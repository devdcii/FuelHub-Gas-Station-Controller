#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <TM1637Display.h>

const char* ssid = "FuelHub Controller";        
const char* password = "12345678";       

IPAddress local_ip(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

WebServer server(80);

#define DISPLAY1_CLK 17
#define DISPLAY1_DIO 16     

#define DISPLAY2_CLK 17      
#define DISPLAY2_DIO 5    

#define DISPLAY3_CLK 17    
#define DISPLAY3_DIO 4    

TM1637Display display1(DISPLAY1_CLK, DISPLAY1_DIO);
TM1637Display display2(DISPLAY2_CLK, DISPLAY2_DIO);
TM1637Display display3(DISPLAY3_CLK, DISPLAY3_DIO);

float dieselPrice = 54.50;    // Display index 0 -> Display 1
float regularPrice = 56.75;   // Display index 1 -> Display 2  
float premiumPrice = 59.25;   // Display index 2 -> Display 3

bool wifiAPStarted = false;
unsigned long lastStatusCheck = 0;

void setup() {
  Serial.begin(115200);
  delay(2000);
 
  Serial.println("\n=== ESP32 Gas Station Controller Starting ===");
  Serial.println("Firmware Version: v2.3 - Fixed Display Mapping");
  
  Serial.println("\n🔍 DEBUG: Initial price values:");
  Serial.printf("   dieselPrice = %.2f (should go to Display 1)\n", dieselPrice);
  Serial.printf("   regularPrice = %.2f (should go to Display 2)\n", regularPrice);
  Serial.printf("   premiumPrice = %.2f (should go to Display 3)\n", premiumPrice);
 
  Serial.println("\nInitializing displays...");
  initializeDisplays();
 
  showStartupAnimation();
 
  setupWiFiAccessPoint();
 
  setupWebServer();
  
  if (wifiAPStarted) {
    Serial.println("\n🔍 DEBUG: About to call updateAllDisplays()");
    updateAllDisplays();
    Serial.println("=== Setup Complete - System Ready ===");
  } else {
    Serial.println("=== Setup Complete - AP Failed but System Running ===");
    showConnectionFailed();
  }
}

void loop() {
  server.handleClient();
 
  if (millis() - lastStatusCheck > 30000) {
    checkAccessPointStatus();
    lastStatusCheck = millis();
  }
 
  delay(10);
}

void initializeDisplays() {
  Serial.println("Setting up displays with unique pins...");
  Serial.printf("Display 1 (Diesel): CLK=%d, DIO=%d\n", DISPLAY1_CLK, DISPLAY1_DIO);
  Serial.printf("Display 2 (Regular): CLK=%d, DIO=%d\n", DISPLAY2_CLK, DISPLAY2_DIO);
  Serial.printf("Display 3 (Premium): CLK=%d, DIO=%d\n", DISPLAY3_CLK, DISPLAY3_DIO);
 
  // Initialize each display with maximum brightness and delays
  display1.setBrightness(0x0f);
  delay(200);
  display2.setBrightness(0x0f);
  delay(200);
  display3.setBrightness(0x0f);
  delay(200);
 
  display1.clear();
  display2.clear();
  display3.clear();
  delay(500);
 
  Serial.println("Testing Display 1 (Diesel)...");
  display1.showNumberDec(1111, false);
  delay(1500);
 
  Serial.println("Testing Display 2 (Regular)...");
  display2.showNumberDec(2222, false);
  delay(1500);
 
  Serial.println("Testing Display 3 (Premium)...");
  display3.showNumberDec(3333, false);
  delay(1500);
 
  display1.clear();
  display2.clear();
  display3.clear();
  delay(500);w
 
  Serial.println("✅ All displays initialized and tested successfully");
}

void showStartupAnimation() {
  Serial.println("Running startup animation...");
 
  for(int i = 0; i < 3; i++) {
    display1.showNumberDec(8888, false);
    display2.showNumberDec(8888, false);
    display3.showNumberDec(8888, false);
    delay(500);
    
    display1.clear();
    display2.clear();
    display3.clear();
    delay(300);
  }
 
  for(int i = 0; i < 4; i++) {
    uint8_t pattern[4] = {0, 0, 0, 0};
    for(int j = 0; j <= i; j++) {
      pattern[j] = SEG_G;
    }
    display1.setSegments(pattern);
    display2.setSegments(pattern);
    display3.setSegments(pattern);
    delay(500);
  }
 
  // Clear displays
  display1.clear();
  display2.clear();
  display3.clear();
  delay(500);
}

void setupWiFiAccessPoint() {
  Serial.println("\n=== WiFi Access Point Setup ===");
 
  WiFi.disconnect(true);
  WiFi.mode(WIFI_OFF);
  delay(1000);
  
  WiFi.mode(WIFI_AP);
  delay(1000);
  
  if (!WiFi.softAPConfig(local_ip, gateway, subnet)) {
    Serial.println("❌ Failed to configure Access Point IP");
    return;
  }
  
  Serial.printf("Creating Access Point: '%s'\n", ssid);
  Serial.printf("Password: '%s'\n", password);
  Serial.printf("AP IP: %s\n", local_ip.toString().c_str());
  
  if (WiFi.softAP(ssid, password)) {
    wifiAPStarted = true;
    
    delay(2000);
    
    Serial.println("✅ WiFi Access Point Started Successfully!");
    Serial.printf("AP SSID: %s\n", WiFi.softAPSSID().c_str());
    Serial.printf("AP IP Address: %s\n", WiFi.softAPIP().toString().c_str());
    Serial.printf("AP MAC Address: %s\n", WiFi.softAPmacAddress().c_str());
    
    showConnectionSuccess();
    
  } else {
    Serial.println("❌ Failed to start WiFi Access Point!");
    wifiAPStarted = false;
    printAPDiagnostics();
  }
}

void checkAccessPointStatus() {
  if (wifiAPStarted) {
    int connectedClients = WiFi.softAPgetStationNum();
    Serial.printf("📊 AP Status: %d clients connected\n", connectedClients);
    
    if (connectedClients > 0) {
      Serial.println("📱 Devices connected to Access Point");
    }
  } else {
    Serial.println("⚠️ Access Point is not running");
    setupWiFiAccessPoint();
  }
}

void printAPDiagnostics() {
  Serial.println("\n=== Access Point Diagnostics ===");
  Serial.printf("AP Started: %s\n", wifiAPStarted ? "Yes" : "No");
  Serial.printf("SSID: '%s'\n", ssid);
  Serial.printf("Password: '%s'\n", password);
  Serial.printf("Target IP: %s\n", local_ip.toString().c_str());
  Serial.printf("ESP32 MAC: %s\n", WiFi.macAddress().c_str());
}

void showConnectionSuccess() {
 
  uint8_t apon[] = {
    SEG_A | SEG_B | SEG_C | SEG_E | SEG_F | SEG_G,    // A
    SEG_A | SEG_B | SEG_E | SEG_F | SEG_G,            // P
    SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F,    // O
    SEG_C | SEG_E | SEG_G                             // n
  };
 
  display1.setSegments(apon);
  display2.setSegments(apon);  
  display3.setSegments(apon);
  delay(2000);
 
  display1.clear();
  display2.clear();
  display3.clear();
  delay(500);
}

void showConnectionFailed() {
  uint8_t fail[] = {
    SEG_A | SEG_E | SEG_F | SEG_G,                 // F
    SEG_A | SEG_B | SEG_C | SEG_E | SEG_F | SEG_G, // A
    SEG_E | SEG_F,                                 // I
    SEG_D | SEG_E | SEG_F                          // L
  };
 
  display1.setSegments(fail);
  display2.setSegments(fail);  
  display3.setSegments(fail);
  delay(3000);
  
  updateAllDisplays();
}

void setupWebServer() {
  server.enableCORS(true);
  
  server.on("/", handleRoot);
  server.on("/setPrice", HTTP_POST, handleSetPrice);
  server.on("/getAllPrices", HTTP_GET, handleGetAllPrices);
  server.on("/test", HTTP_GET, handleTest);
  server.on("/status", HTTP_GET, handleStatus);
 
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
      server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
      server.send(204);
    } else {
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.send(404, "text/plain", "404: Not Found");
    }
  });
 
  server.begin();
  Serial.println("✅ HTTP server started on port 80");
  if (wifiAPStarted) {
    Serial.printf("🌐 Access via: http://%s\n", WiFi.softAPIP().toString().c_str());
  }
}

void handleTest() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  StaticJsonDocument<200> doc;
  doc["status"] = "success";
  doc["message"] = "ESP32 Gas Station Controller is working!";
  doc["ap_started"] = wifiAPStarted;
  doc["ip"] = wifiAPStarted ? WiFi.softAPIP().toString() : "Not started";
  doc["clients"] = WiFi.softAPgetStationNum();
  doc["firmware"] = "v2.3-FIXED-MAPPING";
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleStatus() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  StaticJsonDocument<300> doc;
  doc["ap_started"] = wifiAPStarted;
  doc["ip"] = wifiAPStarted ? WiFi.softAPIP().toString() : "0.0.0.0";
  doc["ssid"] = ssid;
  doc["connected_clients"] = WiFi.softAPgetStationNum();
  doc["mac"] = WiFi.softAPmacAddress();
  doc["firmware"] = "v2.3-FIXED-MAPPING";
  doc["uptime"] = millis();
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleRoot() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
 
  String html = "<!DOCTYPE html><html><head>";
  html += "<title>Gas Station Controller v2.3 - Fixed Mapping</title>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "</head>";
  html += "<body style='font-family: Arial; margin: 20px; background: #1a1a1a; color: white;'>";
  html += "<h1>🛠️ ESP32 Gas Station Controller v2.3</h1>";
  html += "<h2>Fixed Display Mapping</h2>";
  
  html += "<h2>System Status</h2>";
  html += "<p>Access Point: <span style='color: " + String(wifiAPStarted ? "#4CAF50" : "#F44336") + "'>";
  html += wifiAPStarted ? "✅ Running" : "❌ Failed";
  html += "</span></p>";
  
  if (wifiAPStarted) {
    html += "<p>AP IP: <strong>" + WiFi.softAPIP().toString() + "</strong></p>";
    html += "<p>SSID: <strong>" + String(ssid) + "</strong></p>";
    html += "<p>Connected Devices: <strong>" + String(WiFi.softAPgetStationNum()) + "</strong></p>";
  }
  
  html += "<p>Uptime: <strong>" + String(millis() / 1000) + " seconds</strong></p>";
 
  html += "<h2>Current Prices (FIXED: Index matches Physical Display)</h2>";
  html += "<div style='display: flex; gap: 20px; flex-wrap: wrap;'>";
 
  html += "<div style='border: 2px solid #607D8B; padding: 15px; border-radius: 10px; min-width: 150px;'>";
  html += "<h3>🚛 DIESEL (Index 0 → Display 1)</h3>";
  html += "<p style='font-size: 24px; margin: 10px 0;'>₱" + String(dieselPrice, 2) + "</p>";
  html += "</div>";

  html += "<div style='border: 2px solid #4CAF50; padding: 15px; border-radius: 10px; min-width: 150px;'>";
  html += "<h3>⛽ REGULAR (Index 1 → Display 2)</h3>";
  html += "<p style='font-size: 24px; margin: 10px 0;'>₱" + String(regularPrice, 2) + "</p>";
  html += "</div>";
 
  html += "<div style='border: 2px solid #FF5722; padding: 15px; border-radius: 10px; min-width: 150px;'>";
  html += "<h3>🔥 PREMIUM (Index 2 → Display 3)</h3>";
  html += "<p style='font-size: 24px; margin: 10px 0;'>₱" + String(premiumPrice, 2) + "</p>";
  html += "</div>";
 
  html += "</div>";
  
  html += "<h2>Display Pin Configuration</h2>";
  html += "<p>Display 1 (Diesel): CLK=" + String(DISPLAY1_CLK) + ", DIO=" + String(DISPLAY1_DIO) + "</p>";
  html += "<p>Display 2 (Regular): CLK=" + String(DISPLAY2_CLK) + ", DIO=" + String(DISPLAY2_DIO) + "</p>";
  html += "<p>Display 3 (Premium): CLK=" + String(DISPLAY3_CLK) + ", DIO=" + String(DISPLAY3_DIO) + "</p>";

  html += "</body></html>";
 
  server.send(200, "text/html", html);
}

void handleSetPrice() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
 
  if (server.method() == HTTP_OPTIONS) {
    server.send(204);
    return;
  }
 
  Serial.println("=== Received Price Update Request ===");
  
  if (!server.hasArg("display") || !server.hasArg("price")) {
    Serial.println("❌ Missing parameters");
    server.send(400, "application/json", 
                "{\"status\":\"error\",\"message\":\"Missing required parameters: display and price\"}");
    return;
  }
 
  int displayIndex = server.arg("display").toInt();
  float newPrice = server.arg("price").toFloat();
 
  Serial.printf("Request: Display=%d, Price=%.2f\n", displayIndex, newPrice);
 
  if (displayIndex < 0 || displayIndex > 2) {
    Serial.println("❌ Invalid display index");
    server.send(400, "application/json", 
                "{\"status\":\"error\",\"message\":\"Display index must be 0, 1, or 2\"}");
    return;
  }
 
  if (newPrice <= 0 || newPrice > 99.99) {
    Serial.printf("❌ Invalid price range: %.2f\n", newPrice);
    server.send(400, "application/json", 
                "{\"status\":\"error\",\"message\":\"Price must be between 0.01 and 99.99\"}");
    return;
  }
 
  switch (displayIndex) {
    case 0:
      dieselPrice = newPrice;  // Index 0 → Display 1 (Diesel)
      Serial.printf("✅ Diesel price updated: ₱%.2f → Display 1\n", dieselPrice);
      break;
    case 1:
      regularPrice = newPrice; // Index 1 → Display 2 (Regular)
      Serial.printf("✅ Regular price updated: ₱%.2f → Display 2\n", regularPrice);
      break;
    case 2:
      premiumPrice = newPrice; // Index 2 → Display 3 (Premium)
      Serial.printf("✅ Premium price updated: ₱%.2f → Display 3\n", premiumPrice);
      break;
  }
 
  bool displaySuccess = displayPrice(displayIndex, newPrice);
 
  StaticJsonDocument<300> doc;
  doc["status"] = displaySuccess ? "success" : "warning";
  doc["display"] = displayIndex;
  doc["price"] = newPrice;
  doc["fuel_type"] = getFuelTypeName(displayIndex);
  doc["message"] = displaySuccess ? "Price updated successfully" : "Price saved but display update failed";
  doc["ip"] = WiFi.softAPIP().toString();
  
  String response;
  serializeJson(doc, response);
  
  Serial.println("✅ Response: " + response);
  server.send(200, "application/json", response);
}

void handleGetAllPrices() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
 
  StaticJsonDocument<400> doc;
  doc["diesel"] = dieselPrice;    // Index 0 → Display 1
  doc["regular"] = regularPrice;  // Index 1 → Display 2
  doc["premium"] = premiumPrice;  // Index 2 → Display 3
  doc["status"] = "online";
  doc["ap_started"] = wifiAPStarted;
  doc["firmware"] = "v2.3-FIXED-MAPPING";
  doc["ip"] = WiFi.softAPIP().toString();
  doc["network"] = String(ssid);
  doc["connected_clients"] = WiFi.softAPgetStationNum();
  doc["uptime"] = millis();
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
 
  Serial.println("📊 All prices requested - Response sent");
}

String getFuelTypeName(int displayIndex) {
  switch(displayIndex) {
    case 0: return "Diesel";   // Index 0 → Display 1
    case 1: return "Regular";  // Index 1 → Display 2
    case 2: return "Premium";  // Index 2 → Display 3
    default: return "Unknown";
  }
}

void updateAllDisplays() {
  Serial.println("📺 Updating all displays...");
 
  bool success1 = displayPrice(0, dieselPrice);  // Index 0 → Display 1 (Diesel)
  delay(100);
  bool success2 = displayPrice(1, regularPrice); // Index 1 → Display 2 (Regular)
  delay(100);
  bool success3 = displayPrice(2, premiumPrice); // Index 2 → Display 3 (Premium)
 
  Serial.println("📺 Display update results:");
  Serial.printf("   Display 1 (Diesel):  %s - ₱%.2f\n", success1 ? "✅" : "❌", dieselPrice);
  Serial.printf("   Display 2 (Regular): %s - ₱%.2f\n", success2 ? "✅" : "❌", regularPrice);
  Serial.printf("   Display 3 (Premium): %s - ₱%.2f\n", success3 ? "✅" : "❌", premiumPrice);
}

bool displayPrice(int displayIndex, float price) {
  if (displayIndex < 0 || displayIndex > 2) {
    Serial.printf("❌ Invalid display index: %d\n", displayIndex);
    return false;
  }
  
  if (price < 0 || price > 99.99) {
    Serial.printf("❌ Price out of range: %.2f (must be 0.00-99.99)\n", price);
    return false;
  }
 
  TM1637Display* currentDisplay;
  String displayName;
 
  switch (displayIndex) {
    case 0:
      currentDisplay = &display1;  // Index 0 → Display 1 (Diesel)
      displayName = "Display 1 (Diesel)";
      break;
    case 1:
      currentDisplay = &display2;  // Index 1 → Display 2 (Regular)
      displayName = "Display 2 (Regular)";
      break;
    case 2:
      currentDisplay = &display3;  // Index 2 → Display 3 (Premium)
      displayName = "Display 3 (Premium)";
      break;
    default:
      return false;
  }
 
  try {
    int displayValue = (int)(price * 100 + 0.5); // +0.5 for rounding
    
    currentDisplay->showNumberDecEx(displayValue, 0b01000000, true, 4, 0);
    
    Serial.printf("📺 %s: ₱%.2f -> %d (with decimal point)\n", 
                  displayName.c_str(), price, displayValue);
    
    return true;
    
  } catch (...) {
    Serial.printf("❌ Failed to update %s\n", displayName.c_str());
    return false;
  }
}

void clearAllDisplays() {
  Serial.println("📺 Clearing all displays...");
  
  display1.clear();
  delay(50);
  display2.clear();
  delay(50);
  display3.clear();
  delay(50);
  
  Serial.println("📺 All displays cleared");
}