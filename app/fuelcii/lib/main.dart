import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(GasStationApp());
}

class GasStationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'FuelHub Gas Station',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.white,
        scaffoldBackgroundColor: CupertinoColors.black,
        barBackgroundColor: CupertinoColors.black,
      ),
      home: PriceControlScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditableFuelDisplay extends StatefulWidget {
  final String fuelType;
  final String subtitle;
  final double currentPrice;
  final Color color;
  final IconData icon;
  final Function(double) onPriceUpdate;
  final bool isLoading;

  const EditableFuelDisplay({
    Key? key,
    required this.fuelType,
    required this.subtitle,
    required this.currentPrice,
    required this.color,
    required this.icon,
    required this.onPriceUpdate,
    required this.isLoading,
  }) : super(key: key);

  @override
  _EditableFuelDisplayState createState() => _EditableFuelDisplayState();
}

class _EditableFuelDisplayState extends State<EditableFuelDisplay> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPrice.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(EditableFuelDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.currentPrice != oldWidget.currentPrice) {
      _controller.text = widget.currentPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _savePrice() {
    double? newPrice = double.tryParse(_controller.text);
    // FIXED: Enhanced validation with 99.99 limit
    if (newPrice != null && newPrice > 0 && newPrice <= 99.99) {
      widget.onPriceUpdate(newPrice);
      setState(() {
        _isEditing = false;
      });
    } else {
      // Show error for invalid price
      String errorMessage;
      if (newPrice == null || newPrice <= 0) {
        errorMessage = "Please enter a valid price greater than 0.00";
      } else if (newPrice > 99.99) {
        errorMessage = "Price cannot exceed ₱99.99. Please enter a lower amount.";
      } else {
        errorMessage = "Invalid price format";
      }

      _showInvalidPriceAlert(errorMessage);
      _controller.text = widget.currentPrice.toStringAsFixed(2);
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _showInvalidPriceAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed),
              SizedBox(width: 8),
              Text("Invalid Price", style: TextStyle(color: CupertinoColors.white)),
            ],
          ),
          content: Text(message, style: TextStyle(color: CupertinoColors.white)),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _cancelEdit() {
    _controller.text = widget.currentPrice.toStringAsFixed(2);
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.darkColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey4.darkColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            // Icon Section
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 22,
              ),
            ),

            SizedBox(width: 10),

            // Fuel Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.fuelType,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.white,
                      letterSpacing: 1.0,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.fuelType == "DIESEL"
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Price Section - FIXED FOR OVERFLOW
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 120,
                  maxWidth: 180,
                ),
                child: !_isEditing ?
                GestureDetector(
                  onTap: _startEditing,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.systemGrey3,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "₱ ${widget.currentPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: CupertinoColors.black,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.square_pencil,
                          color: CupertinoColors.black,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ) :
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CupertinoColors.systemGrey4, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 32,
                        child: CupertinoTextField(
                          controller: _controller,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.black,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          prefix: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text("₱", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _savePrice(),
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              color: CupertinoColors.activeGreen,
                              borderRadius: BorderRadius.circular(4),
                              minSize: 20,
                              onPressed: widget.isLoading ? null : _savePrice,
                              child: widget.isLoading
                                  ? CupertinoActivityIndicator(color: CupertinoColors.white, radius: 6)
                                  : Icon(CupertinoIcons.checkmark, color: CupertinoColors.white, size: 12),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              color: CupertinoColors.systemGrey,
                              borderRadius: BorderRadius.circular(4),
                              minSize: 20,
                              onPressed: _cancelEdit,
                              child: Icon(CupertinoIcons.xmark, color: CupertinoColors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriceControlScreen extends StatefulWidget {
  @override
  _PriceControlScreenState createState() => _PriceControlScreenState();
}

class _PriceControlScreenState extends State<PriceControlScreen> {
  // FIXED: Price variables correctly aligned with ESP32 indices
  double dieselPrice = 54.50;    // Index 0 → Display 1
  double regularPrice = 56.75;   // Index 1 → Display 2
  double premiumPrice = 59.25;   // Index 2 → Display 3

  String esp32IP = "192.168.4.1";
  bool isConnected = false;
  bool isLoading = false;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _startAutoConnection();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }

  void _startAutoConnection() {
    _connectionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!isConnected) {
        _checkConnection();
      }
    });
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32IP/getAllPrices'),
      ).timeout(Duration(seconds: 2));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          // FIXED: Correct mapping from JSON response
          dieselPrice = jsonResponse['diesel'].toDouble();    // Index 0
          regularPrice = jsonResponse['regular'].toDouble();  // Index 1
          premiumPrice = jsonResponse['premium'].toDouble();  // Index 2
          isConnected = true;
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }
  }

  Future<void> updatePrice(int displayIndex, double newPrice) async {
    setState(() {
      isLoading = true;
    });

    // FIXED: Enhanced validation with 99.99 limit
    if (newPrice > 99.99) {
      setState(() {
        isLoading = false;
      });
      _showErrorAlert("Price cannot exceed ₱99.99. Please enter a lower amount.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$esp32IP/setPrice'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'display=$displayIndex&price=${newPrice.toStringAsFixed(2)}',
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            // FIXED: Correct price assignment matching ESP32 indices
            switch (displayIndex) {
              case 0:
                dieselPrice = newPrice;    // Index 0 → Display 1 (Diesel)
                break;
              case 1:
                regularPrice = newPrice;   // Index 1 → Display 2 (Regular)
                break;
              case 2:
                premiumPrice = newPrice;   // Index 2 → Display 3 (Premium)
                break;
            }
            isConnected = true;
          });
          HapticFeedback.lightImpact();
          String fuelType = ['Diesel', 'Regular', 'Premium'][displayIndex];
          _showSuccessAlert("$fuelType price updated to ₱${newPrice.toStringAsFixed(2)}");
        } else {
          _showErrorAlert(jsonResponse['message'] ?? "Unknown error");
        }
      } else {
        _showErrorAlert("Failed to update price. Check ESP32 connection.");
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
      _showErrorAlert("Cannot reach ESP32 device");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.systemGreen),
              SizedBox(width: 8),
              Text("Success!", style: TextStyle(color: CupertinoColors.white)),
            ],
          ),
          content: Text(message, style: TextStyle(color: CupertinoColors.white)),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showErrorAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed),
              SizedBox(width: 8),
              Text("Error", style: TextStyle(color: CupertinoColors.white)),
            ],
          ),
          content: Text(message, style: TextStyle(color: CupertinoColors.white)),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            "About",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
          content: Padding(
            padding: EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Text(
                  "Developer:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text("Canlas, Adrian S.", style: TextStyle(fontSize: 14, color: CupertinoColors.white)),
                Text("Digman, Christian D.", style: TextStyle(fontSize: 14, color: CupertinoColors.white)),
                Text("Paragas, John Ian Joseph M.", style: TextStyle(fontSize: 14, color: CupertinoColors.white)),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAboutDialog,
          child: Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.white,
            size: 20,
          ),
        ),
        middle: Text(
          'FUELHUB',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      child: Container(
        width: screenWidth,
        height: screenHeight,
        color: CupertinoColors.black,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Connection Status
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.darkColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isConnected ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isConnected ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isConnected ? "ESP32 CONNECTED" : "CONNECTING...",
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (!isConnected)
                        CupertinoActivityIndicator(color: CupertinoColors.white, radius: 8),
                      SizedBox(width: 8),
                    ],
                  ),
                ),

                SizedBox(height: 15),

                // Title
                Text(
                  "PRICES",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: CupertinoColors.white,
                    letterSpacing: 2,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // FIXED: Fuel Cards - Correct index mapping
                Expanded(
                  child: Column(
                    children: [
                      // DIESEL - Index 0 → Display 1
                      Expanded(
                        child: EditableFuelDisplay(
                          fuelType: "DIESEL",
                          subtitle: "Automotive Diesel",
                          currentPrice: dieselPrice,
                          color: CupertinoColors.systemGrey,
                          icon: Icons.local_gas_station,
                          onPriceUpdate: (price) => updatePrice(0, price), // Index 0 → Display 1
                          isLoading: isLoading,
                        ),
                      ),

                      SizedBox(height: 8),

                      // UNLEADED - Index 1 → Display 2
                      Expanded(
                        child: EditableFuelDisplay(
                          fuelType: "UNLEADED",
                          subtitle: "Regular Gasoline",
                          currentPrice: regularPrice,
                          color: CupertinoColors.systemGreen,
                          icon: CupertinoIcons.drop_fill,
                          onPriceUpdate: (price) => updatePrice(1, price), // Index 1 → Display 2
                          isLoading: isLoading,
                        ),
                      ),

                      SizedBox(height: 8),

                      // PREMIUM - Index 2 → Display 3
                      Expanded(
                        child: EditableFuelDisplay(
                          fuelType: "PREMIUM",
                          subtitle: "High Octane",
                          currentPrice: premiumPrice,
                          color: CupertinoColors.systemRed,
                          icon: CupertinoIcons.flame_fill,
                          onPriceUpdate: (price) => updatePrice(2, price), // Index 2 → Display 3
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}