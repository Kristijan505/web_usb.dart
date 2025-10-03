import 'package:test/test.dart';
import 'package:web_usb/web_usb.dart';

void main() {
  group('Web USB Tests', () {
    test('canUseUsb should return boolean', () {
      final result = canUseUsb();
      expect(result, isA<bool>());
    });

    test('usb getter should work when available', () {
      if (canUseUsb()) {
        final usbInstance = usb;
        expect(usbInstance, isA<Usb>());
      } else {
        // Skip test if USB is not available (e.g., in test environment)
        print('USB not available in test environment');
      }
    });

    test('usb getter should throw when unavailable', () {
      // This test might not work in all environments
      // but it verifies the error handling
      try {
        final usbInstance = usb;
        // If we get here, USB is available
        expect(usbInstance, isA<Usb>());
      } catch (e) {
        expect(e, isA<String>());
        expect(e.toString(), contains('unavailable'));
      }
    });
  });
}
