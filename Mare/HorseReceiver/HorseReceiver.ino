#include <SPI.h>
#include <RF24.h>
#include <Servo.h>

// CONSTANTS
const int NUM_SENSORS = 4;

const byte address[6] = "00001";
const char servoPins[] = {3, 5, 6, 9}; // Pin (D)

// GLOBALS
RF24 radio(7, 8); // CE, CSN
Servo servos[NUM_SENSORS];

void setup() {
  // Serial.begin(9600);

  // Attach Servos
  for (char i = 0; i < NUM_SENSORS; ++i) {
    servos[i].attach(servoPins[i]);
  }

  // Initial Servo Positions
  servos[0].write(90);
  servos[1].write(90);
  servos[2].write(90);
  servos[3].write(90);
  

  radio.begin();
  radio.openReadingPipe(0, address);
  radio.setPALevel(RF24_PA_MIN);
  radio.startListening();
}

void loop() {
  if (radio.available()) {
    char readBuf[20] = "";
    radio.read(&readBuf, sizeof(readBuf));

    // DEBUG
    // Serial.println(readBuf);

    int servoIndex;
    int servoAngle; // 0 - 90 range 
    sscanf(readBuf, "%d %d", &servoIndex, &servoAngle);

    // NOTE: 90 is the neutral position (except for the front left leg sadly)
    
    // 4 Flex Sensors
    // servos[0].write(servoAngle);

    // 2 Flex Sensor Version
    if (servoIndex == 0) {
      servos[0].write(constrain(map(servoAngle, 0, 90, 90, 0), 0, 180)); // Front Right (Start 90, End 0)
      servos[1].write(constrain(map(servoAngle, 0, 90, 90, 180), 0, 180)); // Front Left (Start 90, End 180)
    } 
    else if (servoIndex == 1) {
      servos[2].write(constrain(map(servoAngle, 0, 90, 70, 0), 0, 180)); // Back Left (Start 90, End 0)
      servos[3].write(constrain(map(servoAngle, 0, 90, 70, 180), 0, 180)); // Back Right (Start 90, End 180)
    }
//    if (servoIndex == 0) {
//      servos[0].write(constrain(map(servoAngle, 0, 90, 90, 0), 0, 180)); // Front Right (Start 90, End 0)
//    } 
//    else if (servoIndex == 1) {
//      servos[1].write(constrain(map(servoAngle, 0, 90, 90, 180), 0, 180)); // Front Left (Start 90, End 180)
//    }
    
    delay(15);
  }
}
