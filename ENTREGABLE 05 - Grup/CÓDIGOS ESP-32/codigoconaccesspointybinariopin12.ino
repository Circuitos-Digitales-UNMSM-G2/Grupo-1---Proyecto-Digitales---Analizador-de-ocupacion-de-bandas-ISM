// CON BITS BINARIOS DE RESULTADO + ACCESS POINT WIFI + MÉTRICA PDR
#include <Arduino.h>
#include <WiFi.h>

// Credenciales para tu nuevo Access Point
const char* ssid = "FPGA_Auto_Band";
const char* password = "password123";

// ESP32 Receptor <- FPGA
static const int PIN_VALID = 25; 

// Bus de datos (Si mantienes el pin 12, recuerda el orden de encendido)
static const int DATA_PINS[8] = {26, 27, 14, 12, 13, 4, 17, 16}; 

volatile bool datoListo = false;
uint8_t canalActual = 0; 

// --- VARIABLES PARA MÉTRICA PDR ---
uint32_t paquetesRecibidos = 0;
uint32_t paquetesEsperados = 100; // Cambia este número según cuántas pruebas mande el Concentrador

void IRAM_ATTR onOutputValid() {
  datoListo = true;
}

void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(PIN_VALID, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_VALID), onOutputValid, RISING);

  for (int i = 0; i < 8; i++) {
    pinMode(DATA_PINS[i], INPUT);
  }

  WiFi.mode(WIFI_AP);

  Serial.println("=== ESP32 Receptor y AP Listo ===");
  Serial.println("Esperando señal 'output_valid' de la FPGA...");
}

void loop() {
  if (datoListo) {
    // Deshabilitar interrupciones momentáneamente para una lectura segura
    noInterrupts();
    datoListo = false; 
    interrupts();

    // Pequeño delay de estabilización eléctrica en el bus paralelo
    delayMicroseconds(5);

    uint8_t canalRecomendado = 0;
    int estadosPines[8]; 

    // 1. Leer el bus paralelo
    for (int i = 0; i < 8; i++) {
      int nivelLogico = digitalRead(DATA_PINS[i]);
      estadosPines[i] = nivelLogico; 

      if (nivelLogico == HIGH) {
        canalRecomendado |= (1 << i);
      }
    }

    paquetesRecibidos++; // Incrementamos el contador para la métrica

    // 2. Desglose y Reporte en Monitor Serie
    Serial.println("\n====================================");
    Serial.println("[FPGA ALERTA]: Lectura de Pines en Paralelo");
    Serial.println("------------------------------------");
    for (int i = 7; i >= 0; i--) {
      Serial.printf("  Bit %d (GPIO %2d): %d\n", i, DATA_PINS[i], estadosPines[i]);
    }
    Serial.println("------------------------------------");
    Serial.printf("--> Resultado Combinado de FPGA: CH%u\n", canalRecomendado);
    
    // Calcular e imprimir métrica de rendimiento PDR en tiempo real
    float pdr = ((float)paquetesRecibidos / (float)paquetesEsperados) * 100.0;
    Serial.printf("[MÉTRICA PDR]: %u/%u paquetes recibidos (%.2f%% PDR)\n", paquetesRecibidos, paquetesEsperados, pdr);
    Serial.println("------------------------------------");
    
    // 3. Generar el Access Point en base al canal recomendado
    if (canalRecomendado >= 1 && canalRecomendado <= 14) {
      if (canalRecomendado != canalActual) {
        Serial.printf("[WIFI] Creando Access Point en el CH%u...\n", canalRecomendado);
        
        WiFi.softAPdisconnect(true);
        delay(100);

        bool apIniciado = WiFi.softAP(ssid, password, canalRecomendado, 0, 4);

        if (apIniciado) {
          Serial.printf("[WIFI] ÉXITO: Red '%s' disponible en CH%u\n", ssid, canalRecomendado);
          Serial.print("[WIFI] Dirección IP del ESP32: ");
          Serial.println(WiFi.softAPIP());
          
          canalActual = canalRecomendado; 
        } else {
          Serial.println("[WIFI] ERROR: No se pudo levantar el Access Point.");
        }
      } else {
         Serial.printf("[WIFI] INFO: El AP ya está emitiendo en el CH%u. Sin cambios.\n", canalRecomendado);
      }
    } else {
      Serial.println("[WIFI] ERROR: El canal recibido no es un canal WiFi válido (1-14).");
    }

    Serial.println("====================================");
  }
}