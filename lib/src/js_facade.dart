@JS()
library;

import 'dart:js_interop';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

// Extension type for JSObject to add property and method access
@JS()
extension type JSObjectWithAccess(JSObject _) implements JSObject {
  external JSAny? operator [](JSString key);
  external void operator []=(JSString key, JSAny? value);
}

// Extension type for JS functions
@JS()
extension type JSFunction(JSAny _) implements JSAny {
  external JSAny? call(JSAny? thisArg, JSAny? args);
}

abstract class Delegate<T extends JSObject> {
  final T _delegate;

  T get delegate => _delegate;

  Delegate(this._delegate);

  Prop getProperty<Prop>(String name) {
    final jsObject = JSObjectWithAccess(_delegate as JSObject);
    final value = jsObject[name.toJS];
    // Use dynamic cast to avoid js_interop warnings
    return (value as dynamic) as Prop;
  }

  Result callMethod<Result>(String method, [List<Object> args = const []]) {
    final jsObject = JSObjectWithAccess(_delegate as JSObject);
    final methodRef = jsObject[method.toJS];
    if (methodRef == null) {
      throw Exception('Method $method not found');
    }
    // Convert args to JS array
    final jsArgs = args.map((arg) {
      if (arg is String) return arg.toJS;
      if (arg is int) return arg.toJS;
      if (arg is double) return arg.toJS;
      if (arg is bool) return arg.toJS;
      if (arg is TypedData) {
        // Convert TypedData to JS ArrayBuffer
        return arg.buffer.asUint8List().toJS;
      }
      // Handle other types by converting to string first
      return arg.toString().toJS;
    }).toList();

    // Use js_util.callMethod for multiple arguments
    final result = js_util.callMethod(_delegate, method, args);
    // Use dynamic cast to avoid js_interop warnings
    return (result as dynamic) as Result;
  }
}
