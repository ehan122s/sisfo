import 'dart:js_interop';

@JS('localStorage.clear')
external void _clearLocalStorage();

@JS('sessionStorage.clear')
external void _clearSessionStorage();

@JS('location.reload')
external void _reload();

void clearWebStorage() {
  _clearLocalStorage();
  _clearSessionStorage();
  _reload();
}
