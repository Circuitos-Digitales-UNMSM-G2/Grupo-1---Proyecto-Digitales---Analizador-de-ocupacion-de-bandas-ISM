#include <WiFi.h>
// ESP32-S3 Analizador ISM E5
static const int FPGA_RX_PIN=16;
static const int FPGA_TX_PIN=43;
const uint32_t UART_BAUD=115200;
const uint32_t SCAN_INTERVAL_MS=5000;
struct CanalInfo{int redes=0;int sumaRSSI=0;int rssiMax=-100;int rssiMin=0;};
CanalInfo ch1,ch6,ch11;
uint8_t normalizarRSSI(int r){int v=r+100; if(v<0)v=0; if(v>100)v=100; return v;}
uint8_t ocupacion(int n){if(n<=0)return 0; if(n==1)return 20; if(n==2)return 40; if(n==3)return 60; if(n==4)return 80; return 100;}
const char* estado(uint8_t o){if(o<=20)return "LIBRE"; if(o<=60)return "MODERADO"; return "CONGESTIONADO";}
void actualizar(CanalInfo &c,int r){c.redes++; c.sumaRSSI+=r; if(r>c.rssiMax)c.rssiMax=r; if(c.redes==1||r<c.rssiMin)c.rssiMin=r;}
void enviarFPGA(uint8_t r1,uint8_t o1,uint8_t r6,uint8_t o6,uint8_t r11,uint8_t o11){Serial2.write(r1);Serial2.write(o1);Serial2.write(r6);Serial2.write(o6);Serial2.write(r11);Serial2.write(o11);Serial2.flush();}
void setup(){Serial.begin(115200);delay(1500);WiFi.mode(WIFI_STA);WiFi.disconnect();Serial2.begin(UART_BAUD,SERIAL_8N1,FPGA_RX_PIN,FPGA_TX_PIN);Serial.println("Analizador ISM");}
void loop(){ch1=CanalInfo();ch6=CanalInfo();ch11=CanalInfo();int n=WiFi.scanNetworks();Serial.println("\nSSID\tCH\tRSSI");for(int i=0;i<n;i++){int ch=WiFi.channel(i);int r=WiFi.RSSI(i);Serial.printf("%-20s\t%2d\t%d dBm\n",WiFi.SSID(i).c_str(),ch,r);if(ch==1)actualizar(ch1,r);else if(ch==6)actualizar(ch6,r);else if(ch==11)actualizar(ch11,r);}int a1=ch1.redes?ch1.sumaRSSI/ch1.redes:-100;int a6=ch6.redes?ch6.sumaRSSI/ch6.redes:-100;int a11=ch11.redes?ch11.sumaRSSI/ch11.redes:-100;uint8_t o1=ocupacion(ch1.redes),o6=ocupacion(ch6.redes),o11=ocupacion(ch11.redes);Serial.printf("\nCH1:%d redes RSSI=%d OCC=%u %%%% %s\n",ch1.redes,a1,o1,estado(o1));Serial.printf("CH6:%d redes RSSI=%d OCC=%u %%%% %s\n",ch6.redes,a6,o6,estado(o6));Serial.printf("CH11:%d redes RSSI=%d OCC=%u %%%% %s\n",ch11.redes,a11,o11,estado(o11));enviarFPGA(normalizarRSSI(a1),o1,normalizarRSSI(a6),o6,normalizarRSSI(a11),o11);delay(SCAN_INTERVAL_MS);}