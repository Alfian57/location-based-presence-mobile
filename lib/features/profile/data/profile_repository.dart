part of '../../../main.dart';

class ProfileRepository {
  const ProfileRepository(this.client);

  final ApiClient client;

  Future<Map<String, dynamic>> updateNotifications(bool enabled) async {
    final response =
        await client.put(
              '/profil/pengaturan-notifikasi',
              body: {'notifikasi_aktif': enabled},
            )
            as Map<String, dynamic>;

    return Map<String, dynamic>.from(response['pengguna'] as Map);
  }
}
