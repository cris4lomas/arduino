#include <DHT.h>
#include <TimeLib.h>
#include <TimeAlarms.h>
#include <SoftwareSerial.h>
#define DHTPIN 4
#define DHTTYPE DHT22
#define PINRELE1 8
#define PINRELE2 9
#define PINRELE3 10
#define PINRELE4 11
#define PINSENSORSUELO A0

enum TipoRele{
    luces,
    humed,
    suelo,
    venti
};

struct DataRele{
  unsigned short int inicio;
  unsigned short int fin;
  unsigned short int minutos;
  bool manual;
};


SoftwareSerial bt(2, 3);
DHT dht(DHTPIN, DHTTYPE);

time_t tEncendidoR1 = now();
time_t tEncendidoR2 = now();
time_t tEncendidoR3 = now();
time_t tEncendidoR4 = now();

bool r1IsOn = false;
bool r2IsOn = false;
bool r3IsOn = false;
bool r4IsOn = false;
bool infoActualizadaLuces = true;
bool infoActualizadaRiego = true;
char msjRec[256];
char msjR1[2], msjR2[2], msjR3[2], msjR4[2];

float _lastH = -1;
float _lastT = -1;
int _suelo = 0;
int cantNoLeidosT = 0;
int cantNoLeidosH = 0;

TipoRele tipo1 = luces;
TipoRele tipo2 = humed;
TipoRele tipo3 = suelo;
TipoRele tipo4 = venti;

DataRele dataR1 = {12, 12, 0, false}; //luces: tiempo
DataRele dataR2 = {25, 45, 0, false}; // humedad: humedad ambiente
DataRele dataR3 = {10, 20, 0, false}; //riego: tiempo
DataRele dataR4 = {35, 25, 0, false}; //venti: temperatura ambiente

//AlarmId idLuces;
//AlarmId idSuelo;

void TurnManuallyRele(short int numRele);
void getReleData(String info);
bool charStarts(const char* cadena, const char * empiezaCon);
void sendEnvironmentInfo();
void getTypes(const char * msj);
void getDateTime(const char * msj);
void setReleTimes(const char * msj);
void setReleT(unsigned short int rele, unsigned short int pos, unsigned short int valor);
void setOnOrOffReles(const char * msj);
void verifyReleStatus(DataRele rele, TipoRele tipo, int nrRele);
void turnOffRele(int nrRele);
void turnOnRele(int nrRele);


void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  pinMode(PINRELE1, OUTPUT);
  pinMode(PINRELE2, OUTPUT);
  pinMode(PINRELE3, OUTPUT);
  pinMode(PINRELE4, OUTPUT);
  pinMode(DHTPIN, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  dht.begin();
}

void loop() {
  
  delay(50);

  if(bt.available()){
    
    while(bt.available() > 0){
      Serial.print((char)bt.read());
      delay(10);
    }
  }

  if(Serial.available()){

    short int idx = 0;

    verifyReleStatus(dataR1, tipo1, 1);
    delay(25);
    verifyReleStatus(dataR2, tipo2, 2);
    delay(25);
    verifyReleStatus(dataR3, tipo3, 3);
    delay(25);
    verifyReleStatus(dataR4, tipo4, 4);
    delay(25);
    
    while(Serial.available() > 0){
      msjRec[idx] = (char)Serial.read();
      idx++;
      delay(10);
    }

    msjRec[idx] = '\0';
    char * msjRecPointer = msjRec;
    const char * msjRecC = msjRecPointer;

    if(charStarts(msjRecC, "R1"))
      setOnOrOffReles(msjRecC);
    
    else if(charStarts(msjRecC, "AMB"))
      sendEnvironmentInfo();
    
    else if(charStarts(msjRecC, "&"))
      setReleTimes(msjRecC);
        
    else if(charStarts(msjRecC, "TIPOS"))
      getTypes(msjRecC);
    
    else if(charStarts(msjRecC, "DATE"))
      getDateTime(msjRecC);

    delay(100);

    memset(msjRec,'\0', 255 * sizeof(char));

    delay(100);

  }
}

void verifyReleStatus(DataRele rele, TipoRele tipo, int nrRele){

  bool automatico = !rele.manual;
  time_t timeReleOn;
  bool encendido;

  if(nrRele == 1)
    encendido = r1IsOn;
  else if(nrRele == 2)
    encendido = r2IsOn;
  else if(nrRele == 3)
    encendido = r3IsOn;
  else if(nrRele == 4)
    encendido = r4IsOn;

  if(nrRele == 1)
    timeReleOn = tEncendidoR1;
  else if(nrRele == 2)
    timeReleOn = tEncendidoR2;
  else if(nrRele == 3)
    timeReleOn = tEncendidoR3;
  else if(nrRele == 4)
    timeReleOn = tEncendidoR4;

  tmElements_t nowElements = {second(), minute(), hour(), weekday(), day(), month(), year() };
  tmElements_t releElements;
  breakTime(timeReleOn, releElements);
  time_t tNowSec = makeTime(nowElements);
  time_t tReleOnSec = makeTime(releElements);

  if(tipo == humed)
  {  
    if(automatico)
    {
      if(_lastH == -1){
        if(encendido)
          turnOffRele(nrRele);
      }
      else if((_lastH >= rele.fin) && encendido)
        turnOffRele(nrRele);

      else if((_lastH <= rele.inicio) && !encendido)
        turnOnRele(nrRele);
    }
    
    else
    {
      //Si pasaron más de 12 hrs de que está encendido, apagar.
      if(((tNowSec - tReleOnSec) > 12 * 3600) && encendido)
        turnOffRele(nrRele);
    }

  }

  if(tipo == venti)
  {  
    if(automatico)
    {
      /*
      if(lastT == -1){
        if(encendido)
          turnOffRele(nrRele);        
      }
      else if((lastT <= rele.fin) && encendido)
        turnOffRele(nrRele);

      else if((lastT >= rele.inicio) && !encendido)
        turnOnRele(nrRele);
      */
      if(_suelo < 380 && encendido)
        turnOffRele(nrRele);
      else if(_suelo >= 380 && !encendido)
        turnOnRele(nrRele);
    }
    
    else
    {
      //SI PASARON 12 HORAS DE QUE EL EXTRACTOR ESTÁ PRENDIDO -> APAGAR
      if(((tNowSec - tReleOnSec) > 12 * 3600) && encendido)
        turnOffRele(nrRele);
    }
    
  }

  if(tipo == suelo)
  {  
    if(automatico)
    {
      /*if(infoActualizadaRiego){
        Alarm.free(idSuelo);
        if(nrRele == 1)
          idSuelo = Alarm.alarmRepeat(rele.inicio,rele.minutos,0,turnOnRele1);
        else if(nrRele == 2)
          idSuelo = Alarm.alarmRepeat(rele.inicio,rele.minutos,0,turnOnRele2);
        else if(nrRele == 3)
          idSuelo = Alarm.alarmRepeat(rele.inicio,rele.minutos,0,turnOnRele3);
        else if(nrRele == 4)
          idSuelo = Alarm.alarmRepeat(rele.inicio,rele.minutos,0,turnOnRele4);
        
        infoActualizadaRiego = false;
      }
      */
      tmElements_t releData;
      if(rele.inicio + (rele.fin / 60) > 23){
      }
      else{
        releData = {0, rele.minutos, rele.inicio, weekday(), day(), month(), year() };
        unsigned long int cantSecRele = (rele.minutos * 60) + (rele.inicio * 3600);
        unsigned long int cantSecAhora = (hour() * 3600) + (minute() * 60);
        unsigned long int cantSecFin = (rele.minutos * 60) + (rele.inicio * 3600) + (rele.fin * 60);
        if(cantSecAhora >= cantSecRele && cantSecAhora < cantSecFin && !encendido){
          turnOnRele(nrRele);
        }
      }
      
      //Si se llegó a la hora de fin... apagar (para el riego es en minutos!!)
      if(((tNowSec - tReleOnSec) > (rele.fin * 60)) && encendido)
        turnOffRele(nrRele);
    }
    
    else
    {
      //SI PASO 1 HORA DE QUE EL REGADOR ESTÁ PRENDIDO -> APAGAR
      if(((tNowSec - tReleOnSec) > 3600) && encendido)
        turnOffRele(nrRele);        
      
    }
    
  }

  if(tipo == luces)
  {  
    if(automatico)
    {
      tmElements_t releData;
      if(rele.inicio + rele.fin > 23){
      }
      else{
        releData = {0, rele.minutos, rele.inicio, weekday(), day(), month(), year() };
        unsigned long int cantSecRele = (rele.minutos * 60) + (rele.inicio * 3600);
        unsigned long int cantSecAhora = (hour() * 3600) + (minute() * 60);
        unsigned long int cantSecFin = (rele.minutos * 60) + (rele.inicio * 3600) + (rele.fin * 3600);
        if(cantSecAhora >= cantSecRele && cantSecAhora < cantSecFin && !encendido){
          turnOnRele(nrRele);
        }
      }

      //Si se llegó a la hora de fin... apagar
      if(((tNowSec - tReleOnSec) > rele.fin * 3600) && encendido)
        turnOffRele(nrRele);
    }
    
    else
    {
      //SI PASARON 12 HORAS DE QUE EL EXTRACTOR ESTÁ PRENDIDO -> APAGAR
      if(((tNowSec - tReleOnSec) > 24 * 3600) && encendido)
          turnOffRele(nrRele);
    }
  }
    
}

void turnOnRele(int nrRele){

  char info[6];

  if(nrRele == 1 && !r1IsOn){
    digitalWrite(PINRELE1, HIGH);
    r1IsOn = true;
    tEncendidoR1 = now();
  }
  else if(nrRele == 2 && !r2IsOn){
    digitalWrite(PINRELE2, HIGH);
    r2IsOn = true;
    tEncendidoR2 = now();
  }
  else if(nrRele == 3 && !r3IsOn){
    digitalWrite(PINRELE3, HIGH);
    r3IsOn = true;
    tEncendidoR3 = now();
  }
  else if(nrRele == 4 && !r4IsOn){
    digitalWrite(PINRELE4, HIGH);
    r4IsOn = true;
    tEncendidoR4 = now();
  }

  sprintf(info, "R%d 1", nrRele);
  Serial.println(info);
  memset(info, '\0', sizeof(char) * 5);
  delay(100);
}

void turnOffRele(int nrRele){

  char info[6];

  if(nrRele == 1 && r1IsOn){
    digitalWrite(PINRELE1, LOW);
    r1IsOn = false;
  }
  else if(nrRele == 2 && r2IsOn){
    digitalWrite(PINRELE2, LOW);
    r2IsOn = false;
  }
  else if(nrRele == 3 && r3IsOn){
    digitalWrite(PINRELE3, LOW);
    r3IsOn = false;
  }
  else if(nrRele == 4 && r4IsOn){
    digitalWrite(PINRELE4, LOW);
    r4IsOn = false;
  }

  sprintf(info, "R%d 0", nrRele);
  Serial.println(info);
  memset(info, '\0', sizeof(char) * 5);
  delay(100);
}

void setOnOrOffReles(const char * msj){

  Serial.print('1');
  int cantR = 0;
  for(int i = 0; i < strlen(msj); i++){
    
    if(msj[i] == 'R'){
      cantR++;
      continue;
    }

    if(msj[i] == '1' || msj[i] == '0' && msj[i-1] != 'R'){
      if(cantR == 1)
        msjR1[0] = msj[i];
      else if(cantR == 2)
        msjR2[0] = msj[i];
      else if(cantR == 3)
        msjR3[0] = msj[i];
      else if(cantR == 4)
        msjR4[0] = msj[i];
    }
    
  }
  
  delay(25);

  bool turnOnR1 = (msjR1[0] == '1') && (!r1IsOn) && (dataR1.manual);
  bool turnOnR2 = (msjR2[0] == '1') && (!r2IsOn) && (dataR2.manual);
  bool turnOnR3 = (msjR3[0] == '1') && (!r3IsOn) && (dataR3.manual);
  bool turnOnR4 = (msjR4[0] == '1') && (!r4IsOn) && (dataR4.manual);

  bool turnOffR1 = (msjR1[0] == '0') && (r1IsOn) && (dataR1.manual);
  bool turnOffR2 = (msjR2[0] == '0') && (r2IsOn) && (dataR2.manual);
  bool turnOffR3 = (msjR3[0] == '0') && (r3IsOn) && (dataR3.manual);
  bool turnOffR4 = (msjR4[0] == '0') && (r4IsOn) && (dataR4.manual);

  delay(10);

  if(turnOnR1 || turnOffR1)
    TurnManuallyRele(1);
    
  delay(10);

  if(turnOnR2 || turnOffR2)
    TurnManuallyRele(2);

  delay(10);

  if(turnOnR3 || turnOffR3)
    TurnManuallyRele(3);

  delay(10);

  if(turnOnR4 || turnOffR4)
    TurnManuallyRele(4);

  delay(100);

}

void TurnManuallyRele(short int numRele){

  switch(numRele){
    case 1:
      if(r1IsOn)
        turnOffRele(1);
      else
        turnOnRele(1);
      break;
    case 2:
      if(r2IsOn)
        turnOffRele(2);
      else
        turnOnRele(2);
      break;
    case 3:
      if(r3IsOn)
        turnOffRele(3);
      else
        turnOnRele(3);
      break;
    case 4:
      if(r4IsOn)
        turnOffRele(4);
      else
        turnOnRele(4);
      break;
  }
}

bool charStarts(const char* cadena, const char * empiezaCon){
  
  if(strncmp(cadena, empiezaCon, strlen(empiezaCon)) == 0)
    return true;
  else
    return false;

}

void sendEnvironmentInfo(){

  char hum[7];
  char tem[7];
  char sue[10];
  
  delay(10);

  float h = dht.readHumidity();
  delay(10);
  
  float t = dht.readTemperature();
  delay(10);
  
  _suelo = analogRead(PINSENSORSUELO);
  delay(10);
  
  if(!isnan(h)){
    _lastH = h;
    cantNoLeidosH = 0;
    dtostrf(h,6,2,hum);
  }
  else{
    strcpy(hum,"0");
    cantNoLeidosH++;
    if(cantNoLeidosH > 10)
      _lastH = -1;
  }
  
  if(!isnan(t)){
    _lastT = t;
    cantNoLeidosT = 0;
    dtostrf(t,6,2,tem);
  }
  else{
    strcpy(tem,"0");
    cantNoLeidosT++;
    if(cantNoLeidosT > 10)
      _lastT = -1;
  }

  sprintf(sue, "%d \n",_suelo);

  Serial.print("TE ");
  delay(5);
  Serial.print(tem);
  delay(5);  
  Serial.print(" HU ");
  delay(5);
  Serial.print(hum);
  delay(5);
  Serial.print(" SU ");
  delay(5);
  Serial.print(sue);
  delay(100);
  
}

void getTypes(const char * msj){

  int tipoActual = 1;
  TipoRele tipo;

  for(int i = 6; i < strlen(msj); i++){
    if(isdigit(msj[i])){
      
      char t = msj[i];

      if(t == '0')
        tipo = luces;
      else if(t == '1')
        tipo = humed;
      else if(t == '2')
        tipo = suelo;
      else if(t == '3')
        tipo = venti;
      
      if(tipoActual == 1)
        tipo1 = tipo;
      else if(tipoActual == 2)
        tipo2 = tipo;
      else if(tipoActual == 3)
        tipo3 = tipo;
      else if(tipoActual == 4)
        tipo4 = tipo;
      
      tipoActual++;

    }
  }

  Serial.print('2');
  delay(250);
  Serial.flush();
  delay(100);

}

void getDateTime(const char * msj){

  Serial.print('4');
  int datoActual = 0;
  int hora, min, sec, mes, dia, year;
  char charNumActual[7];
  int index = 0;

  for(int i = 5; i < strlen(msj); i++){
    
    if(isspace(msj[i])){

      if(datoActual == 0)
        hora = atoi(charNumActual);
      else if(datoActual == 1)
        min = atoi(charNumActual);
      else if(datoActual == 2)
        sec = atoi(charNumActual);
      else if(datoActual == 3)
        mes = atoi(charNumActual);
      else if(datoActual == 4)
        dia = atoi(charNumActual);
      else if(datoActual == 5)
        year = atoi(charNumActual);

      datoActual++;
      memset(charNumActual, '\0', sizeof(char) * 6);
      index = 0;
      continue;
    }

    if(isdigit(msj[i])){
      charNumActual[index] = msj[i];
      index++;
      
      if( (i + 1) == strlen(msj)){
        year = atoi(charNumActual);
      }
    }

  }

  setTime(hora, min, sec, mes, dia, year);
  delay(100);
  Serial.flush();
  delay(100);
}

void setReleTimes(const char * msj){

  //LLEGA INFO NUEVA. FORMATO: &INICIO-FIN-MINUTOS-MANUAL&...
  unsigned short int sepRele = 1;
  unsigned short int sepData = 0;
  unsigned short int digitActual = 0;
  int numActual = 0;
  char numCharActual[7];

  //Hay que saltearse el primer &
  for(int i = 1; i < strlen(msj); i++){

    if(msj[i] == '&'){
      numActual = atoi(numCharActual);
      setReleT(sepRele, sepData, numActual);
      sepRele++;
      sepData = 0;
      digitActual = 0;
      memset(numCharActual, '\0', sizeof(char) * 6);
      continue;
    }

    if(msj[i] == '-'){
      numActual = atoi(numCharActual);
      setReleT(sepRele, sepData, numActual);
      sepData++;
      digitActual = 0;
      memset(numCharActual, '\0', sizeof(char) * 6);
      continue;
    }

    if(isdigit(msj[i])){
      numCharActual[digitActual] = msj[i];     
      digitActual++;

      if((i + 1) == strlen(msj)){
        numActual = atoi(numCharActual);
        setReleT(sepRele, sepData, numActual);
      }      
    }

  }

  Serial.print('3');
  delay(250);
  infoActualizadaLuces = true;
  infoActualizadaRiego = true;
  Serial.flush();
  delay(100);

}

void setReleT(unsigned short int rele, unsigned short int pos, int valor){

  switch(rele){
    case 1:
      if(pos == 0)
        dataR1.inicio = valor;
      else if(pos == 1)
        dataR1.fin = valor;
      else if(pos == 2)
        dataR1.minutos = valor;
      else if(pos == 3 && valor == 1)
        dataR1.manual = true;
      else
        dataR1.manual = false;
      break;

    case 2:
      if(pos == 0)
        dataR2.inicio = valor;
      else if(pos == 1)
        dataR2.fin = valor;
      else if(pos == 2)
        dataR2.minutos = valor;
      else if(pos == 3 && valor == 1)
        dataR2.manual = true;
      else
        dataR2.manual = false;
      break;

    case 3:
      if(pos == 0)
        dataR3.inicio = valor;
      else if(pos == 1)
        dataR3.fin = valor;
      else if(pos == 2)
        dataR3.minutos = valor;
      else if(pos == 3 && valor == 1)
        dataR3.manual = true;
      else
        dataR3.manual = false;
      break;

    case 4:
      if(pos == 0)
        dataR4.inicio = valor;
      else if(pos == 1)
        dataR4.fin = valor;
      else if(pos == 2)
        dataR4.minutos = valor;
      else if(pos == 3 && valor == 1)
        dataR4.manual = true;
      else
        dataR4.manual = false;
      break;
  }
}

void Test(){

  /*

  //mandar dataR1, dataR2, dataR3, dataR4 .. .inicio, .fin, .minutos, .manual
  //tipo1, tipo2, tipo3, tipo4
  delay(500);
  char msj[256];
  short int man;
  short int tip;

  if(dataR1.manual)
    man = 1;
  else
    man = 0;

  if(tipo1 == luces)
    tip = 0;
  else if(tipo1 == humed)
    tip = 1;
  else if(tipo1 == suelo)
    tip = 2;
  else
    tip = 3;

  sprintf(msj, "Datos R1: Ini %d, Fin %d, Min %d, Man %d, Tip %d", dataR1.inicio,dataR1.fin, dataR1.minutos,man,tip);

  Serial.println(msj);

  memset(msj,'\0', 255 * sizeof(char));
  delay(500);
  Serial.flush();
  delay(500);

  if(dataR2.manual)
    man = 1;
  else
    man = 0;
  
  if(tipo2 == luces)
    tip = 0;
  else if(tipo2 == humed)
    tip = 1;
  else if(tipo2 == suelo)
    tip = 2;
  else
    tip = 3;

  sprintf(msj, "Datos R2: Ini %d, Fin %d, Min %d, Man %d, Tip %d", dataR2.inicio,dataR2.fin, dataR2.minutos,man,tip);
  Serial.println(msj);

  memset(msj,'\0', 255 * sizeof(char));
  delay(500);
  Serial.flush();
  delay(500);

  if(dataR3.manual)
    man = 1;
  else
    man = 0;
  
  if(tipo3 == luces)
    tip = 0;
  else if(tipo3 == humed)
    tip = 1;
  else if(tipo3 == suelo)
    tip = 2;
  else
    tip = 3;

  sprintf(msj, "Datos R3: Ini %d, Fin %d, Min %d, Man %d, Tip %d", dataR3.inicio,dataR3.fin, dataR3.minutos,man,tip);
  Serial.println(msj);

  memset(msj,'\0', 255 * sizeof(char));
  delay(500);
  Serial.flush();
  delay(500);

  if(dataR4.manual)
    man = 1;
  else
    man = 0;
  
  if(tipo4 == luces)
    tip = 0;
  else if(tipo4 == humed)
    tip = 1;
  else if(tipo4 == suelo)
    tip = 2;
  else
    tip = 3;

  sprintf(msj, "Datos R4: Ini %d, Fin %d, Min %d, Man %d, Tip %d", dataR4.inicio,dataR4.fin, dataR4.minutos,man,tip);
  Serial.println(msj);

  memset(msj,'\0', 255 * sizeof(char));
  delay(500);
  Serial.flush();
  delay(500);

  */
}