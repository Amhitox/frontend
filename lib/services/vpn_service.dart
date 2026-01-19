import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();

  factory VpnService() {
    return _instance;
  }

  VpnService._internal();

  Future<bool> isVpnActive() async {
    try {
      final List<ConnectivityResult> connectivityResults = await (Connectivity().checkConnectivity());
      if (connectivityResults.contains(ConnectivityResult.vpn)) {
        return true;
      }

      final List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains("tun") ||
            name.contains("tap") ||
            name.contains("ppp") ||
            name.contains("pptp") ||
            name.contains("ipsec") ||
            name.contains("l2tp")) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
