import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'src/js_facade.dart';

part 'src/web_usb_base.dart';

@JS('navigator.usb')
external EventTarget? get _usb;

// External JavaScript functions for WebUSB operations
@JS()
external JSAny? jsRequestDevice(JSAny? options);
@JS()
external JSAny? jsGetDevices();

bool canUseUsb() => _usb != null;

Usb? _instance;
Usb get usb {
  if (_usb != null) {
    return _instance ??= Usb._(_usb!);
  }
  throw 'navigator.usb unavailable';
}
