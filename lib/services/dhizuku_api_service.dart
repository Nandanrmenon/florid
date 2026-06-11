import 'package:flutter/services.dart';

class DhizukuApiService {
  static const _channel = MethodChannel('florid/dhizuku');

  Future<bool?> pingBinder() async {
    return _channel.invokeMethod<bool>('pingBinder');
  }

  Future<bool?> checkPermission() async {
    return _channel.invokeMethod<bool>('checkPermission');
  }

  Future<bool?> requestPermission() async {
    return _channel.invokeMethod<bool>('requestPermission');
  }

  Future<String?> installApk(String path) async {
    return _channel.invokeMethod<String>('installApk', {'path': path});
  }
}
