import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/literature_search_result.dart';

class EvidenceEngineService {
  EvidenceEngineService._();

  static final EvidenceEngineService instance = EvidenceEngineService._();

  Future<List<LiteratureSearchResult>> searchRemotePapers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final uri = Uri.https(
      'evidenceengine.eu',
      '/api/search',
      {
        'q': q,
        'year_from': '2015',
        'year_to': '2026',
        'only_with_abstract': 'false',
        'open_access_only': 'false',
        'limit': '20',
        'offset': '0',
        'sources': 'openalex,pubmed,europepmc,doaj,arxiv',
        'raw_only': 'true',
        'per_source_max': '80',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Referer': 'https://evidenceengine.eu/',
        'User-Agent': 'EvidenceEngineStudioOpen/0.1',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'EvidenceEngine API returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    final List<dynamic> hits;
    if (decoded is List) {
      hits = decoded;
    } else if (decoded is Map && decoded['hits'] is List) {
      hits = decoded['hits'] as List;
    } else if (decoded is Map && decoded['results'] is List) {
      hits = decoded['results'] as List;
    } else {
      throw Exception('Unexpected EvidenceEngine response format.');
    }

    return hits
        .whereType<Map>()
        .map((item) => LiteratureSearchResult.fromApiJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}
