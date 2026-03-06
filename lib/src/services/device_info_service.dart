import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String?> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use androidId for unique identification (survives app reinstalls usually)
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // identifierForVendor (changes on reinstall, but acceptable for this scope)
        return iosInfo.identifierForVendor;
      }
      return 'unknown_device';
    } catch (e) {
      return null;
    }
  }

  Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return "${iosInfo.name} ${iosInfo.systemName}";
      }
      return 'Generic Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }
}

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});
