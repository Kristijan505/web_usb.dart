import 'dart:typed_data';
import 'package:web_usb/web_usb.dart';

class ThermalPrinterExample {
  UsbDevice? _device;

  Future<bool> initializePrinter() async {
    try {
      print('Requesting USB device...');
      _device = await usb.requestDevice();
      print('Connected to device: $_device');

      print('Opening device...');
      await _device!.open();
      print('Device opened successfully');

      print('Selecting configuration...');
      await _device!.selectConfiguration(1);
      print('Configuration selected');

      print('Claiming interface...');
      final configuration = _device!.configuration;
      if (configuration == null) {
        print('No configuration available');
        return false;
      }

      final interface = configuration.interfaces.first;
      await _device!.claimInterface(interface.interfaceNumber);
      print('Interface claimed');

      return true;
    } catch (e) {
      print('Error initializing printer: $e');
      return false;
    }
  }

  /// Generate a simple test receipt using raw ESC/POS commands
  List<int> generateSimpleReceipt() {
    var bytes = <int>[];

    // Initialize printer
    bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize printer

    // Simple test message - Center aligned, Bold
    bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('TEST SUCCESSFUL!\n'.codeUnits);

    // Reset formatting
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Cut paper
    bytes.addAll([0x1D, 0x56, 0x00]); // GS V 0 - Full cut

    return bytes;
  }

  Future<bool> printTestReceipt() async {
    if (_device == null) {
      print('Device not initialized');
      return false;
    }

    try {
      print('Generating test receipt...');
      final receiptData = generateSimpleReceipt();
      print('Receipt data generated: ${receiptData.length} bytes');

      return await printReceipt(receiptData);
    } catch (e) {
      print('Error printing test receipt: $e');
      return false;
    }
  }

  Future<bool> printReceipt(List<int> receiptData) async {
    if (_device == null) {
      print('Device not initialized');
      return false;
    }

    try {
      final configuration = _device!.configuration;
      if (configuration == null) {
        print('No configuration available');
        return false;
      }

      final interface = configuration.interfaces.first;
      final alternate = interface.alternates.first;

      int? endpointNumber;
      for (int i = 0; i < alternate.endpoints.length; i++) {
        final endpoint = alternate.endpoints[i];
        if (endpoint.direction == 'out') {
          endpointNumber = endpoint.endpointNumber;
          print('Found bulk OUT endpoint: $endpointNumber');
          break;
        }
      }

      if (endpointNumber == null) {
        print('No bulk OUT endpoint found');
        return false;
      }

      print('Using endpoint: $endpointNumber');

      final data = Uint8List.fromList(receiptData);
      final result = await _device!.transferOut(endpointNumber, data);

      print('Transfer result: ${result.bytesWritten} bytes written');

      return result.bytesWritten == receiptData.length;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  Future<void> cleanup() async {
    if (_device != null) {
      try {
        final configuration = _device!.configuration;
        if (configuration != null) {
          final interface = configuration.interfaces.first;
          await _device!.releaseInterface(interface.interfaceNumber);
          print('Interface released');
        }
        await _device!.close();
        print('Device released and closed');
      } catch (e) {
        print('Error during cleanup: $e');
      }
    }
  }
}
