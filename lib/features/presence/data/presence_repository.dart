part of '../../../main.dart';

class PresenceRepository {
  const PresenceRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> today() async {
    return await client.get('/presensi/hari-ini') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> workSchedule() async {
    return await client.get('/jadwal-kerja') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> clock(String type) async {
    final location = await PlatformBridge.location();
    final device = await PlatformBridge.deviceInfo();
    final response =
        await client.post(
              '/presensi/catat',
              body: {
                'jenis': type,
                'latitude': location.latitude,
                'longitude': location.longitude,
                'akurasi': location.accuracy,
                'id_perangkat': device['device_id'],
                'lokasi_palsu': location.mockedLocation,
                'waktu_klien': DateTime.now().toIso8601String(),
              },
            )
            as Map<String, dynamic>;

    return {
      'message': response['pesan'] as String,
      'attendance': Map<String, dynamic>.from(response['presensi'] as Map),
      'location': location,
    };
  }
}
