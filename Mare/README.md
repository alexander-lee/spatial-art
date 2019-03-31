# Mare - Arduino Project

### Description
Mare is a marionette with no strings attached. The goal of the project was to create a puppet that you could control with your fingers without requiring anything physical. The project consists of a glove with flex sensors that uses radio frequencies to communicate with a toy horse with servos. Bending a finger will rotate a specific servo on the horse, allowing for full control (however in this prototype, the mobility isn't the where I want it yet)

### Code
* [GloveSender](/GloveSender) involves RF transmission from the flex sensor glove
* [HorseReceiver](HorseReceiver) involves receiving RF data in order to move the servos on the horse
* [RFTest](RFTest) is a test to ensure the RF module is working correctly
* [SweepCalibration](SweepCalibration) is a modified version of `Sweep.c`

### Demo
![Demo](https://github.com/alexander-lee/spatial-art/blob/master/Mare/Demo.gif?raw=true)
**Video:** https://www.youtube.com/watch?v=_txTRFKy-fQ

### Resources
* [NRF24L01 Tutorial](https://howtomechatronics.com/tutorials/arduino/arduino-wireless-communication-nrf24l01-tutorial/)
* [Arduino Flex Glove](https://www.youtube.com/watch?v=oBpehYPtOAA)
