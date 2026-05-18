class LiteratureSearchResult {
  final String remoteId;
  final String title;
  final String authors;
  final String journal;
  final int year;
  final String summary;
  final String? doi;
  final String? url;
  final String? pdfUrl;

  LiteratureSearchResult({
    required this.remoteId,
    required this.title,
    required this.authors,
    required this.journal,
    required this.year,
    required this.summary,
    this.doi,
    this.url,
    this.pdfUrl,
  });

  factory LiteratureSearchResult.fromApiJson(Map<String, dynamic> json) {
    final rawAuthors = json['authors'];

    String authors;
    if (rawAuthors is List) {
      authors = rawAuthors.map((e) => e.toString()).join(', ');
    } else {
      authors = rawAuthors?.toString() ?? '';
    }

    return LiteratureSearchResult(
      remoteId: json['id']?.toString() ??
          json['remoteID']?.toString() ??
          json['doi']?.toString() ??
          json['title']?.toString() ??
          '',
      title: json['title']?.toString() ?? 'Untitled',
      authors: authors,
      journal: json['journal']?.toString() ??
          json['source']?.toString() ??
          'Unknown source',
      year: json['year'] is num
          ? (json['year'] as num).toInt()
          : int.tryParse(json['year']?.toString() ?? '') ?? 0,
      summary: json['abstract']?.toString() ??
          json['summary']?.toString() ??
          '',
      doi: json['doi']?.toString(),
      url: json['url']?.toString(),
      pdfUrl: json['pdf_url']?.toString() ?? json['pdfURL']?.toString(),
    );
  }
}
