import 'package:flutter_driver/flutter_driver.dart';

Future<FlutterDriver> connectDriverWithRetry({int retries = 3}) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (int attempt = 1; attempt <= retries; attempt += 1) {
    try {
      return await FlutterDriver.connect();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (attempt == retries) {
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}
