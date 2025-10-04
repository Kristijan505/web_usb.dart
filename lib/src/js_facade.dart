@JS()
library;

import 'dart:js_interop';
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
    print('🔧 callMethod called: $method with ${args.length} arguments');
    for (int i = 0; i < args.length; i++) {
      print('  arg[$i]: ${args[i].runtimeType} = ${args[i]}');
    }

    final jsObject = JSObjectWithAccess(_delegate as JSObject);
    final methodRef = jsObject[method.toJS];
    if (methodRef == null) {
      throw Exception('Method $method not found');
    }

    // Convert args to JS values
    final jsArgs = args.map((arg) {
      if (arg is String) return arg.toJS;
      if (arg is int) return arg.toJS;
      if (arg is double) return arg.toJS;
      if (arg is bool) return arg.toJS;
      if (arg is TypedData) {
        // Convert TypedData to JS ArrayBuffer
        print('  Converting TypedData to ArrayBuffer');
        return arg.buffer.toJS;
      }
      // Handle other types by converting to string first
      return arg.toString().toJS;
    }).toList();

    print('  Converted to ${jsArgs.length} JS arguments');

    // Call the method with converted arguments
    final jsFunction = JSFunction(methodRef);
    print('  Calling JS function with ${jsArgs.length} arguments');

    // Try using apply method instead of call
    if (jsArgs.isEmpty) {
      final result = jsFunction.call(_delegate, <JSAny?>[].toJS);
      return (result as dynamic) as Result;
    } else if (jsArgs.length == 1) {
      final result = jsFunction.call(_delegate, [jsArgs[0]].toJS);
      return (result as dynamic) as Result;
    } else if (jsArgs.length == 2) {
      final result = jsFunction.call(_delegate, [jsArgs[0], jsArgs[1]].toJS);
      return (result as dynamic) as Result;
    } else {
      final result = jsFunction.call(_delegate, jsArgs.toJS);
      return (result as dynamic) as Result;
    }
  }
}
