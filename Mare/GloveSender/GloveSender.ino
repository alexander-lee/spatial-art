#include <SPI.h>
#include <RF24.h>

// CONSTANTS
const int NUM_SENSORS = 2;
const int NUM_READINGS = 10;

const char flexPins[] = {0, 1}; // Pin of Analog Input (A)
const byte address[6] = "00001";

// GLOBALS
int readings[NUM_SENSORS][NUM_READINGS]; // the readings from the analog input
int readIndex; // Current index of reading
int totals[NUM_SENSORS]; // Total of all readings such that the average can easily be calculated

int flexMax;
int flexMin;

bool readingsFilled;

RF24 radio(7, 8); // CE, CSN

void setup() {
  // Serial.begin(9600);

  // Initialize Min and Max Flex Values
  flexMax = 900;
  flexMin = 800;

  // Initialize Readings
  readIndex = 0;
  readingsFilled = false;
  for (char i = 0; i < NUM_SENSORS; ++i) {
    totals[i] = 0;
    
    for (char j = 0; j < NUM_READINGS; ++j) {
      readings[i][j] = 0;
    }
  }
  
  radio.begin();
  radio.openWritingPipe(address);
  radio.setPALevel(RF24_PA_MIN);
  radio.stopListening();
}

void loop() {
  // Perform reading on all sensors
  for (char i = 0; i < NUM_SENSORS; ++i) {
    // Subtract latest reading
    totals[i] -= readings[i][readIndex];

    // Collect next reading and add it to the total
    int flexResistance = analogRead(flexPins[i]); // Flex Pin at A0
    
    readings[i][readIndex] = flexResistance;
    totals[i] += readings[i][readIndex];

    int recordedAverage = readingsFilled ? (totals[i] / NUM_READINGS) : (totals[i] / (readIndex + 1)); 
    // DEBUG
    // if (i == 1) Serial.println(recordedAverage);

    // Update min and max if recordedAverage seems to be less or greater than what was recorded
//    if (recordedAverage > flexMax) {
//      flexMax = recordedAverage;
//    }
//  
//    if (recordedAverage < flexMin) {
//      flexMin = recordedAverage;
//    }
//   
    int servoAngle = map(recordedAverage, flexMin, flexMax, 0, 90);
    servoAngle = constrain(servoAngle, 0, 180);
  
    // Send Servo Index and Angle over the buffer
    char sendBuf[20];
    sprintf(sendBuf, "%d %d", i, servoAngle);
    
    radio.write(&sendBuf, sizeof(sendBuf));
    
    // DEBUG
    // Serial.println(sendBuf);
    delay(15);
  }

  // Update readIndex for next iteration
  if (!readingsFilled && (readIndex + 1) >= NUM_READINGS) {
    readingsFilled = true;
  }
  readIndex = (readIndex + 1) % NUM_READINGS;
}
