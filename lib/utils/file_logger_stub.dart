/// Stub for writeLog on non-IO platforms
Future<void> writeLog(String endpoint, String logPath, Map<String, dynamic> logData) async {
  // Web 平台不执行文件日志记录
}
