#include <Servo.h>

// Pin definitions
const int trigPin = 10;
const int echoPin = 11;
const int servoPin = 12;   // Kept at Pin 9 from your original code
const int buzzerPin = 8;  // Buzzer connected to Pin 8

long duration;
int distance;
Servo myServo;

int calculateDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  duration = pulseIn(echoPin, HIGH, 30000); // 30ms timeout (~5m max range)
  if (duration == 0) {
    return 40; // Default to max range if nothing detected
  }
  int d = duration * 0.034 / 2;
  return (d > 40) ? 40 : d;
}

// Adjusts buzzer tone frequency based on object proximity
void handleBuzzer(int d) {
  if (d < 40 && d > 0) {
    // 2cm (near) = 2000Hz (high pitch/intense), 40cm (far) = 300Hz (low pitch)
    int toneFreq = map(d, 2, 40, 2000, 300);
    tone(buzzerPin, toneFreq);
  } else {
    noTone(buzzerPin); // Silent when out of range
  }
}

void setup() {
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  
  Serial.begin(9600);
  myServo.attach(servoPin);
}

void loop() {
  // Sweep left to right (0° to 180°)
  for (int i = 0; i <= 180; i++) {
    myServo.write(i);
    delay(20);
    distance = calculateDistance();
    handleBuzzer(distance);
    
    Serial.print(i);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(".");
  }
  
  // Sweep right to left (180° to 0°)
  for (int i = 180; i >= 0; i--) {
    myServo.write(i);
    delay(20);
    distance = calculateDistance();
    handleBuzzer(distance);
    
    Serial.print(i);
    Serial.print(",");
    Serial.print(distance);
    Serial.print(".");
  }
}