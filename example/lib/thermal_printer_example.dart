import 'dart:typed_data';
import 'package:web_usb/web_usb.dart';

/// Example of using WebUSB with thermal printers for receipt generation
/// This example shows how to connect to a thermal printer via USB and print a receipt
class ThermalPrinterExample {
  UsbDevice? _device;

  /// Initialize the USB manager and connect to a thermal printer
  Future<bool> initializePrinter() async {
    try {
      // Check if WebUSB is supported
      if (!canUseUsb()) {
        print('WebUSB is not supported in this browser');
        return false;
      }

      // Request a USB device (thermal printer)
      _device = await usb.requestDevice();
      print('Connected to device: ${_device.toString()}');

      // Open the device
      await _device!.open();
      print('Device opened successfully');

      // Select configuration (usually configuration 1)
      await _device!.selectConfiguration(1);
      print('Configuration selected');

      // Claim the interface (usually interface 0)
      await _device!.claimInterface(0);
      print('Interface claimed');

      return true;
    } catch (e) {
      print('Error initializing printer: $e');
      return false;
    }
  }

  /// Generate a simple receipt using raw ESC/POS commands
  List<int> generateSimpleReceipt() {
    var bytes = <int>[];

    // Initialize printer
    bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize printer

    // Company header - Center aligned, double size
    bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll([0x1B, 0x21, 0x30]); // ESC ! 0x30 - Double size
    bytes.addAll('MY COMPANY\n'.codeUnits);

    // Reset to normal size
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal size
    bytes.addAll('123 Main Street\n'.codeUnits);
    bytes.addAll('City, Country\n'.codeUnits);
    bytes.addAll('Phone: +1 234 567 8900\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF - Line feed

    // Receipt header - Bold
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('RECEIPT #001\n'.codeUnits);

    // Reset bold
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll(
      'Date: ${DateTime.now().toString().substring(0, 19)}\n'.codeUnits,
    );

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Horizontal line
    bytes.addAll('--------------------------------\n'.codeUnits);

    // Items header
    bytes.addAll('ITEM                QTY  PRICE  TOTAL\n'.codeUnits);
    bytes.addAll('--------------------------------\n'.codeUnits);

    // Sample items
    bytes.addAll('Coffee               2  5.50  11.00\n'.codeUnits);
    bytes.addAll('Sandwich             1  8.50   8.50\n'.codeUnits);
    bytes.addAll('Cookie               3  2.00   6.00\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF
    bytes.addAll('--------------------------------\n'.codeUnits);

    // Totals - Right aligned
    bytes.addAll([0x1B, 0x61, 0x02]); // ESC a 2 - Right alignment
    bytes.addAll('SUBTOTAL:                    25.50\n'.codeUnits);
    bytes.addAll('TAX (10%):                    2.55\n'.codeUnits);

    // Total - Bold and double size
    bytes.addAll([0x1B, 0x21, 0x38]); // ESC ! 0x38 - Bold + Double size
    bytes.addAll('TOTAL:                       28.05\n'.codeUnits);

    // Reset formatting
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment

    // Feed line
    bytes.addAll([0x0A]); // LF
    bytes.addAll('--------------------------------\n'.codeUnits);

    // Payment info - Center aligned
    bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll('Payment: Cash\n'.codeUnits);
    bytes.addAll('Change: 1.95\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Thank you message - Bold
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('Thank you for your business!\n'.codeUnits);

    // Feed lines
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Cut the paper
    bytes.addAll([0x1D, 0x56, 0x00]); // GS V 0 - Full cut

    return bytes;
  }

  /// Generate a more complex receipt similar to the ArgesERP example
  List<int> generateComplexReceipt() {
    var bytes = <int>[];

    // Initialize printer
    bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize printer

    // Company logo (placeholder)
    bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll([0x1B, 0x21, 0x30]); // ESC ! 0x30 - Double size
    bytes.addAll('[LOGO]\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Company information
    bytes.addAll([0x1B, 0x21, 0x38]); // ESC ! 0x38 - Bold + Double size
    bytes.addAll('ARGES ERP COMPANY\n'.codeUnits);

    // Reset to normal size
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal size
    bytes.addAll('Address: 123 Business Street\n'.codeUnits);
    bytes.addAll('City, Country\n'.codeUnits);
    bytes.addAll('OIB: 12345678901\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Receipt number - Bold
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('RECEIPT #R-2024-001\n'.codeUnits);

    // Reset bold
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Customer information - Right aligned
    bytes.addAll([0x1B, 0x61, 0x02]); // ESC a 2 - Right alignment
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('Customer: John Doe\n'.codeUnits);

    // Reset bold
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll('Address: 456 Customer Ave\n'.codeUnits);
    bytes.addAll('Email: john@example.com\n'.codeUnits);

    // Reset alignment
    bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Horizontal line
    bytes.addAll('----------------------------------------\n'.codeUnits);

    // Items header - Bold
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('ITEM NAME           QTY  PRICE  TOTAL\n'.codeUnits);

    // Reset bold
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll('----------------------------------------\n'.codeUnits);

    // Items
    bytes.addAll('Product A              2  15.50  31.00\n'.codeUnits);
    bytes.addAll('Product B              1  25.00  25.00\n'.codeUnits);
    bytes.addAll('Service C              1  50.00  50.00\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF
    bytes.addAll('----------------------------------------\n'.codeUnits);

    // Tax calculation - Center aligned, Bold
    bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('TAX CALCULATION\n'.codeUnits);

    // Reset bold
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll('----------------------------------------\n'.codeUnits);

    // Reset alignment
    bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('VAT %    BASE        AMOUNT    TOTAL\n'.codeUnits);

    // Reset bold
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll('----------------------------------------\n'.codeUnits);

    bytes.addAll('25      106.00      26.50    132.50\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Totals - Right aligned
    bytes.addAll([0x1B, 0x61, 0x02]); // ESC a 2 - Right alignment
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('TOTAL PRICE:                    106.00\n'.codeUnits);
    bytes.addAll('TOTAL TAX:                        26.50\n'.codeUnits);

    // Total with tax - Bold and double size
    bytes.addAll([0x1B, 0x21, 0x38]); // ESC ! 0x38 - Bold + Double size
    bytes.addAll('TOTAL WITH TAX:                  132.50\n'.codeUnits);

    // Reset formatting
    bytes.addAll([0x1B, 0x21, 0x00]); // ESC ! 0x00 - Normal
    bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0 - Left alignment

    // Feed line
    bytes.addAll([0x0A]); // LF
    bytes.addAll('----------------------------------------\n'.codeUnits);

    // Payment information - Center aligned
    bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center alignment
    bytes.addAll('Payment: Credit Card\n'.codeUnits);
    bytes.addAll('Card ending: ****1234\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF

    // QR Code (placeholder)
    bytes.addAll('[QR CODE]\n'.codeUnits);

    // Feed line
    bytes.addAll([0x0A]); // LF

    // Legal text
    bytes.addAll('This receipt is valid for tax purposes\n'.codeUnits);
    bytes.addAll('Article 39 of the VAT Act applies\n'.codeUnits);

    // Feed lines
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Footer - Bold
    bytes.addAll([0x1B, 0x21, 0x08]); // ESC ! 0x08 - Bold
    bytes.addAll('Thank you for your business!\n'.codeUnits);

    // Feed lines
    bytes.addAll([0x0A, 0x0A]); // LF LF

    // Cut the paper
    bytes.addAll([0x1D, 0x56, 0x00]); // GS V 0 - Full cut

    return bytes;
  }

  /// Send data to the thermal printer via USB
  Future<bool> printReceipt(List<int> receiptData) async {
    if (_device == null) {
      print('Device not initialized');
      return false;
    }

    try {
      // Get the configuration and find the bulk OUT endpoint
      final configuration = _device!.configuration;
      if (configuration == null) {
        print('No configuration available');
        return false;
      }

      // Find the bulk OUT endpoint from the claimed interface
      final interface = configuration.interfaces.first;
      final alternate = interface.alternates.first;

      // Find the bulk OUT endpoint (endpoint with direction OUT)
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

      // Send the receipt data
      final data = Uint8List.fromList(receiptData);
      final result = await _device!.transferOut(endpointNumber, data);

      print('Transfer result: ${result.bytesWritten} bytes written');

      return result.bytesWritten == receiptData.length;
    } catch (e) {
      print('Error printing receipt: $e');
      return false;
    }
  }

  /// Print a simple test receipt
  Future<bool> printTestReceipt() async {
    print('Generating test receipt...');
    final receiptData = generateSimpleReceipt();
    print('Receipt data generated: ${receiptData.length} bytes');

    return await printReceipt(receiptData);
  }

  /// Print a complex receipt similar to ArgesERP
  Future<bool> printComplexReceipt() async {
    print('Generating complex receipt...');
    final receiptData = generateComplexReceipt();
    print('Receipt data generated: ${receiptData.length} bytes');

    return await printReceipt(receiptData);
  }

  /// Clean up resources
  Future<void> cleanup() async {
    if (_device != null) {
      try {
        await _device!.releaseInterface(0);
        await _device!.close();
        print('Device released and closed');
      } catch (e) {
        print('Error during cleanup: $e');
      }
    }
  }
}

/// Example usage function
Future<void> runThermalPrinterExample() async {
  final printer = ThermalPrinterExample();

  try {
    // Initialize the printer
    print('Initializing thermal printer...');
    final initialized = await printer.initializePrinter();

    if (!initialized) {
      print('Failed to initialize printer');
      return;
    }

    // Print a simple test receipt
    print('Printing test receipt...');
    final success = await printer.printTestReceipt();

    if (success) {
      print('Test receipt printed successfully!');

      // Wait a bit before printing the complex receipt
      await Future.delayed(const Duration(seconds: 2));

      // Print a complex receipt
      print('Printing complex receipt...');
      final complexSuccess = await printer.printComplexReceipt();

      if (complexSuccess) {
        print('Complex receipt printed successfully!');
      } else {
        print('Failed to print complex receipt');
      }
    } else {
      print('Failed to print test receipt');
    }
  } catch (e) {
    print('Error in thermal printer example: $e');
  } finally {
    // Clean up
    await printer.cleanup();
  }
}
