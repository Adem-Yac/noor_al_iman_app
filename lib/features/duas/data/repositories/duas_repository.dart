import '../../../../data/web_services/ummah_api_service.dart';
import '../models/dua_models.dart';

class DuasRepository {
  DuasRepository({UmmahApiService? api}) : _api = api ?? UmmahApiService();

  final UmmahApiService _api;

  Future<DuasHub> getHub() async {
    return DuasHub.fromJson(await _api.getDuas());
  }

  Future<List<Dua>> getByCategory(String category) async {
    final json = await _api.getDuas(category: category);
    final data = json['data'] as Map<String, dynamic>;
    return (data['duas'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Dua.fromJson)
        .toList();
  }
}
