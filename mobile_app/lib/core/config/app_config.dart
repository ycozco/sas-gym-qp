import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, staging, prod }

enum AppMode { backend, demo }

class AppConfig {
  static const String environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String appModeName = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'backend',
  );
  static const bool enableDemoLogin = bool.fromEnvironment(
    'ENABLE_DEMO_LOGIN',
    defaultValue: false,
  );
  static const bool enableQrSimulator = bool.fromEnvironment(
    'ENABLE_QR_SIMULATOR',
    defaultValue: false,
  );
  static const int maxLocalImageBytes = int.fromEnvironment(
    'MAX_LOCAL_IMAGE_BYTES',
    defaultValue: 5 * 1024 * 1024,
  );

  static AppEnvironment get environment {
    return switch (environmentName.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }

  static bool get isProduction => environment == AppEnvironment.prod;

  static AppMode get mode {
    return switch (appModeName.toLowerCase()) {
      'demo' => AppMode.demo,
      _ => AppMode.backend,
    };
  }

  static bool get isDemoMode => mode == AppMode.demo;

  static String resolveApiBaseUrl() {
    if (apiBaseUrlOverride.isNotEmpty) {
      _validateProductionApiBaseUrl(apiBaseUrlOverride);
      return apiBaseUrlOverride;
    }
    if (isProduction) {
      throw StateError(
        'API_BASE_URL is required when APP_ENV=production. '
        'Provide it with --dart-define=API_BASE_URL=https://api.<dominio>/api/v1.',
      );
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static String? demoTotpSecretForDni(String dni) {
    if (isProduction) return null;
    if (!enableQrSimulator) return null;
    return '${dni}_secure_totp_secret_key_2026';
  }

  static void _validateProductionApiBaseUrl(String value) {
    if (!isProduction) return;
    final uri = Uri.tryParse(value);
    final host = uri?.host.toLowerCase() ?? '';
    if (host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2') {
      throw StateError(
        'Invalid API_BASE_URL for production: $value. '
        'Use the public HTTPS API URL for the deployed environment.',
      );
    }
  }
}

class AppLogger {
  static void debug(String message, [Object? error]) {
    if (kReleaseMode) return;
    final suffix = error == null ? '' : ': ${_sanitize(error.toString())}';
    debugPrint('$message$suffix');
  }

  static String _sanitize(String value) {
    return value
        .replaceAll(
          RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+/]+=*', caseSensitive: false),
          'Bearer ********',
        )
        .replaceAll(
          RegExp(
            r'''token["']?\s*[:=]\s*["']?[^,\s}\]]+''',
            caseSensitive: false,
          ),
          'token=********',
        )
        .replaceAll(
          RegExp(
            r'''password["']?\s*[:=]\s*["']?[^,\s}\]]+''',
            caseSensitive: false,
          ),
          'password=********',
        );
  }
}
