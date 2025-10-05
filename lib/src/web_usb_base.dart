part of '../web_usb.dart';

// Helper function to convert JavaScript promises to Dart futures using dart:js_interop
Future<T> promiseToFuture<T>(JSAny? promise) {
  if (promise == null) {
    throw Exception('Promise is null');
  }

  // Use dart:js_interop's toDart extension method
  return (promise as JSPromise<JSAny?>).toDart.then((value) {
    // For JS interop wrapper types, create the appropriate wrapper
    if (T == UsbDevice) {
      return UsbDevice._(value as JSObject) as T;
    } else if (T == List<UsbDevice>) {
      // Convert JS array to List<UsbDevice>
      final jsArray = value as JSArray;
      final List<UsbDevice> deviceList = [];
      for (int i = 0; i < jsArray.length; i++) {
        deviceList.add(UsbDevice._(jsArray[i] as JSObject));
      }
      return deviceList as T;
    } else if (T == UsbInTransferResult) {
      return UsbInTransferResult._(value as JSObject) as T;
    } else if (T == UsbOutTransferResult) {
      return UsbOutTransferResult._(value as JSObject) as T;
    } else {
      // For primitive types and void, use dynamic cast
      return (value as dynamic) as T;
    }
  });
}

class Usb extends Delegate<EventTarget> {
  Usb._(super.delegate);

  Future<UsbDevice> requestDevice([RequestOptions? options]) {
    try {
      print('🔧 requestDevice called - creating options object');

      // Create options object if not provided
      JSObject requestOptions;
      if (options != null) {
        print('📋 Using provided options');
        requestOptions = options as JSObject;
      } else {
        print('🆕 Creating new options with empty filters array');
        // Create a simple JavaScript object with empty filters array
        requestOptions = jsObject({'filters': <Object>[]});
        print('✅ Options object created: {filters: []}');
      }

      // Call requestDevice directly using JavaScript interop
      final jsResult = _requestDevice(requestOptions);

      // Convert JavaScript promise to Dart Future using dart:js_interop
      final future = promiseToFuture(jsResult);
      return future.then((value) => UsbDevice._(value));
    } catch (e) {
      throw Exception('Request device failed: $e');
    }
  }

  Future<List<UsbDevice>> getDevices() {
    try {
      // Call getDevices directly on the delegate
      final jsResult = callMethod('getDevices');

      // Convert JavaScript promise to Dart Future using dart:js_interop
      final future = promiseToFuture(jsResult);
      return future.then((value) {
        final List<dynamic> deviceList = List.from(value as dynamic);
        return deviceList.map((e) => UsbDevice._(e)).toList();
      });
    } catch (e) {
      return Future.value(<UsbDevice>[]);
    }
  }

  void subscribeConnect(EventListener listener) {
    delegate.addEventListener('connect', listener);
  }

  void unsubscribeConnect(EventListener listener) {
    delegate.removeEventListener('connect', listener);
  }

  void subscribeDisconnect(EventListener listener) {
    delegate.addEventListener('disconnect', listener);
  }

  void unsubscribeDisconnect(EventListener listener) {
    delegate.removeEventListener('disconnect', listener);
  }
}

@JS()
@staticInterop
@anonymous
class RequestOptions {
  external factory RequestOptions({required JSArray filters});
}

@JS()
@staticInterop
@anonymous
class RequestOptionsFilter {
  external factory RequestOptionsFilter({
    int vendorId,
    int productId,
    int classCode,
    int subclassCode,
    int protocolCode,
    int serialNumber,
  });
}

class UsbDevice extends Delegate<JSObject> {
  UsbDevice._(super.delegate);

  Future<void> open() {
    var promise = callMethod('open');
    return promiseToFuture(promise);
  }

  Future<void> close() {
    var promise = callMethod('close');
    return promiseToFuture(promise);
  }

  Future<void> reset() {
    var promise = callMethod('reset');
    return promiseToFuture(promise);
  }

  UsbConfiguration? get configuration {
    var property = getProperty('configuration');
    if (property == null) return null;
    return UsbConfiguration._(property);
  }

  Future<void> selectConfiguration(int configurationValue) {
    var promise = callMethod('selectConfiguration', [configurationValue]);
    return promiseToFuture(promise);
  }

  Future<void> claimInterface(int interfaceNumber) {
    var promise = callMethod('claimInterface', [interfaceNumber]);
    return promiseToFuture(promise);
  }

  Future<void> releaseInterface(int interfaceNumber) {
    var promise = callMethod('releaseInterface', [interfaceNumber]);
    return promiseToFuture(promise);
  }

  Future<UsbInTransferResult> transferIn(int endpointNumber, int length) {
    var promise = callMethod('transferIn', [endpointNumber, length]);
    return promiseToFuture(
      promise,
    ).then((value) => UsbInTransferResult._(value));
  }

  Future<UsbOutTransferResult> transferOut(int endpointNumber, TypedData data) {
    print(
      '🔧 transferOut called with endpoint: $endpointNumber, data type: ${data.runtimeType}, data length: ${data.lengthInBytes}',
    );

    // Use the new and improved generic callMethod.
    // It will correctly handle the conversion of `data` to an ArrayBuffer.
    var promise = callMethod('transferOut', [endpointNumber, data]);

    return promiseToFuture(
      promise,
    ).then((value) => UsbOutTransferResult._(value));
  }
}

class UsbConfiguration extends Delegate<JSObject> {
  UsbConfiguration._(super.delegate);

  List<UsbInterface> get interfaces {
    var property = getProperty('interfaces');
    if (property == null) return [];
    return (property as List).map((e) => UsbInterface._(e)).toList();
  }
}

class UsbInterface extends Delegate<JSObject> {
  UsbInterface._(super.delegate);

  int get interfaceNumber => getProperty('interfaceNumber');

  List<UsbAlternateInterface> get alternates {
    var property = getProperty('alternates');
    if (property == null) return [];
    return (property as List).map((e) => UsbAlternateInterface._(e)).toList();
  }
}

class UsbAlternateInterface extends Delegate<JSObject> {
  UsbAlternateInterface._(super.delegate);

  int get interfaceClass => getProperty('interfaceClass');

  List<UsbEndpoint> get endpoints {
    var property = getProperty('endpoints');
    if (property == null) return [];
    return (property as List).map((e) => UsbEndpoint._(e)).toList();
  }
}

class UsbEndpoint extends Delegate<JSObject> {
  UsbEndpoint._(super.delegate);

  int get endpointNumber => getProperty('endpointNumber');
  String get direction => getProperty('direction');
  String get type => getProperty('type');
}

class UsbInTransferResult extends Delegate<JSObject> {
  UsbInTransferResult._(super.delegate);

  ByteData get data => getProperty('data');
}

class UsbOutTransferResult extends Delegate<JSObject> {
  UsbOutTransferResult._(super.delegate);

  int get bytesWritten => getProperty('bytesWritten');
}
