import processing.serial.*;

// =============================================================
// SMART SONAR / ADAPTIVE ACOUSTIC SENSING SYSTEM
// Ultra-Crisp Native 1080p Full HD Fullscreen Dashboard
// =============================================================

// --- Serial & Sensor Variables ---
Serial myPort;
String data = "";
int iAngle = 0;       // -90 to +90 for dashboard display
int rawAngle = 90;    // 0 to 180 standard servo range
int iDistance = 0;    // Current reading in cm

// Sub-degree resolution for ultra-smooth rendering (721 samples = 0.25 deg step)
final int SAMPLES = 721;
float[] scanDistances = new float[SAMPLES];
float[] radarAlpha    = new float[SAMPLES]; // Standard sweep fade
float[] map3DAlpha    = new float[SAMPLES]; // Long persistent memory for 3D voxels

// --- Dynamic Real-Time Scan History Structure ---
class ScanLog {
  String timestamp;
  String message;
  boolean isObstacle;

  ScanLog(String time, String msg, boolean obstacle) {
    this.timestamp = time;
    this.message = msg;
    this.isObstacle = obstacle;
  }
}

ArrayList<ScanLog> historyLogs = new ArrayList<ScanLog>();
final int MAX_LOGS = 6; // Display up to 6 events
long lastLogTime = 0;
boolean wasObstacleDetected = false;

// Hardware Real-Time Mode (Set simulationMode = false for live Arduino input)
boolean simulationMode = false; 

// Dynamic animation interpolation variables
float smoothDist = 40.0;
float wavePhase = 0;

// Typography Handles
PFont fontRegular, fontBold, fontLarge, fontHistory;

// Layout coordinates
float originX, originY, maxRadius;

void setup() {
  // Native Full HD display rendering with 8x MSAA anti-aliasing
  fullScreen();
  pixelDensity(displayDensity());
  smooth(8);

  // Scaled typography with sub-pixel hinting for crisp text
  fontRegular = createFont("Segoe UI", 15, true);
  fontBold    = createFont("Segoe UI Semibold", 16, true);
  fontLarge   = createFont("Segoe UI Bold", 26, true);
  fontHistory = createFont("Segoe UI Semibold", 16, true);

  originX = width * 0.50;
  originY = height * 0.53;
  maxRadius = height * 0.36;

  for (int i = 0; i < SAMPLES; i++) {
    scanDistances[i] = 0;
    radarAlpha[i] = 0;
    map3DAlpha[i] = 0;
  }

  addHistoryLog("System initialized - Sonar active", false);

  if (!simulationMode) {
    printArray((Object[])Serial.list());
    if (Serial.list().length > 0) {
      String portName = Serial.list()[0];
      myPort = new Serial(this, portName, 9600);
      myPort.bufferUntil('.');
      println("Connected to: " + portName);
    } else {
      println("No serial ports detected. Connect Arduino and restart.");
    }
  }
}

void draw() {
  background(2, 8, 20);

  processRealtimeLog();

  // Live sensor response for waveform/spectrum
  float targetDist = (iDistance > 0 && iDistance < 40) ? (float)iDistance : 40.0;
  smoothDist = lerp(smoothDist, targetDist, 0.18);
  wavePhase += map(smoothDist, 5, 40, 0.35, 0.08);

  updateFading();

  drawGridBackground();
  drawSmoothSonarHeatmap(); // Real-time radar swept heatmap
  drawCenterOriginGlow();   // Sensor emitter glow
  drawRadarSweepBeam();     // Physical servo-locked sweep beam
  drawRadarGrid();          // Polar overlay grid
  drawUI();
}

// -------------------------------------------------------------
// Real-Time Scan History Management
// -------------------------------------------------------------
void processRealtimeLog() {
  boolean currentDetected = (iDistance > 0 && iDistance < 40);
  long now = millis();

  if (currentDetected != wasObstacleDetected && (now - lastLogTime > 750)) {
    if (currentDetected) {
      addHistoryLog("Obstacle detected – " + iDistance + " cm, " + iAngle + "°", true);
    } else {
      addHistoryLog("Clear path – scanning sector", false);
    }
    wasObstacleDetected = currentDetected;
    lastLogTime = now;
  }
}

void addHistoryLog(String msg, boolean obstacle) {
  String timeStr = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  historyLogs.add(0, new ScanLog(timeStr, msg, obstacle));
  
  while (historyLogs.size() > MAX_LOGS) {
    historyLogs.remove(historyLogs.size() - 1);
  }
}

// -------------------------------------------------------------
// Fading Logic: Radar Sweeps Fast / 3D Map Persists Longer
// -------------------------------------------------------------
void updateFading() {
  for (int i = 0; i < SAMPLES; i++) {
    // 1. Radar fading
    if (radarAlpha[i] > 0) {
      radarAlpha[i] -= 3.5;
      if (radarAlpha[i] < 0) radarAlpha[i] = 0;
    }

    // 2. 3D Acoustic Map slow persistence
    if (map3DAlpha[i] > 0) {
      map3DAlpha[i] -= 0.50;
      if (map3DAlpha[i] < 0) {
        map3DAlpha[i] = 0;
        scanDistances[i] = 0;
      }
    }
  }
}

void drawSmoothSonarHeatmap() {
  pushMatrix();
  translate(originX, originY);
  noStroke();

  for (int i = 0; i < SAMPLES - 1; i++) {
    float a1 = i * 0.25;
    float a2 = (i + 1) * 0.25;

    float alpha1 = radarAlpha[i];
    float alpha2 = radarAlpha[i + 1];

    if (alpha1 <= 1 && alpha2 <= 1) continue;

    float r1 = radians(180 - a1);
    float r2 = radians(180 - a2);

    float d1 = scanDistances[i];
    float d2 = scanDistances[i + 1];

    float cos1 = cos(r1), sin1 = -sin(r1);
    float cos2 = cos(r2), sin2 = -sin(r2);

    // Safe Sector (Green)
    float rSafe1 = (d1 > 0 && d1 < 40) ? map(d1, 0, 40, 0, maxRadius) : maxRadius;
    float rSafe2 = (d2 > 0 && d2 < 40) ? map(d2, 0, 40, 0, maxRadius) : maxRadius;

    beginShape(QUAD_STRIP);
    fill(0, 255, 100, alpha1 * 0.85);
    vertex(0, 0);
    fill(0, 255, 100, alpha2 * 0.85);
    vertex(0, 0);

    fill(0, 230, 80, alpha1 * 0.55);
    vertex(rSafe1 * cos1, rSafe1 * sin1);
    fill(0, 230, 80, alpha2 * 0.55);
    vertex(rSafe2 * cos2, rSafe2 * sin2);
    endShape();

    // Obstacle Sector (Yellow -> Red gradient)
    if ((d1 > 0 && d1 < 40) || (d2 > 0 && d2 < 40)) {
      beginShape(QUAD_STRIP);
      fill(255, 190, 0, alpha1 * 0.9);
      vertex(rSafe1 * cos1, rSafe1 * sin1);
      fill(255, 190, 0, alpha2 * 0.9);
      vertex(rSafe2 * cos2, rSafe2 * sin2);

      fill(255, 25, 25, alpha1 * 0.95);
      vertex(maxRadius * cos1, maxRadius * sin1);
      fill(255, 25, 25, alpha2 * 0.95);
      vertex(maxRadius * cos2, maxRadius * sin2);
      endShape();
    }
  }
  popMatrix();
}

void drawCenterOriginGlow() {
  pushMatrix();
  translate(originX, originY);
  noStroke();
  for (int r = 60; r > 0; r -= 4) {
    fill(0, 255, 120, map(r, 0, 60, 55, 0));
    arc(0, 0, r * 2, r * 2, PI, TWO_PI);
  }
  popMatrix();
}

void drawRadarSweepBeam() {
  pushMatrix();
  translate(originX, originY);

  float rad = radians(180 - rawAngle);

  // Soft glow
  stroke(0, 255, 150, 45);
  strokeWeight(7);
  line(0, 0, maxRadius * cos(rad), -maxRadius * sin(rad));

  // Core beam matching physical servo angle
  stroke(210, 255, 230, 255);
  strokeWeight(2.0);
  line(0, 0, (maxRadius + 5) * cos(rad), -(maxRadius + 5) * sin(rad));

  popMatrix();
}

// -------------------------------------------------------------
// UI & Dashboard Panels
// -------------------------------------------------------------
void drawUI() {
  drawHeader();
  drawAdaptiveSonarSettingsPanel(); 
  drawLiveReadingsPanel();
  drawLiveWaveformPanel();          
  drawLiveSpectrumPanel();          
  drawScanHistoryPanel();
  drawAcousticMapPanel();
  drawSystemStatusPanel();
  drawRadarLegend();
  drawRadarLabels();
  drawFooterBar();
}

void drawHeader() {
  textFont(fontLarge);
  fill(0, 180, 255);
  textAlign(LEFT, CENTER);
  text("Smart SONAR  /  Adaptive Acoustic Sensing System", width * 0.025, height * 0.04);

  // Status Indicator
  textFont(fontBold);
  fill(0, 255, 120);
  ellipse(width * 0.70, height * 0.04, 12, 12);
  text("System Active", width * 0.71, height * 0.04);

  // System Calendar Date
  String[] months = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
  String dateStr = nf(day(), 2) + " " + months[month()] + " " + year();

  textFont(fontRegular);
  fill(160, 190, 220);
  textAlign(RIGHT, CENTER);
  text(nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2) + " | " + dateStr, width * 0.975, height * 0.04);
}

void drawAdaptiveSonarSettingsPanel() {
  float pX = width * 0.025;
  float pY = height * 0.075;
  float pW = width * 0.22;
  float pH = height * 0.45;

  drawPanel(pX, pY, pW, pH, "Adaptive Sonar Settings");
  
  textFont(fontRegular);
  fill(160, 190, 220);
  textAlign(LEFT, TOP);
  text("Frequency:\n\nPulse Duration:\n\nWaveform:\n\nTransmitter Power:\n\nMax Range:\n\nResolution:\n\nSampling Mode:", pX + 22, pY + 50);

  int dynamicFreq = int(map(smoothDist, 5, 40, 120, 40));
  String powerMode = (smoothDist < 15) ? "High (Near Field)" : "Low (Eco)";

  textAlign(RIGHT, TOP);
  fill(255, 204, 0);
  text(dynamicFreq + " kHz\n\n2.5 ms\n\nLFM Chirp\n\n" + powerMode + "\n\n40 cm\n\nHigh Res\n\nContinuous", pX + pW - 22, pY + 50);
}

void drawLiveReadingsPanel() {
  float pX = width * 0.755;
  float pY = height * 0.075;
  float pW = width * 0.22;
  float pH = height * 0.16;

  drawPanel(pX, pY, pW, pH, "Live Readings");

  textFont(fontRegular);
  fill(160, 190, 220);
  textAlign(LEFT, TOP);
  text("Distance:\nAngle:\nObject:", pX + 22, pY + 45);

  textAlign(RIGHT, TOP);
  if (iDistance < 40 && iDistance > 0) {
    fill(0, 255, 120);
    text(iDistance + " cm", pX + pW - 22, pY + 45);
  } else {
    fill(255, 70, 70);
    text("Out of Range", pX + pW - 22, pY + 45);
  }

  fill(0, 255, 120);
  text(iAngle + "°", pX + pW - 22, pY + 75);

  if (iDistance < 40 && iDistance > 0) {
    fill(255, 70, 70);
    text("Detected", pX + pW - 22, pY + 105);
  } else {
    fill(100, 130, 150);
    text("Clear", pX + pW - 22, pY + 105);
  }
}

void drawLiveWaveformPanel() {
  float pX = width * 0.755;
  float pY = height * 0.25;
  float pW = width * 0.22;
  float pH = height * 0.13;

  drawPanel(pX, pY, pW, pH, "Waveform Output");

  float waveFreqMultiplier = map(smoothDist, 5, 40, 2.5, 0.7);
  float waveAmplitude = (iDistance > 0 && iDistance < 40) ? map(smoothDist, 5, 40, 26, 12) : 10;

  stroke(255, (iDistance > 0 && iDistance < 40) ? 80 : 180, 0);
  strokeWeight(2.0);
  noFill();
  beginShape();
  for (int x = 0; x < pW - 44; x++) {
    float k = map(x, 0, pW - 44, 0.04, 0.28) * waveFreqMultiplier;
    float jitter = (iDistance > 0 && iDistance < 40) ? random(-1.2, 1.2) : 0;
    float y = sin(x * k + wavePhase) * waveAmplitude + jitter;
    vertex(pX + 22 + x, pY + pH * 0.52 + y);
  }
  endShape();

  textFont(fontRegular);
  fill(160, 190, 220);
  textAlign(CENTER, BOTTOM);
  text((iDistance > 0 && iDistance < 40) ? "Echo Return Detected" : "LFM Chirp (Transmitting)", pX + pW * 0.5, pY + pH - 8);
}

void drawLiveSpectrumPanel() {
  float pX = width * 0.755;
  float pY = height * 0.395;
  float pW = width * 0.22;
  float pH = height * 0.13;

  drawPanel(pX, pY, pW, pH, "Frequency Spectrum");

  float peakX = map(smoothDist, 5, 40, (pW - 44) * 0.75, (pW - 44) * 0.25);
  float maxPeakHeight = (iDistance > 0 && iDistance < 40) ? map(smoothDist, 5, 40, 52, 28) : 22;

  stroke(0, 200, 255, 200);
  strokeWeight(2.2);
  for (int x = 0; x < pW - 44; x += 4) {
    float variance = map(smoothDist, 5, 40, 220.0, 500.0);
    float noiseOffset = noise(x * 0.1, frameCount * 0.08) * 6;
    float h = exp(-pow(x - peakX, 2) / variance) * maxPeakHeight + noiseOffset;
    line(pX + 22 + x, pY + pH - 28, pX + 22 + x, pY + pH - 28 - h);
  }

  textFont(fontRegular);
  fill(140, 160, 180);
  textAlign(CENTER, TOP);
  text("60       80      100     120     140   (kHz)", pX + pW * 0.5, pY + pH - 24);
}

// -------------------------------------------------------------
// Scan History Panel
// -------------------------------------------------------------
void drawScanHistoryPanel() {
  float pX = width * 0.025;
  float pY = height * 0.54;
  float pW = width * 0.26;
  float pH = height * 0.40;

  drawPanel(pX, pY, pW, pH, "Scan History");

  textFont(fontHistory);
  for (int i = 0; i < historyLogs.size(); i++) {
    ScanLog log = historyLogs.get(i);
    float rowY = pY + 54 + (i * 30);

    if (log.isObstacle) {
      fill(255, 75, 75);
    } else {
      fill(0, 255, 130);
    }
    noStroke();
    ellipse(pX + 22, rowY, 8, 8);

    fill(215, 230, 245);
    textAlign(LEFT, CENTER);
    text(log.timestamp + "   " + log.message, pX + 38, rowY);
  }
}

// -------------------------------------------------------------
// Real-Time 3D Acoustic Perspective Map
// -------------------------------------------------------------
void drawAcousticMapPanel() {
  float pX = width * 0.30;
  float pY = height * 0.58;
  float pW = width * 0.43;
  float pH = height * 0.36;

  drawPanel(pX, pY, pW, pH, "3D Acoustic Map");

  float vpX = pX + pW * 0.5;
  float vpY = pY + pH * 0.22;
  float baseCenterY = pY + pH - 20;
  float baseHalfW = pW * 0.45;

  // Perspective Grid (Ground Floor)
  stroke(0, 80, 160, 110);
  strokeWeight(1.2);
  for (int i = 0; i <= 10; i++) {
    float x1 = lerp(vpX - baseHalfW, vpX + baseHalfW, i / 10.0);
    line(vpX, vpY, x1, baseCenterY);
  }
  for (int j = 0; j <= 5; j++) {
    float y = lerp(vpY, baseCenterY, j / 5.0);
    float span = lerp(0, baseHalfW, j / 5.0);
    line(vpX - span, y, vpX + span, y);
  }

  // Real-time sweeping scan cone
  float normAngle = map(iAngle, -90, 90, -1.0, 1.0);
  float beamBottomX = vpX + normAngle * baseHalfW;

  noStroke();
  fill(0, 255, 120, 35);
  beginShape();
  vertex(vpX, vpY);
  vertex(beamBottomX - 22, baseCenterY);
  vertex(beamBottomX + 22, baseCenterY);
  endShape(CLOSE);

  stroke(0, 255, 150, 180);
  strokeWeight(2.0);
  line(vpX, vpY, beamBottomX, baseCenterY);

  // Render 3D Voxels using slow-decaying map3DAlpha array
  for (int i = 0; i < SAMPLES; i += 8) {
    float d = scanDistances[i];
    float a = map3DAlpha[i];

    if (d > 0 && d < 40 && a > 8) {
      float angDeg = (i * 0.25) - 90;
      
      float z = map(d, 0, 40, 0.0, 1.0);
      float lateralNorm = map(angDeg, -90, 90, -1.0, 1.0);

      float scale = lerp(1.0, 0.35, z);
      float voxelX = vpX + (lateralNorm * baseHalfW * (1.0 - z * 0.75));
      float voxelY = lerp(baseCenterY, vpY, z);
      float voxelSize = 26 * scale;

      color faceColor = (d < 20) ? color(255, 50, 30, a) : color(255, 180, 0, a);
      color topColor  = (d < 20) ? color(255, 120, 50, a) : color(255, 220, 80, a);

      draw3DVoxel(voxelX, voxelY, voxelSize, faceColor, topColor, a);
    }
  }

  // Transducer mount base
  fill(0, 180, 255, 200);
  noStroke();
  ellipse(vpX, baseCenterY, 32, 12);
  fill(255);
  ellipse(vpX, baseCenterY, 12, 5);
}

void draw3DVoxel(float x, float y, float sz, color frontCol, color topCol, float alphaVal) {
  float h = sz * 1.3;

  // Front face
  stroke(255, 220, 100, alphaVal * 0.9);
  strokeWeight(1.4);
  fill(frontCol);
  rect(x - sz * 0.5, y - h, sz, h);

  // Top Face
  fill(topCol);
  beginShape();
  vertex(x - sz * 0.5, y - h);
  vertex(x - sz * 0.25, y - h - sz * 0.35);
  vertex(x + sz * 0.75, y - h - sz * 0.35);
  vertex(x + sz * 0.5, y - h);
  endShape(CLOSE);

  // Side Face
  fill(red(frontCol) * 0.75, green(frontCol) * 0.75, blue(frontCol) * 0.75, alphaVal);
  beginShape();
  vertex(x + sz * 0.5, y - h);
  vertex(x + sz * 0.75, y - h - sz * 0.35);
  vertex(x + sz * 0.75, y - sz * 0.35);
  vertex(x + sz * 0.5, y);
  endShape(CLOSE);
}

void drawSystemStatusPanel() {
  float pX = width * 0.745;
  float pY = height * 0.54;
  float pW = width * 0.23;
  float pH = height * 0.40;

  drawPanel(pX, pY, pW, pH, "✓  System Status");

  textFont(fontRegular);
  fill(160, 190, 220);
  textAlign(LEFT, TOP);
  text("Power Consumption:\n\nBattery / Supply:\n\nSignal Quality:\n\nSystem Health:", pX + 22, pY + 54);

  textAlign(RIGHT, TOP);
  fill(255);
  text("1.2 W\n\nOK", pX + pW - 22, pY + 54);
  fill(0, 255, 120);
  text("\n\n\n\nGood\n\nExcellent", pX + pW - 22, pY + 54);
}

void drawRadarLegend() {
  float lX = width * 0.435;
  float lY = height * 0.545;

  fill(0, 255, 100);
  rect(lX, lY, 16, 9, 2);
  fill(160, 190, 220);
  textFont(fontRegular);
  textAlign(LEFT, CENTER);
  text("Safe", lX + 24, lY + 4);

  fill(255, 204, 0);
  rect(lX + 76, lY, 16, 9, 2);
  fill(160, 190, 220);
  text("Warning", lX + 100, lY + 4);

  fill(255, 60, 60);
  rect(lX + 175, lY, 16, 9, 2);
  fill(160, 190, 220);
  text("Danger", lX + 199, lY + 4);
}

void drawRadarLabels() {
  fill(0, 200, 255);
  textFont(fontRegular);
  textAlign(CENTER, CENTER);

  int[] labels = {-90, -60, -30, 0, 30, 60, 90};
  for (int a : labels) {
    float rad = radians(a - 90);
    float x = originX + (maxRadius + 28) * cos(rad);
    float y = originY + (maxRadius + 28) * sin(rad);
    text(a + "°", x, y);
  }

  fill(140, 180, 210);
  for (int d = 10; d <= 40; d += 10) {
    float r = map(d, 0, 40, 0, maxRadius);
    text(d + " cm", originX, originY - r + 9);
  }
}

void drawFooterBar() {
  fill(0, 170, 240);
  textFont(fontRegular);
  textAlign(CENTER, CENTER);
  text("Smarter Sensing   |   Safer Navigation   |   Cleaner Oceans", width * 0.5, height * 0.975);
}

void drawPanel(float x, float y, float w, float h, String title) {
  stroke(0, 90, 160, 180);
  strokeWeight(1.4);
  fill(4, 16, 35, 220);
  rect(x, y, w, h, 8);

  textFont(fontBold);
  fill(0, 200, 255);
  textAlign(LEFT, TOP);
  text(title, x + 16, y + 14);
}

void drawGridBackground() {
  stroke(0, 40, 80, 40);
  strokeWeight(1);
  for (int x = 0; x < width; x += 55) line(x, 0, x, height);
  for (int y = 0; y < height; y += 55) line(0, y, width, y);
}

void drawRadarGrid() {
  pushMatrix();
  translate(originX, originY);
  noFill();
  stroke(0, 200, 100, 140);
  strokeWeight(1.4);

  for (int i = 1; i <= 4; i++) {
    arc(0, 0, (maxRadius * 2 / 4) * i, (maxRadius * 2 / 4) * i, PI, TWO_PI);
  }

  int[] spokes = {-90, -60, -30, 0, 30, 60, 90};
  for (int a : spokes) {
    float rad = radians(a - 90);
    line(0, 0, maxRadius * cos(rad), maxRadius * sin(rad));
  }
  popMatrix();
}

// -------------------------------------------------------------
// Live Serial Event Handler (Arduino angle,distance. parser)
// -------------------------------------------------------------
void serialEvent(Serial port) {
  try {
    data = port.readStringUntil('.');
    if (data != null) {
      data = data.substring(0, data.length() - 1);
      int commaIndex = data.indexOf(",");
      if (commaIndex > 0) {
        String angleStr = data.substring(0, commaIndex);
        String distStr = data.substring(commaIndex + 1);

        rawAngle = constrain(int(trim(angleStr)), 0, 180);
        iAngle = rawAngle - 90;
        iDistance = int(trim(distStr));

        // Buffer assignment at active sensor position
        int sampleIdx = rawAngle * 4;
        for (int k = max(0, sampleIdx - 2); k <= min(SAMPLES - 1, sampleIdx + 2); k++) {
          scanDistances[k] = iDistance;
          radarAlpha[k]    = 255;
          map3DAlpha[k]    = 255;
        }
      }
    }
  } catch (Exception e) {
    // Drop noisy or incomplete packets
  }
}