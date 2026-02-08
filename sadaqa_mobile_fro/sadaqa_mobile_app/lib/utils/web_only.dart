// web_only.dart (Web implementation)
import 'dart:html' as html;
import 'dart:js' as js;

void addFacebookSuccessListener(Function(String token) onToken) {
  html.window.addEventListener('facebook-login-success', (event) async {
    final custom = event as html.CustomEvent;
    final detail = custom.detail as dynamic;
    final token = detail['accessToken'] as String;
    onToken(token);
  });
}

void addFacebookFailureListener(VoidCallback onFail) {
  html.window.addEventListener('facebook-login-failure', (event) {
    onFail();
  });
}

void callFacebookLoginJS() {
  js.context.callMethod('loginWithFacebookJS');
}

typedef VoidCallback = void Function();
