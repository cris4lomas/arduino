#include <DHT.h>
#include <TimeLib.h>
#include <Time.h>
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
float _suelo = 0;
int cantNoLeidosT = 0;
int cantNoLeidosH = 0;

time_t horaInicial = now();

TipoRele tipo1 = luces;
TipoRele tipo2 = humed;
TipoRele tipo3 = suelo;
TipoRele tipo4 = venti;

DataRele dataR1 = {23, 2, 0, false}; //luces: tiempo //INICIO 10, FIN 1 MINUTOS, 2 MINUTOS => INICIO: 10:02 AM
DataRele dataR2 = {25, 45, 0, false}; // humedad: humedad ambiente
DataRele dataR3 = {10, 20, 0, false}; //riego: tiempo
DataRele dataR4 = {35, 25, 0, false}; //venti: temperatura ambiente

void getDateTime();
void verifyReleStatus();


void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  getDateTime();
}

void loop() {
  
  delay(2000);
  verifyReleStatus();

}

/*

void verifyReleStatus(){

  if(_suelo < dataR1.fin)
    digitalWrite(LED_BUILTIN, LOW);
  else if(_suelo >= dataR1.fin)
    digitalWrite(LED_BUILTIN, HIGH);

  tmElements_t timeNow = {0, minute(), hour(), weekday(), day(), month(), year() };
  tmElements_t releData = {0, dataR1.minutos, dataR1.inicio, weekday(), day(), month(), year() };
  //tm releData = {0, dataR1.minutos, dataR1.inicio, weekday(), day(), month(), year() };
  
  time_t t_ahora = makeTime(timeNow);
  time_t t_rele = makeTime(releData);

  long int diferencia = difftime(t_ahora, t_rele);
  unsigned long int max = dataR1.fin * 60;
  bool dentroDeRango = (diferencia >= 0) && (diferencia < max);

  Serial.println("La diferencia de segundos es de: " + String(diferencia));

  Serial.println("Tiempo límite: " + String(max));

  if(dentroDeRango)
    digitalWrite(LED_BUILTIN, HIGH);
  else
    digitalWrite(LED_BUILTIN, LOW);   
  delay(4500);
    
}

*/

void verifyReleStatus(){

  tmElements_t timeNow = {0, minute(), hour(), weekday(), day(), month(), year() };
  tmElements_t releData = {0, dataR1.minutos, dataR1.inicio, weekday(), day(), month(), year() };
  tmElements_t timeNowMinusOne = {0, 0,0, 0, 1, 0, 0 };
  //tm releData = {0, dataR1.minutos, dataR1.inicio, weekday(), day(), month(), year() };
  
  time_t t_ahora = makeTime(timeNow);
  time_t t_rele = makeTime(releData);
  time_t t_ahora_menosUno = t_ahora - SECS_PER_DAY;

  long int diferencia = difftime(t_ahora, t_rele);
  long int diferenciaMenosUno = difftime(t_ahora_menosUno, t_rele);
  unsigned long int max = dataR1.fin * 60;
  bool dentroDeRango = (diferencia >= 0) && (diferencia < max);

  Serial.println("La diferencia de segundos es de: " + String(diferencia));
  Serial.println(" ");
  Serial.println("La diferencia de segundos MENOS UN DÍA es de: " + String(diferenciaMenosUno));
  Serial.println(" ");
  Serial.println("La cantidad de segundos en un día es de: " + String(SECS_PER_DAY));
  Serial.println("Tiempo límite: " + String(max));

  if(dentroDeRango)
    digitalWrite(LED_BUILTIN, HIGH);
  else
    digitalWrite(LED_BUILTIN, LOW);   
  delay(4500);
    
}

void getDateTime(){
  
  int hora = 23, min = 58, sec = 0, mes = 1, dia = 1, year = 2010 - 1970;
  
  setTime(hora, min, sec, mes, dia, year);
  horaInicial = now();
  delay(100);
  Serial.flush();
  delay(100);
}