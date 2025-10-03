import 'dart:js_interop';
import 'package:web/web.dart';
import 'package:web_usb/web_usb.dart';
import 'thermal_printer_example.dart';

void main() {
  // Get DOM elements
  final statusDiv = document.getElementById('status') as HTMLDivElement;
  final outputDiv = document.getElementById('output') as HTMLDivElement;
  final checkUsbBtn = document.getElementById('checkUsb') as HTMLButtonElement;
  final getDevicesBtn =
      document.getElementById('getDevices') as HTMLButtonElement;
  final requestDeviceBtn =
      document.getElementById('requestDevice') as HTMLButtonElement;
  final testThermalPrinterBtn =
      document.getElementById('testThermalPrinter') as HTMLButtonElement;

  // Helper function to update status
  void updateStatus(String message, String type) {
    statusDiv.textContent = message;
    statusDiv.className = 'status $type';
  }

  // Helper function to add output
  void addOutput(String message) {
    final p = document.createElement('p') as HTMLParagraphElement;
    p.textContent = message;
    outputDiv.appendChild(p);
  }

  // Check USB support
  void checkUsbSupport() {
    try {
      final canUse = canUseUsb();
      if (canUse) {
        updateStatus('✅ USB API is supported!', 'success');
        addOutput('USB API is available in this browser');
      } else {
        updateStatus('❌ USB API is not supported', 'error');
        addOutput('USB API is not available in this browser');
      }
    } catch (e) {
      updateStatus('❌ Error checking USB support: $e', 'error');
      addOutput('Error: $e');
    }
  }

  // Get devices
  void getDevices() async {
    try {
      if (!canUseUsb()) {
        addOutput('USB API not available');
        return;
      }

      addOutput('Getting devices...');
      final devices = await usb.getDevices();
      addOutput('Found ${devices.length} devices');

      for (int i = 0; i < devices.length; i++) {
        addOutput('Device $i: ${devices[i].toString()}');
      }
    } catch (e) {
      addOutput('Error getting devices: $e');
    }
  }

  // Request device
  void requestDevice() async {
    try {
      if (!canUseUsb()) {
        addOutput('USB API not available');
        return;
      }

      addOutput('Requesting device...');
      final device = await usb.requestDevice();
      addOutput('Device selected: ${device.toString()}');
    } catch (e) {
      addOutput('Error requesting device: $e');
    }
  }

  // Test thermal printer
  void testThermalPrinter() async {
    try {
      if (!canUseUsb()) {
        addOutput('USB API not available');
        return;
      }

      addOutput('Testing thermal printer functionality...');

      final printer = ThermalPrinterExample();

      // Initialize the printer
      addOutput('Initializing thermal printer...');
      final initialized = await printer.initializePrinter();

      if (!initialized) {
        addOutput('Failed to initialize printer');
        return;
      }

      // Print a simple test receipt
      addOutput('Printing test receipt...');
      final success = await printer.printTestReceipt();

      if (success) {
        addOutput('✅ Test receipt printed successfully!');

        // Wait a bit before printing the complex receipt
        await Future.delayed(const Duration(seconds: 2));

        // Print a complex receipt
        addOutput('Printing complex receipt...');
        final complexSuccess = await printer.printComplexReceipt();

        if (complexSuccess) {
          addOutput('✅ Complex receipt printed successfully!');
        } else {
          addOutput('❌ Failed to print complex receipt');
        }
      } else {
        addOutput('❌ Failed to print test receipt');
      }

      // Clean up
      await printer.cleanup();
      addOutput('Printer cleanup completed');
    } catch (e) {
      addOutput('Error testing thermal printer: $e');
    }
  }

  // Set up event listeners
  checkUsbBtn.onClick.listen((_) => checkUsbSupport());
  getDevicesBtn.onClick.listen((_) => getDevices());
  requestDeviceBtn.onClick.listen((_) => requestDevice());
  testThermalPrinterBtn.onClick.listen((_) => testThermalPrinter());

  // Initial check
  checkUsbSupport();
}
