import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'src/js_facade.dart';

part 'src/web_usb_base.dart';

// Helper function to create JavaScript objects
JSObject jsObject(Map<String, Object> map) {
  final obj = JSObject();
  final jsObj = JSObjectWithAccess(obj);
  for (final entry in map.entries) {
    jsObj[entry.key.toJS] = _toJSValue(entry.value);
  }
  return obj;
}

// Helper function to convert Dart values to JS values
JSAny? _toJSValue(Object value) {
  if (value is String) return value.toJS;
  if (value is int) return value.toJS;
  if (value is double) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is Map<String, Object>) return jsObject(value);
  if (value is List) return value.map((e) => _toJSValue(e)).toList().toJS;
  return value.toString().toJS;
}

@JS('navigator.usb')
external EventTarget? get _usb;

@JS('navigator.usb.requestDevice')
external JSAny? _requestDevice(JSObject options);

// Helper function to call transferOut directly
JSAny? callTransferOut(JSObject device, int endpointNumber, JSObject data) {
  final jsObject = JSObjectWithAccess(device);
  final methodRef = jsObject['transferOut'.toJS];
  if (methodRef == null) {
    throw Exception('transferOut method not found');
  }

  final jsFunction = JSFunction(methodRef);
  return jsFunction.call(device, [endpointNumber.toJS, data].toJS);
}

bool canUseUsb() => _usb != null;

Usb? _instance;
Usb get usb {
  if (_usb != null) {
    return _instance ??= Usb._(_usb!);
  }
  throw 'navigator.usb unavailable';
}
