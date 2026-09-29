


Smart SONAR – Adaptive Acoustic Sensing System

A low-cost real-time SONAR-inspired sensing and visualization system built using an Arduino, HC-SR04 ultrasonic sensor, servo motor, buzzer, and Processing.

The system scans the surrounding area by rotating the ultrasonic sensor from 0° to 180°. The measured angle and distance are transmitted from the Arduino to a computer through serial communication, where Processing converts the data into a real-time SONAR-style visualization.

1. Features

- 0°–180° servo-based scanning
- HC-SR04 ultrasonic distance measurement
- Maximum sensing range configured to 40 cm
- Distance-based buzzer feedback
- Real-time Arduino-to-Processing serial communication
- Real-time SONAR radar visualization
- Object detection with angle and distance
- Scan history display
- Waveform visualization
- Frequency-spectrum visualization
- 3D acoustic-map visualization
- Continuous bidirectional scanning

2. System Overview

The system consists of two main software components:

Arduino

The Arduino program controls the:

- HC-SR04 ultrasonic sensor
- Servo motor
- Buzzer

It measures the distance of objects at different servo angles and sends the angle-distance data to the computer through serial communication.

Processing

The Processing program receives the serial data from the Arduino and converts it into a real-time visual dashboard containing the SONAR radar, detected objects, scan history, waveform, spectrum, and 3D acoustic map.

3. Hardware Components

- Arduino board
- HC-SR04 ultrasonic sensor
- Servo motor
- Passive buzzer
- Breadboard
- Jumper wires
- USB cable
- Computer

4. Hardware Connections

Component| Arduino Pin
HC-SR04 Trig| D10
HC-SR04 Echo| D11
Servo Signal| D12
Buzzer| D8
HC-SR04 VCC| 5V
HC-SR04 GND| GND
Servo GND| GND

«The servo should be powered appropriately for the hardware setup. If an external power supply is used, its ground must be connected to Arduino GND.»

5. Software Requirements

- Arduino IDE
- Processing IDE
- Arduino Servo library
- Processing Serial library

6. How It Works

1. The servo rotates the HC-SR04 ultrasonic sensor from 0° to 180°.
2. The ultrasonic sensor measures the distance of objects.
3. The Arduino limits the displayed sensing range to 40 cm.
4. The buzzer changes its tone according to the detected distance.
5. The Arduino sends the angle and distance through serial communication.
6. Processing receives and interprets the serial data.
7. Processing displays the measurements as a real-time SONAR visualization.
8. The scan data is used to generate the radar display, scan history, waveform, spectrum, and 3D acoustic map.

7. Serial Data Format

The Arduino sends data in the following format:

angle,distance.

Example:

90,25.

Where:

- "90" = servo angle in degrees
- "25" = measured distance in centimetres
- "." = end-of-data marker used by the Processing serial parser

8. How to Run

Arduino

1. Open "Arduino/SONAR_Arduino.ino" in the Arduino IDE.
2. Connect the Arduino to the computer through USB.
3. Connect the HC-SR04, servo motor, and buzzer according to the hardware connections.
4. Select the correct Arduino board and serial port.
5. Upload the Arduino program.
6. Keep the Arduino connected to the computer.

Processing

1. Open the Processing IDE.
2. Open "Processing/SONAR_Processing.pde".
3. Make sure the Processing Serial library is available.
4. Ensure the Arduino Serial Monitor is closed.
5. Run the Processing sketch.
6. The Processing dashboard will display the real-time SONAR visualization.
7. Place an object within the configured 40 cm sensing range to test detection.

9. Important Notes

- The Arduino Serial Monitor should be closed while Processing is using the serial port.
- The Processing sketch is configured for live Arduino operation using "simulationMode = false".
- The Arduino and Processing baud rate must match. The current system uses "9600 baud".
- If multiple serial devices are connected, the serial-port selection in the Processing code may need to be adjusted.
- The 40 cm maximum range is a project-level software limit.

10. Repository Structure

SIH-Project--Smart-SONAR-code/
│
├── README.md
│
├── Arduino/
│   └── SONAR_Arduino.ino
│
└── Processing/
    └── SONAR_Processing.pde

11. Project Purpose

The project demonstrates how low-cost ultrasonic sensing, servo-based scanning, serial communication, and computer-based visualization can be combined to create an interactive SONAR-inspired sensing platform.

The prototype is intended as a foundation for further development toward more advanced acoustic sensing and underwater monitoring systems.

12. Future Scope

Potential future improvements include:

- Wider and longer-range sensing
- Waterproof ultrasonic/acoustic transducers
- 360° scanning
- Improved signal processing
- Multiple-sensor integration
- More accurate spatial mapping
- Underwater acoustic sensing
- Integration with autonomous underwater platforms
- Advanced object tracking and classification