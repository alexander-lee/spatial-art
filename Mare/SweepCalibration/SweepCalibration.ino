/* Sweep
 by BARRAGAN <http://barraganstudio.com>
 This example code is in the public domain.

 modified 8 Nov 2013
 by Scott Fitzgerald
 http://www.arduino.cc/en/Tutorial/Sweep
*/

#include <Servo.h>

const int NUM_SERVOS = 1;

char servoPins[NUM_SERVOS] = {9};//3, 5, 6, 9};
Servo servos[NUM_SERVOS];  // create servo object to control a servo
// twelve servo objects can be created on most boards

int pos = 0;    // variable to store the servo position

void setup() {
  Serial.begin(9600);
  for (char i = 0; i < NUM_SERVOS; ++i) {
    servos[i].attach(servoPins[i]);
  }
}

void loop() {
  for (pos = 0; pos <= 180; pos += 1) {
    for (char i = 0; i < NUM_SERVOS; ++i) {
      servos[i].write(pos);
    }
    delay(50);
  }
  for (pos = 180; pos >= 0; pos -= 1)  {
    for (char i = 0; i < NUM_SERVOS; ++i) {
      servos[i].write(pos);
    }
    delay(50);
  }
  delay(1000);

    // servos[0].write(90);
}
