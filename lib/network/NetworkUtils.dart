import 'dart:convert';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../main.dart';
import '../utils/Extensions/extension.dart';
import '../utils/utils.dart';
import 'RestApis.dart';

Map<String, String> buildHeaderTokens() {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.acceptHeader: 'application/json; charset=utf-8',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Origin': '*',
    HttpHeaders.userAgentHeader: 'MightyTaxiRiderApp',
    'X-Requested-With': 'XMLHttpRequest',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Dest': 'empty',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
    'Referer': DOMAIN_URL,
    'Origin': DOMAIN_URL,
  };
  if (appStore.isLoggedIn) {
    header.putIfAbsent(HttpHeaders.authorizationHeader,
        () => 'Bearer ${sharedPref.getString(TOKEN)}');
  }
  log(jsonEncode(header));
  return header;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http')) url = Uri.parse('$mBaseUrl$endPoint');
  log('URL: ${url.toString()}');
  return url;
}

Future<Response> buildHttpResponse(String endPoint,
    {HttpMethod method = HttpMethod.GET,
    Map? request,
    Map<String, String>? header_extra}) async {
  if (await isNetworkAvailable()) {
    var headers = header_extra ?? buildHeaderTokens();
    Uri url = buildBaseUrl(endPoint);

    // Create a client that can keep cookies
    final client = http.Client();

    // Add retry mechanism
    int maxRetries = 2;
    int currentRetry = 0;

    while (currentRetry <= maxRetries) {
      try {
        Response response;
        // Increase timeout duration to 45 seconds
        Duration timeoutDuration = Duration(seconds: 45);

        if (method == HttpMethod.POST) {
          response = await client
              .post(url, body: jsonEncode(request), headers: headers)
              .timeout(timeoutDuration, onTimeout: () {
            log("Request timed out: $url (retry $currentRetry/$maxRetries)");
            throw 'Connection timed out. Please check your internet connection and try again.';
          });
        } else if (method == HttpMethod.DELETE) {
          response = await client
              .delete(url, headers: headers)
              .timeout(timeoutDuration, onTimeout: () {
            log("Request timed out: $url (retry $currentRetry/$maxRetries)");
            throw 'Connection timed out. Please check your internet connection and try again.';
          });
        } else if (method == HttpMethod.PUT) {
          response = await client
              .put(url, body: jsonEncode(request), headers: headers)
              .timeout(timeoutDuration, onTimeout: () {
            log("Request timed out: $url (retry $currentRetry/$maxRetries)");
            throw 'Connection timed out. Please check your internet connection and try again.';
          });
        } else {
          response = await client
              .get(url, headers: headers)
              .timeout(timeoutDuration, onTimeout: () {
            log("Request timed out: $url (retry $currentRetry/$maxRetries)");
            throw 'Connection timed out. Please check your internet connection and try again.';
          });
        }

        // Close the client
        client.close();

        apiURLResponseLog(
          url: url.toString(),
          endPoint: endPoint,
          headers: jsonEncode(headers),
          hasRequest: method == HttpMethod.POST || method == HttpMethod.PUT,
          request: jsonEncode(request),
          statusCode: response.statusCode.validate(),
          responseBody: response.body,
          methodType: method.name,
        );

        // Success! Return the response
        return response;
      } catch (e, s) {
        currentRetry++;

        if (currentRetry > maxRetries) {
          log("API Error after $maxRetries retries: ${e.toString()}");
          FirebaseCrashlytics.instance.recordError(
              "API_ERROR->${url.toString()}::" + e.toString(), s,
              fatal: true);

          // More user-friendly error message
          if (e.toString().contains('timed out'))
            throw 'Connection timed out. Please check your internet connection and try again.';
          else if (e.toString().contains('SocketException') ||
              e.toString().contains('Connection refused'))
            throw 'Unable to connect to server. Please check your internet connection.';
          else
            throw 'Something went wrong. Please try again later.';
        } else {
          // Wait a moment before retrying
          log("Retrying request ($currentRetry/$maxRetries): $url");
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }

    // This line should never be reached due to the throw in the catch block
    throw 'Unable to complete request after multiple attempts';
  } else {
    throw 'No internet connection. Please check your network settings.';
  }
}

JsonDecoder decoder = JsonDecoder();
JsonEncoder encoder = JsonEncoder.withIndent('  ');

void prettyPrintJson(String input) {
  var object = decoder.convert(input);
  var prettyString = encoder.convert(object);
  prettyString.split('\n').forEach((element) => debugPrint(element));
}

void apiURLResponseLog(
    {String url = "",
    String endPoint = "",
    String headers = "",
    String request = "",
    int statusCode = 0,
    dynamic responseBody = "",
    String methodType = "",
    bool hasRequest = false}) {
  if (kReleaseMode) return;
  debugPrint(
      "\u001B[39m \u001b[96m┌───────────────────────────────────────────────────────────────────────────────────────────────────────┐\u001B[39m");
  log("\u001B[39m \u001b[96m Time: ${DateTime.now()}\u001B[39m");
  debugPrint("\u001b[31m Url: \u001B[39m $url");
  debugPrint("\u001b[31m Header: \u001B[39m \u001b[96m$headers\u001B[39m");
  if (request.isNotEmpty)
    log("\u001b[31m Request: \u001B[39m \u001b[96m$request\u001B[39m");
  debugPrint("${statusCode.isSuccessful() ? "\u001b[32m" : "\u001b[31m"}");
  debugPrint(
      'Response ($methodType) $statusCode ${statusCode.isSuccessful() ? "\u001b[32m" : "\u001b[31m"} ');
  prettyPrintJson(responseBody);
  debugPrint("\u001B[0m");
  debugPrint(
      "\u001B[39m \u001b[96m└───────────────────────────────────────────────────────────────────────────────────────────────────────┘\u001B[39m");
}

//region Common
Future handleResponse(Response response, [bool? avoidTokenError]) async {
  if (!await isNetworkAvailable()) {
    throw 'Your internet is not working';
  }
  if (response.statusCode == 401) {
    if (appStore.isLoggedIn) {
      Map req = {
        'email': sharedPref.getString(USER_EMAIL),
        'password': sharedPref.getString(USER_PASSWORD),
      };

      await logInApi(req).then((value) {
        throw 'Please try again.';
      }).catchError((e) {
        throw TokenException(e);
      });
    } else {
      throw '';
    }
  }

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    try {
      var body = jsonDecode(response.body);
      throw parseHtmlString(body['message']);
    } on Exception catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
          "handleResponse_ERROR->::" + e.toString(), s,
          fatal: true);
      log(e);
      throw 'Something Went Wrong';
    }
  }
}

enum HttpMethod { GET, POST, DELETE, PUT }

class TokenException implements Exception {
  final String message;

  const TokenException([this.message = ""]);

  String toString() => "FormatException: $message";
}
