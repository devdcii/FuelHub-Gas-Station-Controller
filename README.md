# FuelHub Gas Station Controller
### IoT-Based Gas Station Price Display System

> A Flutter mobile app that controls an ESP32-powered gas station price board — update Diesel, Unleaded, and Premium fuel prices in real time over direct WiFi, instantly reflected on 3 TM1637 7-segment LED displays.

---

## Overview

FuelHub is an IoT price management system designed for gas stations. The Flutter app connects directly to an ESP32 Access Point over WiFi — no router required. Station attendants can tap any fuel price card, enter a new price, and the update is sent instantly to the ESP32, which displays the new price on the corresponding physical 7-segment LED display board. Prices are validated both on the app and on the ESP32 firmware side.

---

## Features

- **3 Fuel Price Controls** — Diesel, Unleaded (Regular), and Premium with individual price cards
- **Inline Price Editing** — Tap any price to edit, confirm with ✓ or cancel with ✗
- **Real-Time Sync** — Auto-connects to ESP32 every 3 seconds and fetches live prices
- **3 TM1637 Displays** — Each display shows one fuel type price with decimal point
- **Price Validation** — Range check (₱0.01 – ₱99.99) on both app and firmware
- **Connection Status** — Live indicator showing ESP32 connected/connecting state
- **Startup Animation** — Display self-test sequence (1111 → 2222 → 3333 → 8888 flash)
- **Web Control Panel** — Browser-accessible price panel at `http://192.168.4.1`
- **AP Status Monitor** — Logs connected client count every 30 seconds via Serial

---

## App Navigation Flow

```
App Launch
    │
    ▼
PriceControlScreen
    ├── Auto-connect Timer (every 3 seconds)
    │       ├── GET http://192.168.4.1/getAllPrices
    │       ├── ❌ Timeout/Error → Show "CONNECTING..." status (red indicator)
    │       └── ✅ Connected → Load diesel, regular, premium prices (green indicator)
    │
    ├── [ℹ Info Button] → About Dialog (developer names)
    │
    ├── [DIESEL Card] → Tap price to edit
    │       ├── Enter new price (₱0.01 – ₱99.99)
    │       ├── Tap ✓ → POST /setPrice (display=0, price=XX.XX)
    │       │       ├── ❌ Error → Show error dialog
    │       │       └── ✅ Success → Update diesel price + Show success dialog
    │       └── Tap ✗ → Cancel, restore old price
    │
    ├── [UNLEADED Card] → Tap price to edit
    │       ├── Enter new price (₱0.01 – ₱99.99)
    │       ├── Tap ✓ → POST /setPrice (display=1, price=XX.XX)
    │       │       ├── ❌ Error → Show error dialog
    │       │       └── ✅ Success → Update regular price + Show success dialog
    │       └── Tap ✗ → Cancel, restore old price
    │
    └── [PREMIUM Card] → Tap price to edit
            ├── Enter new price (₱0.01 – ₱99.99)
            ├── Tap ✓ → POST /setPrice (display=2, price=XX.XX)
            │       ├── ❌ Error → Show error dialog
            │       └── ✅ Success → Update premium price + Show success dialog
            └── Tap ✗ → Cancel, restore old price
```

---

## Hardware

### Components

| Component | Model | Quantity | Purpose |
|---|---|---|---|
| Microcontroller | ESP32 Dev Module | 1 | WiFi AP + HTTP server + display control |
| 7-Segment Display | TM1637 (4-digit) | 3 | Show Diesel, Regular, Premium prices |
| Power Supply | 5V USB / Power Bank | 1 | Powers ESP32 and displays |
| Jumper Wires | Male-to-Male/Female | — | Connections |
| Breadboard | Standard | 1 | Prototyping |

### Wiring — ESP32 to TM1637 Displays

> **Note:** All 3 displays share the same CLK pin (GPIO 17). Each display has its own unique DIO pin for individual control.

| Display | Fuel Type | CLK Pin | DIO Pin | GPIO (CLK) | GPIO (DIO) |
|---|---|---|---|---|---|
| Display 1 | Diesel | GPIO 17 | GPIO 16 | D17 | D16 |
| Display 2 | Regular/Unleaded | GPIO 17 | GPIO 5 | D17 | D5 |
| Display 3 | Premium | GPIO 17 | GPIO 4 | D17 | D4 |

**TM1637 Pin Labels:**
| TM1637 Pin | Connect To |
|---|---|
| CLK | ESP32 GPIO 17 (shared) |
| DIO | ESP32 GPIO (unique per display) |
| VCC | 3.3V or 5V |
| GND | GND |

### Display Index Mapping

| Index | Variable | Display | Fuel Type |
|---|---|---|---|
| 0 | `dieselPrice` | Display 1 | Diesel |
| 1 | `regularPrice` | Display 2 | Regular / Unleaded |
| 2 | `premiumPrice` | Display 3 | Premium |

### ESP32 WiFi Setup

| Setting | Value |
|---|---|
| SSID | FuelHub Controller |
| Password | 12345678 |
| ESP32 IP | 192.168.4.1 |
| Mode | Access Point (no router needed) |
| AP Status Check | Every 30 seconds |

### ESP32 HTTP API

Base URL: `http://192.168.4.1`

| Endpoint | Method | Params | Description |
|---|---|---|---|
| `/` | GET | — | Web-based price control panel (HTML) |
| `/test` | GET | — | Health check + firmware version |
| `/status` | GET | — | AP status, connected clients, uptime, MAC |
| `/getAllPrices` | GET | — | Returns diesel, regular, premium prices as JSON |
| `/setPrice` | POST | `display`, `price` | Update one fuel price and refresh display |

### API Examples

**Get All Prices** — `GET /getAllPrices`
```json
{
  "diesel": 54.50,
  "regular": 56.75,
  "premium": 59.25,
  "status": "online",
  "firmware": "v2.3-FIXED-MAPPING",
  "ip": "192.168.4.1",
  "network": "FuelHub Controller",
  "connected_clients": 1,
  "uptime": 45231
}
```

**Set Price** — `POST /setPrice`
```
Body (form-encoded):
display=0&price=54.75
```
```json
{
  "status": "success",
  "display": 0,
  "price": 54.75,
  "fuel_type": "Diesel",
  "message": "Price updated successfully",
  "ip": "192.168.4.1"
}
```

### Price Display Format

Prices are shown on TM1637 using `showNumberDecEx` with the decimal point between digits 2 and 3:

```
₱54.50  →  displayed as  5 4 . 5 0
```

Price range enforced: `₱0.01` to `₱99.99`

### Startup Sequence

1. Serial monitor begins at 115200 baud
2. All 3 displays initialized and tested (shows `1111` → `2222` → `3333`)
3. Startup animation (flash `8888` x3, then scrolling segment animation)
4. WiFi Access Point starts
5. Displays show `APOn` on success or `FAIL` on error
6. All 3 displays updated with current default prices
7. HTTP server starts on port 80

### Arduino IDE Setup

1. Install **Arduino IDE** and add ESP32 board support
   - Board Manager URL: `https://dl.espressif.com/dl/package_esp32_index.json`
2. Install required libraries via Library Manager:
   - `ArduinoJson` by Benoit Blanchon
   - `TM1637Display` by Avishay Orpaz
3. Open `firmware/fuelhub/fuelhub.ino`
4. Select board: **ESP32 Dev Module**
5. Upload to ESP32
6. Open Serial Monitor at **115200 baud** to verify startup

---

## Project Structure

```
fuelhub-gas-station/
├── app/                              # Flutter Mobile App
│   ├── lib/
│   │   └── main.dart                 # Full app (PriceControlScreen, EditableFuelDisplay)
│   └── pubspec.yaml
│
└── firmware/                         # ESP32 Arduino Code
    └── fuelhub/
        └── fuelhub.ino               # Main firmware file
```

---

## Mobile App Setup

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio or VS Code with Flutter extensions

### Installation

```bash
cd app
flutter pub get
flutter run
```

### Connecting to the ESP32

1. Power on the ESP32
2. Wait for Serial Monitor to show `=== Setup Complete ===`
3. On your phone, connect to WiFi: **FuelHub Controller** (password: `12345678`)
4. Open the app — it auto-connects every 3 seconds
5. Green dot = connected, Red dot = connecting/offline

---

## App UI Reference (Dark Mode)

| Section | Description |
|---|---|
| Navigation Bar | "FUELHUB" title + ℹ info button |
| Connection Status | Green/Red dot + "ESP32 CONNECTED" or "CONNECTING..." |
| DIESEL Card | Grey icon, inline price editor, sends to display index 0 |
| UNLEADED Card | Green icon, inline price editor, sends to display index 1 |
| PREMIUM Card | Red icon, inline price editor, sends to display index 2 |

---

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

---

## Roadmap

- [ ] Persistent price storage on ESP32 (EEPROM/NVMe) — prices survive power loss
- [ ] Historical price change log
- [ ] Support for more than 3 fuel types
- [ ] PIN code lock for price editing
- [ ] Larger display support (6-digit or LCD)
- [ ] Auto-brightness based on time of day
