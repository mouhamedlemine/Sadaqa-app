// lib/utils/web_web.dart
import 'dart:js' as js;

typedef FbSuccess = void Function(String token);
typedef FbFailure = void Function();

FbSuccess? _onSuccess;
FbFailure? _onFailure;

void addFacebookSuccessListener(FbSuccess cb) => _onSuccess = cb;
void addFacebookFailureListener(FbFailure cb) => _onFailure = cb;

void callFacebookLoginJS() {
  // ✅ استمع للأحداث التي يرسلها index.html (CustomEvent)
  js.context['window'].callMethod('addEventListener', [
    'facebook-login-success',
    (event) {
      try {
        final token = event['detail']['accessToken'] as String;
        _onSuccess?.call(token);
      } catch (_) {}
    }
  ]);

  js.context['window'].callMethod('addEventListener', [
    'facebook-login-failure',
    (event) {
      _onFailure?.call();
    }
  ]);

  // ✅ نادِ الدالة الموجودة عندك في index.html
  js.context.callMethod('loginWithFacebookJS');
}
