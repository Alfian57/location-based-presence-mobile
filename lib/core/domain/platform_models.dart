part of '../../main.dart';

class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.mockedLocation,
  });

  factory LocationSnapshot.fromMap(Map<String, dynamic> map) {
    return LocationSnapshot(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      mockedLocation: map['mocked_location'] == true,
    );
  }

  final double latitude;
  final double longitude;
  final int accuracy;
  final bool mockedLocation;
}

class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String name;
  final String? mimeType;
  final Uint8List bytes;

  bool get validForLeaveUpload {
    if (bytes.length > 4 * 1024 * 1024) return false;

    final lowerName = name.toLowerCase();
    final lowerMime = mimeType?.toLowerCase();
    return lowerMime == 'application/pdf' ||
        lowerMime == 'image/jpeg' ||
        lowerMime == 'image/png' ||
        lowerName.endsWith('.pdf') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png');
  }
}
