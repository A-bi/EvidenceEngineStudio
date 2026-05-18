import 'package:uuid/uuid.dart';

class EvidencePaper {
  final String id;
  String title;
  String journal;
  int year;
  String summary;
  String? authors;
  String? doi;
  String? url;
  String? projectId;

  EvidencePaper({
    String? id,
    required this.title,
    required this.journal,
    required this.year,
    required this.summary,
    this.authors,
    this.doi,
    this.url,
    this.projectId,
  }) : id = id ?? const Uuid().v4();

  factory EvidencePaper.fromJson(Map<String, dynamic> json) {
    return EvidencePaper(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      journal: json['journal'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      authors: json['authors'] as String?,
      doi: json['doi'] as String?,
      url: json['url'] as String?,
      projectId: json['projectId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'journal': journal,
      'year': year,
      'summary': summary,
      'authors': authors,
      'doi': doi,
      'url': url,
      'projectId': projectId,
    };
  }
}
