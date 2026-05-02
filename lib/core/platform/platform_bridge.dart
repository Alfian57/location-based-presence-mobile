part of '../../main.dart';

class PlatformBridge {
  static const _channel = MethodChannel('presensi/device');

  static Future<Map<String, dynamic>> deviceInfo() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'deviceInfo',
    );
    return Map<String, dynamic>.from(raw ?? {});
  }

  static Future<LocationSnapshot> location() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getLocation',
    );
    return LocationSnapshot.fromMap(Map<String, dynamic>.from(raw ?? {}));
  }

  static Future<void> saveValue(String key, String value) async {
    await _channel.invokeMethod('saveValue', {'key': key, 'value': value});
  }

  static Future<String?> readValue(String key) async {
    return _channel.invokeMethod<String>('readValue', {'key': key});
  }

  static Future<void> clearValue(String key) async {
    await _channel.invokeMethod('clearValue', {'key': key});
  }

  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final granted = await _channel.invokeMethod<bool>(
      'requestNotificationPermission',
    );
    return granted == true;
  }

  static Future<PickedDocument?> pickDocument() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickDocument',
    );
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw);
    return PickedDocument(
      name: map['name']?.toString() ?? 'dokumen',
      mimeType: map['mime_type']?.toString(),
      bytes: map['bytes'] as Uint8List,
    );
  }
}
