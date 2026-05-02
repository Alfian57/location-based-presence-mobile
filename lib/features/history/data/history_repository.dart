part of '../../../main.dart';

class HistoryRepository {
  const HistoryRepository(this.client);

  final ApiClient client;

  Future<List<dynamic>> listByMonth(String month) async {
    final response =
        await client.get(
              '/presensi/riwayat?bulan=${Uri.encodeQueryComponent(month)}',
            )
            as Map<String, dynamic>;

    return response['data'] as List<dynamic>;
  }
}
