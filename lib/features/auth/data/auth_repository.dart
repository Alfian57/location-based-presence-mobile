part of '../../../main.dart';

class AuthRepository {
  AuthRepository({required this.apiBase});

  final String apiBase;

  ApiClient get _client => ApiClient(baseUrl: apiBase);

  Future<Map<String, dynamic>> authenticate({
    required bool activationMode,
    required String email,
    required String password,
  }) async {
    final device = await PlatformBridge.deviceInfo();
    final response =
        await _client.post(
              activationMode ? '/autentikasi/aktivasi' : '/autentikasi/masuk',
              body: {
                'email': email,
                'kata_sandi': password,
                'id_perangkat': device['device_id'],
                'nama_perangkat': device['device_name'],
                'platform': device['platform'],
              },
            )
            as Map<String, dynamic>;

    return response;
  }

  Future<String> resetPassword(String email) async {
    final response =
        await _client.post(
              '/autentikasi/reset-kata-sandi',
              body: {'email': email},
            )
            as Map<String, dynamic>;

    return response['pesan'] as String;
  }
}
