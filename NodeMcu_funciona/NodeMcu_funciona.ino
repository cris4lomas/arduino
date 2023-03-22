#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#define MAX_WIFI_RETRIES 25
#define SECS 1000

char msjRec[256];
char ssid[100];
char wifiPass[50];
char usr[50];
char usrPass[50];
bool primerLoop = true;
bool noConectado = true;
bool connectedToFirebase = false;
unsigned long int tiempoActual;
bool sensoresEnviados = true;
bool enviarSensores = false;

//***************************************
//FIREBASE
//***************************************
// Define the Firebase Data object
FirebaseData fbdo;
FirebaseData stream;
// Define the FirebaseAuth data for authentication data
FirebaseAuth auth;
// Define the FirebaseConfig data for config data
FirebaseConfig config;

//String nodNewData = "/dispositivos/000101/INFONUEVA";
//String nodConexion = "/dispositivos/000101/CONEXION";

volatile bool streamHasData = false;

void ConnectToWifi();
void ConnectToFirebase();
void VerifyConections();
void doFirstLoopStuff();
void sendReleTypes();
void sendReleInfo();
int getInicio(unsigned short int rele);
int getFin(unsigned short int rele);
int getMinutos(unsigned short int rele);
int getManual(unsigned short int rele);
int getStatus(unsigned short int rele);
void sendReleStatus();
bool charStarts(const char* cadena, const char * empiezaCon);
void setEnvironmentData(const char *msj);
void streamCallBack(StreamData data);
void streamTimeoutCallback(bool timeout);
void sendReleDate();
void setFbReleData(const char *msj);

void setup() {
  
  Serial.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  ConnectToWifi();

}

void loop() {
  
  VerifyConections();

  if(primerLoop){
    doFirstLoopStuff();
    primerLoop = false;
  }

  

  if(sensoresEnviados){
    tiempoActual = millis();
    sensoresEnviados = false;
  }

  enviarSensores = millis() - tiempoActual >= (25 * SECS);


  if(enviarSensores){
    Serial.println("AMB");
    sensoresEnviados = true;
    delay(250);
  }

  if(Serial.available()){

    int index = 0;      
    while(Serial.available() > 0){
      msjRec[index] = (char)Serial.read();
      index++;
    }

    msjRec[index] = '\0';
    char * msjRecPointer = msjRec;
    const char * msjRecC = msjRecPointer;
    
    if(charStarts(msjRecC, "TE "))
      setEnvironmentData(msjRecC);
    else if(charStarts(msjRecC, "R"))
      setFbReleData(msjRecC);
    
    delay(100);
    memset(msjRec,'\0', 255 * sizeof(char));
  }

  if(streamHasData){
    Firebase.setBoolAsync(fbdo, "/dispositivos/000101/INFONUEVA", false);
    streamHasData = false;
    sendReleInfo();
    delay(250);
    sendReleStatus();
    delay(500);
  }

  delay(50);
}
  
  //*************************************************************
  //Escribir
  //(ojo porque estando en el loop va a escribir infinitamente)
  //*************************************************************
  //Firebase.setInt(fbData, nodo, 1);
  //Firebase.setString(fbData, nodo, "hola");
  //Firebase.setBool(fbData, nodo + "/encendido", false);

  //*************************************************************
  //LEER DATOS
  //*************************************************************
  /*if(Firebase.getInt(fbdo, nodo + "/encendido")){
    Serial.println("Exito");
    encender = fbdo.boolData();
    Serial.println(encender);
  } else{
    Serial.println("Segui intentando y nunca te rindas");
  }
  */

void setFbReleData(const char *msj){

  //DE LA FORMA R[NRO RELE] [0 si es falso / 1 si esta encendido]
  char nroRele = msj[1];
  bool encendido;

   //suponiendo R1 1 o R1 0
  if(msj[3] == '1')
    encendido = true;
  else
    encendido = false;
  
  if(nroRele == '1')
    Firebase.setBoolAsync(fbdo, "/dispositivos/000101/RELES/RELE1", encendido);
  else if(nroRele == '2')
    Firebase.setBoolAsync(fbdo, "/dispositivos/000101/RELES/RELE2", encendido);
  else if(nroRele == '3')
    Firebase.setBoolAsync(fbdo, "/dispositivos/000101/RELES/RELE3", encendido);
  else if(nroRele == '4')
    Firebase.setBoolAsync(fbdo, "/dispositivos/000101/RELES/RELE4", encendido);

  delay(100);
}

void setEnvironmentData(const char *msj){

  //EMPIEZA CON "TE "
  char chTemp[6];
  char chHume[6];
  char chSuel[6];
  unsigned short int index = 0;
  unsigned short int medicionActual = 0; // 1 es TEMP 2 es HUMEDAD y 3 es SUELO
  bool esOtroDato = true;

  for(int i = 3; i < strlen(msj); i++){
        if(isdigit(msj[i]) || msj[i] == '.'){
          if(esOtroDato){
            medicionActual++;
            esOtroDato = false;
          }
          if(medicionActual == 1)
            chTemp[index] = msj[i];
          else if(medicionActual == 2)
            chHume[index] = msj[i];
          else if(medicionActual == 3)
            chSuel[index] = msj[i];
          
          index++;

        } else{
          esOtroDato = true;
          index = 0;
        }
  }
  
  float temp = atof(chTemp);
  float hume = atof(chHume);
  short int suelo = atoi(chSuel);

  Firebase.setFloatAsync(fbdo, "/dispositivos/000101/SENSORES/TEMPERATURA", temp);
  delay(50);
  Firebase.setFloatAsync(fbdo, "/dispositivos/000101/SENSORES/HUMEDAD", hume);
  delay(50);
  Firebase.setIntAsync(fbdo, "/dispositivos/000101/SENSORES/SUELO", suelo);
  delay(50);

}

bool isNewLine(char ch){
  return (ch == '\n') || (ch == (char)10) || (ch == (char)13);
}

void ConnectToWifi(){

  char DatosWifi[251];
  int intentoActual = 0;
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);

  while(noConectado){

    char *_ssid = ssid;
    char *_wifiPass = wifiPass;
    const char *_ssid_ = _ssid;
    const char *_wifiPass_ = _wifiPass;
    
    if(strlen(_wifiPass_) > 0 && strlen(_ssid_) > 0){

      WiFi.begin(_ssid_, _wifiPass_);
      
      while(WiFi.status() != WL_CONNECTED){
        intentoActual++;
        if(intentoActual == MAX_WIFI_RETRIES){
          intentoActual = 0;
          break;            
        }
        delay(1000);
      }

      if(WiFi.status() == WL_CONNECTED){
        noConectado = false;
        break;
      }

    }

    delay(100);

    int idxWifi = 0;
    while(Serial.available() > 0){
      delay(50);
      DatosWifi[idxWifi] = (char)Serial.read();
      idxWifi++;
    }

    delay(50);
    DatosWifi[idxWifi] = '\0';

    int newLines = 0;
    int subIndex = 0;

    if(idxWifi > 0){

      for(int i = 0; i < idxWifi; i++){
        
        if(isNewLine(DatosWifi[i])){
          subIndex = 0;
          if(i > 0){
            if(!isNewLine(DatosWifi[i-1]))
              newLines++;
          }
          continue;
        } else{
          switch(newLines){
            case 0:
              ssid[subIndex] = DatosWifi[i];
              subIndex++;
              break;
            case 1:
              wifiPass[subIndex] = DatosWifi[i];
              subIndex++;
              break;
            case 2:
              usr[subIndex] = DatosWifi[i];
              subIndex++;
              break;
            case 3:
              usrPass[subIndex] = DatosWifi[i];
              subIndex++;
              break;
          }
        }
      }

    memset(DatosWifi,'\0', 250 * sizeof(char));
    idxWifi = 0;    
    }
  }
}

void ConnectToFirebase(){

  while(!connectedToFirebase){

    char *_usr = usr;
    char *_usrPass = usrPass;
    const char *_usr_ = _usr;
    const char *_usrPass_ = _usrPass;

    // Assign the project host and api key (required)
    config.host = "https://esp8266-df5f1-default-rtdb.firebaseio.com";
    config.api_key = "AIzaSyD36F3QhIgsg6kU4SoUpTa8kAOngGxievg";
    // Assign the user sign in credentials
    auth.user.email = _usr_;
    auth.user.password = _usrPass_;
    // Initialize the library with the Firebase authen and config.
    Firebase.begin(&config, &auth);
    //Firebase.reconnectWiFi(true);
    Firebase.setMaxRetry(fbdo, 3);
    Firebase.setStreamCallback(stream, streamCallBack, streamTimeoutCallback);
    delay(250);

    bool streamAreOk = Firebase.beginStream(stream, "/dispositivos/000101/INFONUEVA");
    
    if(Firebase.ready() && streamAreOk){
      connectedToFirebase = true;
      Firebase.setBool(fbdo, "/dispositivos/000101/CONEXION", true);      
    }

  }
}

void VerifyConections(){

  if(WiFi.status() != WL_CONNECTED){
    noConectado = true; 
  }
  if (!Firebase.ready()){
    connectedToFirebase = false;
  }

  if(noConectado){
    ConnectToWifi();
  }
  
  if(!connectedToFirebase){
    ConnectToFirebase();
  }
}

void doFirstLoopStuff(){

  sendReleDate();

  sendReleTypes();

  sendReleInfo();

  sendReleStatus();

  delay(750);

  Serial.println("AMB");

}

void sendReleDate(){

  bool dataOk = true;
  String date;
  do{
      delay(500);

      if(Firebase.getString(fbdo, "/dispositivos/000101/FECHA")){
        date = fbdo.stringData();
        if(date == "" || date == " ")
          dataOk = false;
        else        
          dataOk = true;
      }
      else
      {
        dataOk = false;
      }

      delay(500);

  } while(!dataOk);

  do {
    delay(500);
    Serial.println("DATE " + date);

    if(!Serial.available()){
      dataOk = false;
    }
    else{
      if((char)Serial.read() != '1')
        dataOk = false;
      else
        dataOk = true;
    }

    delay(500);
  } while(!dataOk);

  Serial.flush();
  delay(250);



}

void sendReleStatus(){

  int r1 = getStatus(1);
  delay(25);
  int r2 = getStatus(2);
  delay(25);
  int r3 = getStatus(3);
  delay(25);
  int r4 = getStatus(4);
  delay(25);

  char msg[30];

  sprintf(msg, "R1 %d R2 %d R3 %d R4 %d \n", r1, r2, r3, r4);
  
  bool releStatus = true;

  do {
    Serial.print(msg);
    delay(500);

    if(!Serial.available()){
      releStatus = false;
    }
    else{
      if((char)Serial.read() != '4')
        releStatus = false;
      else
        releStatus = true;
    }

    delay(500);
  } while(!releStatus);

  Serial.flush();
  delay(250);

}

int getStatus(unsigned short int rele){

  bool dataOk = true;
  do{
    if(rele == 1){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/RELES/RELE1")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    else if(rele == 2){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/RELES/RELE2")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    else if(rele == 3){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/RELES/RELE3")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    else if(rele == 4){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/RELES/RELE4")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    delay(500);
  } while(!dataOk);

  return 0;  

}

void sendReleInfo(){

  unsigned short int r1Ini = getInicio(1);
  delay(10);
  unsigned short int r1Fin = getFin(1);
  delay(10);
  unsigned short int r1Min = getMinutos(1);
  delay(10);
  unsigned short int r1Man = getManual(1);
  delay(10);

  unsigned short int r2Ini = getInicio(2);
  delay(10);
  unsigned short int r2Fin = getFin(2);
  delay(10);
  unsigned short int r2Min = getMinutos(2);
  delay(10);
  unsigned short int r2Man = getManual(2);
  delay(10);

  unsigned short int r3Ini = getInicio(3);
  delay(10);
  unsigned short int r3Fin = getFin(3);
  delay(10);
  unsigned short int r3Min = getMinutos(3);
  delay(10);
  unsigned short int r3Man = getManual(3);
  delay(10);

  unsigned short int r4Ini = getInicio(4);
  delay(10);
  unsigned short int r4Fin = getFin(4);
  delay(10);
  unsigned short int r4Min = getMinutos(4);
  delay(10);
  unsigned short int r4Man = getManual(4);
  delay(10);

  char msg[64];

  sprintf(msg, "&%d-%d-%d-%d&%d-%d-%d-%d&%d-%d-%d-%d&%d-%d-%d-%d \n", r1Ini, r1Fin, r1Min, r1Man, r2Ini, r2Fin, r2Min, r2Man, r3Ini, r3Fin, r3Min, r3Man, r4Ini, r4Fin, r4Min, r4Man);

  bool releInfo = true;

  do {
    Serial.print(msg);
    delay(500);

    if(!Serial.available()){
      releInfo = false;
    }
    else{
      if((char)Serial.read() != '3')
        releInfo = false;
      else
        releInfo = true;
    }

    delay(500);
  } while(!releInfo);

  Serial.flush();
  delay(250);

}

int getInicio(unsigned short int rele){

  bool dataOk = true;
  do{
    if(rele == 1){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE1/INICIO"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 2){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE2/INICIO"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 3){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE3/INICIO"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 4){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE4/INICIO"))
        return fbdo.intData();
      else dataOk = false;      
    }
    delay(500);
  } while(!dataOk);

  return 0;

}

int getFin(unsigned short int rele){
  
  bool dataOk = true;
  do{
    if(rele == 1){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE1/FIN"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 2){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE2/FIN"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 3){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE3/FIN"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 4){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE4/FIN"))
        return fbdo.intData();
      else dataOk = false;
    }
    delay(500);
  } while(!dataOk);

  return 0;
  
}

int getMinutos(unsigned short int rele){

  bool dataOk = true;
  do{
    if(rele == 1){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE1/MINS"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 2){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE2/MINS"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 3){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE3/MINS"))
        return fbdo.intData();
      else dataOk = false;
    }
    else if(rele == 4){
      if(Firebase.getInt(fbdo, "/dispositivos/000101/DATARELE/RELE4/MINS"))
        return fbdo.intData();
      else dataOk = false;
    }
    delay(500);
  } while(!dataOk);

  return 0;

}
int getManual(unsigned short int rele){

  bool dataOk = true;
  do{
    if(rele == 1){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/DATARELE/RELE1/MANUAL")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    else if(rele == 2){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/DATARELE/RELE2/MANUAL")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    else if(rele == 3){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/DATARELE/RELE3/MANUAL")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    else if(rele == 4){
      if(Firebase.getBool(fbdo, "/dispositivos/000101/DATARELE/RELE4/MANUAL")){
        if(fbdo.boolData())
          return 1;
        else        
          return 0;
      }
      else dataOk = false;
    }
    delay(500);
  } while(!dataOk);

  return 0;

}

void sendReleTypes(){
  
  int t1 = -1, t2 = -1, t3 = -1, t4 = -1;
  bool dataOk = true;

  do{

    if(t1 == -1 && Firebase.getInt(fbdo, "/dispositivos/000101/TIPORELES/RELE1"))
    t1 = fbdo.intData();
  else
    dataOk = false;
  
  delay(50);
  
  if(t2 == -1 && Firebase.getInt(fbdo, "/dispositivos/000101/TIPORELES/RELE2"))
    t2 = fbdo.intData();
  else
    dataOk = false;

  delay(50);
  
  if(t3 == -1 && Firebase.getInt(fbdo, "/dispositivos/000101/TIPORELES/RELE3"))
    t3 = fbdo.intData();
  else
    dataOk = false;

  delay(50);
  
  if(t4 == -1 && Firebase.getInt(fbdo, "/dispositivos/000101/TIPORELES/RELE4"))
    t4 = fbdo.intData();
  else
    dataOk = false;

  delay(250);

  } while(!dataOk);

  char msg[21];

  sprintf(msg, "TIPOS %d %d %d %d \n", t1, t2, t3, t4);

  bool releTypes = true;

  do{
    Serial.print(msg);
    delay(500);

    if(!Serial.available()){
      releTypes = false;
    }
    else{
      if((char)Serial.read() != '2')
        releTypes = false;
      else
        releTypes = true;
    }

    delay(500);
  } while(!releTypes);

  Serial.flush();

  delay(250);
}

bool charStarts(const char* cadena, const char * empiezaCon){
  
  if(strncmp(cadena, empiezaCon, strlen(empiezaCon)) == 0)
    return true;
  else
    return false;

}

void streamCallBack(StreamData data){

  streamHasData = data.to<bool>() == true ? true : false;

}

void streamTimeoutCallback(bool timeout){

}