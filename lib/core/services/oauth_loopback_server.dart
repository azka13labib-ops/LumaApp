import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';

/// Local HTTP loopback server on port 3000 to catch Supabase OAuth redirects.
/// When Supabase redirects to http://localhost:3000/?code=..., this server
/// intercepts the authorization code, exchanges it for a valid session,
/// and responds to the browser with a clean success page while deep-linking
/// back into the LumaApp.
class OAuthLoopbackServer {
  HttpServer? _server;
  Completer<bool>? _completer;

  Future<void> start({
    required Function(Uri uri) onCallback,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (kIsWeb) return;

    try {
      await stop();
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        3000,
        shared: true,
      );
      debugPrint('[OAuthServer] Listening on http://localhost:3000 for OAuth callback...');

      _completer = Completer<bool>();

      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        debugPrint('[OAuthServer] Received request: ${request.method} $uri');

        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error_description'] ?? uri.queryParameters['error'];

        if (code != null || error != null || uri.queryParameters.isNotEmpty) {
          try {
            onCallback(uri);
          } catch (e) {
            debugPrint('[OAuthServer] Callback handler error: $e');
          }

          request.response.headers.contentType = ContentType.html;
          request.response.statusCode = HttpStatus.ok;
          request.response.write(_buildHtmlResponse(isSuccess: error == null));
          await request.response.close();

          if (!_completer!.isCompleted) {
            _completer!.complete(true);
          }
          // Stop server shortly after handling callback
          Future.delayed(const Duration(seconds: 2), () => stop());
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.write('Luma Auth Server Active');
          await request.response.close();
        }
      });

      // Automatically stop server on timeout
      Future.delayed(timeout, () {
        if (_server != null && !(_completer?.isCompleted ?? true)) {
          debugPrint('[OAuthServer] Timed out waiting for OAuth callback.');
          stop();
        }
      });
    } catch (e) {
      debugPrint('[OAuthServer] Failed to start loopback server on port 3000: $e');
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      try {
        await _server!.close(force: true);
        debugPrint('[OAuthServer] Stopped.');
      } catch (_) {}
      _server = null;
    }
  }

  String _buildHtmlResponse({required bool isSuccess}) {
    if (isSuccess) {
      return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Luma - Login Berhasil</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #0A0A0A;
      color: #EDEDED;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141414;
      border: 1px solid #262626;
      border-radius: 24px;
      padding: 36px 28px;
      text-align: center;
      max-width: 360px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.6);
    }
    .icon {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: #EDEDED;
      color: #0A0A0A;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 28px;
      font-weight: bold;
      margin: 0 auto 20px;
    }
    h1 { font-size: 20px; font-weight: 700; margin-bottom: 8px; letter-spacing: -0.5px; }
    p { font-size: 14px; color: #8E8E93; line-height: 1.5; margin-bottom: 24px; }
    .btn {
      display: inline-block;
      background: #EDEDED;
      color: #0A0A0A;
      text-decoration: none;
      font-weight: 600;
      font-size: 14px;
      padding: 12px 28px;
      border-radius: 30px;
      transition: opacity 0.2s;
    }
    .btn:active { opacity: 0.8; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✓</div>
    <h1>Login Berhasil</h1>
    <p>Autentikasi akun berhasil diverifikasi.<br>Kamu bisa kembali ke aplikasi Luma.</p>
    <a href="io.supabase.lumaapp://login-callback" class="btn">Buka Luma</a>
  </div>
  <script>
    setTimeout(function() {
      window.location.href = "io.supabase.lumaapp://login-callback";
    }, 800);
  </script>
</body>
</html>
''';
    } else {
      return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Luma - Login Gagal</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #0A0A0A;
      color: #EDEDED;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
    }
    .card {
      background: #141414;
      border: 1px solid #262626;
      border-radius: 24px;
      padding: 36px 28px;
      text-align: center;
      max-width: 360px;
    }
    .icon {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: #333;
      color: #EDEDED;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      margin: 0 auto 20px;
    }
    h1 { font-size: 20px; font-weight: 700; margin-bottom: 8px; }
    p { font-size: 14px; color: #8E8E93; line-height: 1.5; margin-bottom: 24px; }
    .btn {
      display: inline-block;
      background: #333;
      color: #EDEDED;
      text-decoration: none;
      font-weight: 600;
      font-size: 14px;
      padding: 12px 28px;
      border-radius: 30px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✕</div>
    <h1>Login Dibatalkan</h1>
    <p>Terjadi kesalahan atau proses dibatalkan.<br>Silakan coba kembali dari aplikasi.</p>
    <a href="io.supabase.lumaapp://login-callback" class="btn">Kembali ke Luma</a>
  </div>
</body>
</html>
''';
    }
  }
}
