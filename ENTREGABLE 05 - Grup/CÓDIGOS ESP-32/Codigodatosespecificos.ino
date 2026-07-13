//CODIGO SIMULACION DE DATOS ESPECÍFICOS

#include <Arduino.h>

// ESP32-S3 Concentrador -> FPGA (Solo inyección de datos duros)
static const int FPGA_RX_PIN = 16; // No se usa, solo se declara para la librería
static const int FPGA_TX_PIN = 43; // Pin físico de transmisión hacia la FPGA
static const uint32_t UART_BAUD = 115200;
static const uint32_t SEND_INTERVAL_MS = 3000; // Envía los datos cada 3 segundos

// Valores fijos e inmutables del Testbench
const uint8_t RSSI_CH1  = 75;
const uint8_t OCC_CH1   = 55; // CH1: Ocupación 55%

const uint8_t RSSI_CH6  = 65;
const uint8_t OCC_CH6   = 15; // CH6: Ocupación 15% (El menor, debe ganar)

const uint8_t RSSI_CH11 = 60;
const uint8_t OCC_CH11  = 60; // CH11: Ocupación 60%

void setup() {
  // Inicializamos únicamente el puerto físico Serial2 acoplado al Pin 43
  Serial2.begin(UART_BAUD, SERIAL_8N1, FPGA_RX_PIN, FPGA_TX_PIN);
}

void loop() {
  // Envío secuencial y directo de la ráfaga de 6 bytes binarios por el hardware
  Serial2.write(RSSI_CH1);
  Serial2.write(OCC_CH1);
  Serial2.write(RSSI_CH6);
  Serial2.write(OCC_CH6);
  Serial2.write(RSSI_CH11);
  Serial2.write(OCC_CH11);
  
  // Forzar la salida inmediata de los bytes desde el buffer interno
  Serial2.flush(); 

  // Pausa de 3 segundos antes de volver a inyectar la misma trama
  delay(SEND_INTERVAL_MS);
}