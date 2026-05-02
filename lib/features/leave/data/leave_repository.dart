part of '../../../main.dart';

class LeaveRepository {
  const LeaveRepository(this.client);

  final ApiClient client;

  Future<List<dynamic>> list() async {
    final response =
        await client.get('/pengajuan-izin') as Map<String, dynamic>;

    return response['data'] as List<dynamic>;
  }

  Future<void> submit({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    required PickedDocument? document,
  }) async {
    await client.multipartLeave({
      'jenis': type,
      'tanggal_mulai': startDate,
      'tanggal_selesai': endDate,
      'alasan': reason,
    }, document);
  }
}
