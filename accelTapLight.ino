#include <Adafruit_CircuitPlayground.h>
#include <Wire.h>
#include <SPI.h>

// Adjust this number for the sensitivity of the 'click' force
// this strongly depend on the range! for 16G, try 5-10
// for 8G, try 10-20. for 4G try 20-40. for 2G try 40-80
#define CLICKTHRESHHOLD 120

void setup(void) {
  while (!Serial);
  
  Serial.begin(9600);
  CircuitPlayground.begin();
  
  CircuitPlayground.setAccelRange(LIS3DH_RANGE_2_G);   // 2, 4, 8 or 16 G!
  
  // 0 = turn off click detection & interrupt
  // 1 = single click only interrupt output
  // 2 = double click only interrupt output, detect single click
  // Adjust threshhold, higher numbers are less sensitive
  CircuitPlayground.setAccelTap(1, CLICKTHRESHHOLD);
  
  // have a procedure called when a tap is detected
  attachInterrupt(digitalPinToInterrupt(CPLAY_LIS3DH_INTERRUPT), tapTime, FALLING);
}

void tapTime(void) {
  // do something :)
   Serial.print("Tap! ");
   Serial.println(millis()); // the time
}

void loop() {
  //tracks the light on the sensor
  float light = CircuitPlayground.lightSensor();
  Serial.print("Light! ");
  Serial.println(light);
  delay(5000);
}
