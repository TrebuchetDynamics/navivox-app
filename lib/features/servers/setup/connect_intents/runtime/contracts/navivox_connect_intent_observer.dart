import '../../../../models/connection_import.dart';

class NavivoxConnectIntentObserver {
  SetupQrImageImport? lastImport;

  void record(SetupQrImageImport import) {
    lastImport = import;
  }
}
