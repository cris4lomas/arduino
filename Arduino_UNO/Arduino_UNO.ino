#include <DHT.h>
#include <Time.h>
#include <TimeLib.h>
#include <TimeAlarms.h>
#include <SoftwareSerial.h>
#define DHTPIN 4
#define DHTTYPE DHT11
#define PINGROUND A0
#define PINRELE1 8
#define PINRELE2 9
#define PINRELE3 10
#define PINRELE4 11
#define QUANTITYRELES 4
#define ONE_MINUTE 60
#define SECS 1000

//******************************************
//********DEFINICION DE FUNCIONES***********
//******************************************
bool charStarts(const char* chain, const char * startWith);
void sendEnvironmentInfo();
void getTypes(const char * msj);
void getDateTime(const char * msj);
void setReleTimes(const char * msj);
void setReleT(unsigned short int rele, unsigned short int pos, unsigned short int valor);
void setOnOrOffReles(const char * msg);
void turnOffRele(int nrRele, bool isFirst = false);
void turnOnRele(int nrRele, bool isFirst = false);
void getMessage(const char * msg);
void verifyReleStatus();
void verifyManualMaxHoursRele(int nrRele, int _maxHours);
void verifyAutoHumidityRele(int nrRele);
void verifyAutoGroundRele(int nrRele);
void verifyAutoLigthRele(int nrRele);
void verifyAutoWindRele(int nrRele);
void sendErrorRele(int nrRele);
//******************************************
//**************VARIABLES*******************
//******************************************

SoftwareSerial bt(2, 3);
DHT dht(DHTPIN, DHTTYPE);

enum ReleTypes{
    light,
    humidifier,
    ground,
    wind
};

struct DataRele{
  unsigned short int pin;
  unsigned short int start;
  unsigned short int end;
  unsigned short int minutes;
  bool manual;
  ReleTypes type;
  bool on;
  time_t timeOn;
};

typedef struct DataRele DataRele;

DataRele reles[QUANTITYRELES] = {
  {PINRELE1, 12, 12, 0, false, light, false, now()}, 
  {PINRELE2, 25, 45, 0, false, humidifier, false, now()}, 
  {PINRELE3, 10, 20, 0, false, ground, false, now()},
  {PINRELE4, 35, 25, 0, false, wind, false, now()}
};

char msjRec[256];

float lastHumidity = 1.0;
float lastTemperature = 1.0;
int lastGround = 0;
int quantityErrTemperature = 0;
int quantityErrHumidity = 0;
bool verificarEstados = true;
bool estadosYaVerificados = true;
bool dataWifiExtraida = false;
unsigned long int tiempoParaVerificarEstados;


//******************************************
//*****************SETUP********************
//******************************************


void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  
  for(int i = 0; i < QUANTITYRELES; i++)
    pinMode(reles[i].pin, OUTPUT);

  pinMode(DHTPIN, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  //dht.begin();
}

//******************************************
//*****************LOOP*********************
//******************************************

void loop() {
  
  delay(50);

  if(estadosYaVerificados){
    tiempoParaVerificarEstados = millis();
    estadosYaVerificados = false;
  }

  verificarEstados = millis() - tiempoParaVerificarEstados >= (5 * SECS);

  if(verificarEstados && dataWifiExtraida){
    verifyReleStatus();
    estadosYaVerificados = true;
    delay(250);
  }

  if(bt.available()){
    
    while(bt.available() > 0){
      Serial.print((char)bt.read());
      delay(10);
    }
  }

  if(Serial.available()){

    short int idx = 0;

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

//******************************************
//**************FUNCIONES*******************
//******************************************

void verifyReleStatus(){

  for(int i = 0; i < QUANTITYRELES; i++){

    ReleTypes _type = reles[i].type;
    bool isManual = reles[i].manual;

    
    if(isManual)
    {
      if(_type == humidifier)
        verifyManualMaxHoursRele(i, 12);
      else if(_type == ground)
        verifyManualMaxHoursRele(i,1);
      else if(_type == light)
        verifyManualMaxHoursRele(i,22);
      else if(_type == wind)
        verifyManualMaxHoursRele(i,23);
    }
    //isAutomatic
    else{
      if(_type == light)
        verifyAutoLightRele(i);
      //if(_type == humidifier)
      //  verifyAutoHumidityRele(i);
      //else if(_type == ground)
      //  verifyAutoGroundRele(i);
      //else if(_type == light)
      //  verifyAutoLightRele(i);
      //else if(_type == wind)
      //  verifyAutoWindRele(i);      
    }
  delay(250);
  }
}

void verifyManualMaxHoursRele(int nrRele, int _maxHours){

  bool isOff = !(reles[nrRele].on);
  unsigned short maxHours = _maxHours;

  if(isOff)
    return;

  time_t lastTimeTurnedOn = reles[nrRele].timeOn;
  long _timeOn = difftime(now(), lastTimeTurnedOn);

  if(_timeOn >= (maxHours * ONE_HOUR))
    turnOffRele(nrRele);
}

void verifyAutoLightRele(int nrRele){
  
  bool isOn = reles[nrRele].on;
  bool isOff = !isOn;
  short int startTime = reles[nrRele].start;
  short int endTime = reles[nrRele].end * ONE_MINUTE;
  short int minutes = reles[nrRele].minutes;
  time_t _now = now();

  /*
  Si está apagado, verificar si el horario actual
  está entre el rango de encendido y encenderlo en tal caso.
  Para esto, crear dos tiempos con los datos de inicio, minutos y de fin del relé.
  Un tiempo con el día de hoy y un tiempo con el día de ayer restado (constante ONE_DAY).
  Calcular la diferencia de hoy con esos dos tiempos y verificar:
    ** Si alguno es mayor a cero y, al mismo tiempo, menor a la cantidad de tiempo indicada por FIN
  */
  if(isOn){
    
    time_t lastTimeTurnedOn = reles[nrRele].timeOn;
    long int timeSinceTurnedOn = difftime(_now, lastTimeTurnedOn);
    bool hasToTurnOff = timeSinceTurnedOn >= (endTime);

    if(hasToTurnOff)
      turnOffRele(nrRele);
          
  }

  else if(isOff){

    const tmElements_t el_timeToTurnOnToday = {Second: 0, Minute: minutes, Hour: startTime, Wday: weekday(), Day: day(), Month: month(), Year: (year() - 1970)};
    time_t timeToTurnOnToday =  makeTime(el_timeToTurnOnToday);
    long int timePassedToday = difftime(_now, timeToTurnOnToday);
    long int timePassedYesterday = timePassedToday - ONE_DAY;
    bool hasToTurnOnToday = (timePassedToday >= 0) && (timePassedToday < endTime);
    bool hasToTurnOnYesterday = (timePassedYesterday >= 0) && (timePassedYesterday < endTime);

    char tm[45];
    sprintf(tm,"%02d/%02d/%02d %02d:%02d:%02d", day(_now),month(_now),year(_now),hour(_now),minute(_now),second(_now));
    Serial.print("Hora actual: ");
    Serial.println(tm);

    char tm2[45];
    sprintf(tm2,"%02d/%02d/%02d %02d:%02d:%02d", day(timeToTurnOnToday),month(timeToTurnOnToday),year(timeToTurnOnToday),hour(timeToTurnOnToday),minute(timeToTurnOnToday),second(timeToTurnOnToday));
    Serial.print("Hora para prender el rele: ");
    Serial.println(tm2);

    if(hasToTurnOnToday || hasToTurnOnYesterday)
      turnOnRele(nrRele);
  
  }

  /*
  Si está encendido, calcular la diferencia de tiempo entre ahora y lastTimeTurnedOn del relé.
  Verificar que esa diferencia no supere el tiempo máximo definido por FIN y en caso positivo, apagarlo.
  

  */
    
}

void verifyAutoGroundRele(int nrRele){
  
  bool isOn = reles[nrRele].on;
  bool isOff = !isOn;
  short int startTime = reles[nrRele].start;
  short int endTime = reles[nrRele].end;
  short int minutes = reles[nrRele].minutes;
  time_t _now = now();

  if(isOn){
    
    time_t lastTimeTurnedOn = reles[nrRele].timeOn;
    long int timeSinceTurnedOn = difftime(_now, lastTimeTurnedOn);
    bool hasToTurnOff = timeSinceTurnedOn >= (endTime * ONE_MINUTE);

    if(hasToTurnOff)
      turnOffRele(nrRele);
          
  }

  else if(isOff){
    
    time_t timeToTurnOnToday =  makeTime({0, minutes, startTime, weekday(), day(), month(), year()});
    long int timePassedToday = difftime(_now, timeToTurnOnToday);
    long int timePassedYesterday = timePassedToday - ONE_DAY;
    bool hasToTurnOnToday = (timePassedToday >= 0) && (timePassedToday < endTime * ONE_MINUTE);
    bool hasToTurnOnYesterday = (timePassedYesterday >= 0) && (timePassedYesterday < endTime * ONE_MINUTE);

    if(hasToTurnOnToday || hasToTurnOnYesterday)
      turnOnRele(nrRele);
  
  }
}

void verifyAutoGroundRele2(int nrRele){
  
  bool isOn = reles[nrRele].on;
  bool isOff = !isOn;
  short int startValue = reles[nrRele].start;
  short int endValue = reles[nrRele].end;

  if(lastGround == 0){
    if(isOn)
      sendErrorRele(nrRele);
    return;
  }
  //El extractor se inicia cuando la humedad de suelo está baja y se apaga cuando la misma sube.
  bool hasToTurnOn = (lastGround >= startValue) && isOff;
  bool hasToTurnOff = (lastGround <= endValue) && isOn;

  if(hasToTurnOn)
    turnOnRele(nrRele);
  else if(hasToTurnOff)
    turnOffRele(nrRele);
    
}

void verifyAutoWindRele(int nrRele){
  
  bool isOn = reles[nrRele].on;
  bool isOff = !isOn;
  short int startValue = reles[nrRele].start;
  short int endValue = reles[nrRele].end;

  if(lastTemperature == -1){
    if(isOn)
      sendErrorRele(nrRele);
    return;
  }
  //El extractor se inicia cuando la temperatura está alta y se apaga cuando la misma baja.
  bool hasToTurnOn = (lastTemperature >= startValue) && isOff;
  bool hasToTurnOff = (lastTemperature <= endValue) && isOn;

  if(hasToTurnOn)
    turnOnRele(nrRele);
  else if(hasToTurnOff)
    turnOffRele(nrRele);
    
}

void verifyAutoHumidityRele(int nrRele){
  
  bool isOn = reles[nrRele].on;
  bool isOff = !isOn;
  short int startValue = reles[nrRele].start;
  short int endValue = reles[nrRele].end;
  
  if(lastHumidity == -1){
    if(isOn)
      sendErrorRele(nrRele);
    return;
  }
  //El humidificador se inicia cuando la humedad está baja y se apaga cuando la misma sube.
  bool hasToTurnOn = (lastHumidity <= startValue) && isOff;
  bool hasToTurnOff = (lastHumidity >= endValue) && isOn;

  if(hasToTurnOn)
    turnOnRele(nrRele);
  else if(hasToTurnOff)
    turnOffRele(nrRele);
    
}

void sendErrorRele(int nrRele){

  bool releIsOn = reles[nrRele].on;
  unsigned short int pinRele = reles[nrRele].pin;

  if(releIsOn){
    digitalWrite(pinRele, LOW);
    reles[nrRele].on = false;
  }

  char info[6];
  sprintf(info, "R%d -1", (nrRele + 1));
  Serial.println(info);
  memset(info, '\0', sizeof(char) * 5);
  delay(100);

}

void getMessage(const char * msg){
  
  if(charStarts(msg, "R1"))
      setOnOrOffReles(msg);
    
    else if(charStarts(msg, "AMB"))
      sendEnvironmentInfo();
    
    else if(charStarts(msg, "&"))
      setReleTimes(msg);
        
    else if(charStarts(msg, "TIPOS"))
      getTypes(msg);
    
    else if(charStarts(msg, "DATE"))
      getDateTime(msg);
}

void turnOnRele(int nrRele, bool isFirst = false){

  bool releIsOff = !(reles[nrRele].on);
  unsigned short int pinRele = reles[nrRele].pin;

  if(releIsOff){
    digitalWrite(pinRele, HIGH);
    reles[nrRele].on = true;
    reles[nrRele].timeOn = now();
  }

  if(!isFirst){
    char info[6];
    sprintf(info, "R%d 1", (nrRele + 1));
    Serial.println(info);
    memset(info, '\0', sizeof(char) * 5);
    delay(100);
  }

}

void turnOffRele(int nrRele, bool isFirst = false){

  bool releIsOn = reles[nrRele].on;
  unsigned short int pinRele = reles[nrRele].pin;

  if(releIsOn){
    digitalWrite(pinRele, LOW);
    reles[nrRele].on = false;
  }

  if(!isFirst){
    char info[6];
    sprintf(info, "R%d 0", (nrRele + 1));
    Serial.println(info);
    memset(info, '\0', sizeof(char) * 5);
    delay(100);
  }
  
}

void setOnOrOffReles(const char * msg){

  Serial.print('4');
  int currRele = 0;
  bool turnOn, turnOff;
  //De la forma R1 1 R2 0 R3 0 R4 1

  for(int i = 3; i < strlen(msg); i++){

    if(msg[i] == 'R'){
      currRele++;
      continue;
    }
    
    bool releIsOn = reles[currRele].on;
    bool releIsOff = !releIsOn;
    bool releIsManual = reles[currRele].manual;
    bool msgIsOn = msg[i] == '1';
    bool msgIsOff = msg[i] == '0';
    bool notIsReleNumberIndicator =  (msg[i-1] != 'R');

    if((msgIsOn || msgIsOff) && notIsReleNumberIndicator && releIsManual){
      turnOn = msgIsOn && releIsOff;
      turnOff = msgIsOff && releIsOn;

      if(turnOn)
        turnOnRele(currRele, true);
      else if(turnOff)
        turnOffRele(currRele, true);
        
    }
    delay(100);
    dataWifiExtraida = true;
  }

}

bool charStarts(const char* chain, const char * startWith){
  
  if(strncmp(chain, startWith, strlen(startWith)) == 0)
    return true;
  else
    return false;

}

void sendEnvironmentInfo(){

  char charHumidity[7] = {""};
  char charTemperature[7] = {""};
  float humidity = dht.readHumidity();
  delay(10);
  float temperature = dht.readTemperature();
  delay(10);
  lastGround = analogRead(PINGROUND);
  
  if(!isnan(humidity)){
    lastHumidity = humidity;
    quantityErrHumidity = 0;
    dtostrf(humidity,6,2,charHumidity);
  }
  else{
    strcpy(charHumidity,"0");
    quantityErrHumidity++;
    if(quantityErrHumidity > 10)
      lastHumidity = -1;
  }

  if(!isnan(temperature)){
    lastTemperature = temperature;
    quantityErrTemperature = 0;
    dtostrf(temperature,6,2,charTemperature);
  }
  else{
    strcpy(charTemperature,"0");
    quantityErrTemperature++;
    if(quantityErrTemperature > 10)
      lastTemperature = -1;
  }

  Serial.print("TE ");
  delay(5);
  Serial.print(charTemperature);
  delay(5);  
  Serial.print(" HU ");
  delay(5);
  Serial.print(charHumidity);
  delay(5);
  Serial.print(" SU ");
  delay(5);
  Serial.println(lastGround);
  delay(100);
  
}

void getTypes(const char * msg){

  int current = 0;
  ReleTypes _type;

  for(int i = 6; i < strlen(msg); i++){
    if(isdigit(msg[i])){
      
      char t = msg[i];

      if(t == '0')
        _type = light;
      else if(t == '1')
        _type = humidifier;
      else if(t == '2')
        _type = ground;
      else if(t == '3')
        _type = wind;

      reles[current].type = _type;
      current++;

    }
  }

  Serial.print('2');
  delay(250);
  Serial.flush();
  delay(100);

}

void getDateTime(const char * msg){

  Serial.print('1');
  int current = 0;
  int hora, min, sec, mes, dia, anio;
  char charNumActual[7] = {};
  int index = 0;

  for(int i = 5; i < strlen(msg); i++){
    
    if(isspace(msg[i])){

      if(current == 0)
        hora = atoi(charNumActual);
      else if(current == 1)
        min = atoi(charNumActual);
      else if(current == 2)
        sec = atoi(charNumActual);
      else if(current == 3)
        mes = atoi(charNumActual);
      else if(current == 4)
        dia = atoi(charNumActual);
      else if(current == 5)
        anio = atoi(charNumActual);

      current++;
      memset(charNumActual, '\0', sizeof(char) * 6);
      index = 0;
      continue;
    }

    if(isdigit(msg[i])){
      charNumActual[index] = msg[i];
      index++;
      
      if( (i + 1) == strlen(msg)){
        anio = atoi(charNumActual);
      }
    }

  }

  setTime(hora, min, sec, dia, mes, anio);
  delay(100);
  Serial.flush();
  delay(100);
}

void setReleTimes(const char * msg){

  //LLEGA INFO NUEVA. FORMATO: &INICIO-FIN-MINUTOS-MANUAL&...
  unsigned short int sepRele = 0;
  unsigned short int sepData = 0;
  unsigned short int digitActual = 0;
  int valor = 0;
  char charValor[7];

  //Hay que saltearse el primer &
  for(int i = 1; i < strlen(msg); i++){

    if(msg[i] == '&'){
      valor = atoi(charValor);
      setReleT(sepRele, sepData, valor);
      sepRele++;
      sepData = 0;
      digitActual = 0;
      memset(charValor, '\0', sizeof(char) * 6);
      continue;
    }

    if(msg[i] == '-'){
      valor = atoi(charValor);
      setReleT(sepRele, sepData, valor);
      sepData++;
      digitActual = 0;
      memset(charValor, '\0', sizeof(char) * 6);
      continue;
    }

    if(isdigit(msg[i])){
      charValor[digitActual] = msg[i];     
      digitActual++;

      if((i + 1) == strlen(msg)){
        valor = atoi(charValor);
        setReleT(sepRele, sepData, valor);
      }      
    }

  }

  Serial.print('3');
  delay(250);
  Serial.flush();
  delay(100);

}

void setReleT(unsigned short int rele, unsigned short int pos, int valor){

      if(pos == 0)
        reles[rele].start = valor;
      else if(pos == 1)
        reles[rele].end = valor;
      else if(pos == 2)
        reles[rele].minutes = valor;
      else if(pos == 3 && valor == 1)
        reles[rele].manual = true;
      else
        reles[rele].manual = false;

}