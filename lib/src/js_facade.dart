@JS()
library;

import 'dart:js_interop';
import 'dart:typed_data';

// Helper to convert Dart types to JS types
JSAny? _toJSValue(Object value) {
  if (value is String) return value.toJS;
  if (value is num) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is TypedData) return value.buffer.toJS;
  if (value is List) return value.map((e) => _toJSValue(e)).toList().toJS;
  return value.toString().toJS;
}

@JS()
extension type JSObjectWithAccess(JSObject _) implements JSObject {
  external JSAny? operator [](JSString key);
  external void operator []=(JSString key, JSAny? value);
}

// Extension to correctly expose JavaScript's 'apply' function
extension JSFunctionApply on JSAny? {
  @JS('apply')
  external JSAny? apply(JSAny? thisArg, JSArray args);
}

abstract class Delegate<T extends JSObject> {
  final T _delegate;

  T get delegate => _delegate;

  Delegate(this._delegate);

  Prop getProperty<Prop>(String name) {
    final jsObject = JSObjectWithAccess(_delegate as JSObject);
    final value = jsObject[name.toJS];
    return (value as dynamic) as Prop;
  }

  // Rewritten callMethod to be generic and correct
  Result callMethod<Result>(String method, [List<Object> args = const []]) {
    final jsObject = JSObjectWithAccess(_delegate as JSObject);
    final methodRef = jsObject[method.toJS];
    if (methodRef == null) {
      throw Exception('Method $method not found');
    }

    final jsArgs = args.map((arg) => _toJSValue(arg)).toList().toJS;

    final result = methodRef.apply(_delegate, jsArgs);
    return (result as dynamic) as Result;
  }
}
