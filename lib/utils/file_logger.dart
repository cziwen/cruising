import 'dart:io';
import 'dart:convert';

/// Desktop-only logger that writes to file
/// Parameters: endpoint (ignored on desktop), logPath, logData
Future<void> writeLog(String endpoint, String logPath, Map<String, dynamic> logData) async {
  try {
    final logFile = File(logPath);
    if (!await logFile.exists()) {
      await logFile.create(recursive: true);
    }
    await logFile.writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
  } catch (_) {}
}

