import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Web-only logger that sends logs via HTTP
/// Parameters: endpoint, logPath (ignored), logData
Future<void> writeLog(String endpoint, String logPath, Map<String, dynamic> logData) async {
  try {
    final request = html.HttpRequest();
    request.open('POST', endpoint, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.send(jsonEncode(logData));
    // Note: HttpRequest.send() is fire-and-forget, we can't easily await it
    // The server should receive it and write to the log file
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[WEB LOGGER ERROR] Failed to send log: $e');
    }
  }
}

