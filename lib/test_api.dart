import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_driver/network/NetworkUtils.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

class ApiTest extends StatefulWidget {
  @override
  _ApiTestState createState() => _ApiTestState();
}

class _ApiTestState extends State<ApiTest> {
  String result = "No results yet";
  bool isLoading = false;

  Future<void> testServiceListApi() async {
    setState(() {
      isLoading = true;
      result = "Loading service list API...";
    });

    try {
      final response =
          await buildHttpResponse('service-list', method: HttpMethod.GET);

      setState(() {
        result = "Status code: ${response.statusCode}\n\n";

        if (response.statusCode == 200) {
          // Pretty print the JSON response
          var jsonResponse = jsonDecode(response.body);
          result +=
              "Response: ${JsonEncoder.withIndent('  ').convert(jsonResponse)}";
        } else {
          result += "Response: ${response.body}";
        }
      });
    } catch (e) {
      setState(() {
        result = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> testSimpleUrl() async {
    setState(() {
      isLoading = true;
      result = "Testing direct HTTP access...";
    });

    try {
      // Use the same headers as our build function
      var headers = buildHeaderTokens();

      final response = await http
          .get(
            Uri.parse('$DOMAIN_URL/api/service-list'),
            headers: headers,
          )
          .timeout(Duration(seconds: 30));

      setState(() {
        result = "Status code: ${response.statusCode}\n\n";
        result +=
            "Headers used: ${JsonEncoder.withIndent('  ').convert(headers)}\n\n";

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          result +=
              "Response: ${JsonEncoder.withIndent('  ').convert(jsonResponse)}";
        } else {
          result += "Response: ${response.body}";
        }
      });
    } catch (e) {
      setState(() {
        result = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> testSignupEndpoint() async {
    setState(() {
      isLoading = true;
      result = "Testing signup endpoint...";
    });

    try {
      // Test data for signup - modified to include more realistic values
      final testData = {
        "first_name": "Test",
        "last_name": "User",
        "username": "testuser${DateTime.now().millisecondsSinceEpoch}",
        "email": "test${DateTime.now().millisecondsSinceEpoch}@masark-sa.com",
        "user_type": "driver",
        "contact_number":
            "1231232${DateTime.now().millisecondsSinceEpoch % 1000}",
        "country_code": "+966",
        "password": "Test123456",
        "player_id": "",
        "user_detail": {
          "car_model": "Toyota",
          "car_color": "White",
          "car_plate_number": "ABC123",
          "car_production_year": "2022"
        },
        "service_id": 2
      };

      final response = await buildHttpResponse(
        'driver-register',
        method: HttpMethod.POST,
        request: testData,
      );

      setState(() {
        result = "Status code: ${response.statusCode}\n\n";
        result +=
            "Request: ${JsonEncoder.withIndent('  ').convert(testData)}\n\n";

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          result +=
              "Response: ${JsonEncoder.withIndent('  ').convert(jsonResponse)}";
        } else {
          result += "Response: ${response.body}";
        }
      });
    } catch (e) {
      setState(() {
        result = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkDomainAccess() async {
    setState(() {
      isLoading = true;
      result = "Checking direct domain access...";
    });

    try {
      // Try to access the domain directly with a more basic request
      final response = await http.get(
        Uri.parse(DOMAIN_URL),
        headers: {
          'User-Agent': 'MightyTaxiRiderApp',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
        },
      ).timeout(Duration(seconds: 20));

      setState(() {
        result = "Domain access status: ${response.statusCode}\n\n";
        if (response.statusCode >= 200 && response.statusCode < 300) {
          result += "Success! Domain is accessible.\n\n";
          // Show first 500 chars of the response to see if it's HTML
          result +=
              "Response (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}";
        } else {
          result += "Error accessing domain directly: ${response.body}";
        }
      });
    } catch (e) {
      setState(() {
        result = "Error accessing domain: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("API Testing"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : testServiceListApi,
                  child: Text("Test Service List"),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : testSimpleUrl,
                  child: Text("Test HTTP Direct"),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : testSignupEndpoint,
                  child: Text("Test Signup API"),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : checkDomainAccess,
                  child: Text("Check Domain"),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                        result =
                            "Testing direct API connection with MightyTaxiRiderApp User-Agent...";
                      });

                      try {
                        final response = await http.get(
                          Uri.parse('$DOMAIN_URL/api/service-list'),
                          headers: {
                            'User-Agent': 'MightyTaxiRiderApp',
                            'Content-Type': 'application/json',
                            'Accept': 'application/json',
                          },
                        ).timeout(Duration(seconds: 30));

                        setState(() {
                          result =
                              "Direct API Test Result (MightyTaxiRiderApp):\n";
                          result += "Status code: ${response.statusCode}\n\n";

                          if (response.statusCode == 200) {
                            try {
                              var jsonResponse = jsonDecode(response.body);
                              result +=
                                  "Response: ${JsonEncoder.withIndent('  ').convert(jsonResponse)}";
                            } catch (e) {
                              result += "Response: ${response.body}";
                            }
                          } else {
                            result += "Error: ${response.body}";
                          }
                        });
                      } catch (e) {
                        setState(() {
                          result = "Error: ${e.toString()}";
                        });
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text("Test MightyTaxiRiderApp Agent",
                  style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Text(result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
