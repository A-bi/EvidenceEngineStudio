import 'package:uuid/uuid.dart';

import 'manuscript_format.dart';

class ManuscriptSection {
  final String id;
  final String title;
  String content;
  bool collapsed;

  ManuscriptSection({
    required this.id,
    required this.title,
    this.content = '',
    this.collapsed = false,
  });

  factory ManuscriptSection.fromJson(Map<String, dynamic> json) {
    return ManuscriptSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      collapsed: json['collapsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'collapsed': collapsed,
    };
  }
}

class ManuscriptFormula {
  final String id;
  String title;
  String latex;
  String note;

  ManuscriptFormula({
    String? id,
    required this.title,
    required this.latex,
    this.note = '',
  }) : id = id ?? const Uuid().v4();

  factory ManuscriptFormula.fromJson(Map<String, dynamic> json) {
    return ManuscriptFormula(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      latex: json['latex'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'latex': latex, 'note': note};
  }
}

class ManuscriptFigure {
  final String id;
  String title;
  String caption;
  String path;
  String note;

  ManuscriptFigure({
    String? id,
    required this.title,
    required this.caption,
    required this.path,
    this.note = '',
  }) : id = id ?? const Uuid().v4();

  factory ManuscriptFigure.fromJson(Map<String, dynamic> json) {
    return ManuscriptFigure(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      path: json['path'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'caption': caption,
      'path': path,
      'note': note,
    };
  }
}

class ManuscriptDataAttachment {
  final String id;
  String name;
  String path;
  String description;

  ManuscriptDataAttachment({
    String? id,
    required this.name,
    required this.path,
    this.description = '',
  }) : id = id ?? const Uuid().v4();

  factory ManuscriptDataAttachment.fromJson(Map<String, dynamic> json) {
    return ManuscriptDataAttachment(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'path': path, 'description': description};
  }
}

class Manuscript {
  String title;
  String authors;
  String affiliation;
  String abstractText;
  String keywords;
  String journalTarget;
  String notes;

  bool metadataCollapsed;
  bool referencesCollapsed;
  bool formulasCollapsed;
  bool figuresCollapsed;
  bool attachmentsCollapsed;
  bool analysesCollapsed;

  ManuscriptFormat format;

  List<ManuscriptSection> sections;
  List<ManuscriptFormula> formulas;
  List<ManuscriptFigure> figures;
  List<ManuscriptDataAttachment> dataAttachments;

  Manuscript({
    this.title = '',
    this.authors = '',
    this.affiliation = '',
    this.abstractText = '',
    this.keywords = '',
    this.journalTarget = '',
    this.notes = '',
    this.metadataCollapsed = false,
    this.referencesCollapsed = false,
    this.formulasCollapsed = false,
    this.figuresCollapsed = false,
    this.attachmentsCollapsed = false,
    this.analysesCollapsed = false,
    ManuscriptFormat? format,
    List<ManuscriptSection>? sections,
    List<ManuscriptFormula>? formulas,
    List<ManuscriptFigure>? figures,
    List<ManuscriptDataAttachment>? dataAttachments,
  }) : format = format ?? ManuscriptFormat(),
       sections = sections ?? defaultSections(),
       formulas = formulas ?? [],
       figures = figures ?? [],
       dataAttachments = dataAttachments ?? [];

  factory Manuscript.fromJson(Map<String, dynamic> json) {
    final decodedSections = (json['sections'] as List? ?? [])
        .whereType<Map>()
        .map((e) => ManuscriptSection.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return Manuscript(
      title: json['title'] as String? ?? '',
      authors: json['authors'] as String? ?? '',
      affiliation: json['affiliation'] as String? ?? '',
      abstractText: json['abstractText'] as String? ?? '',
      keywords: json['keywords'] as String? ?? '',
      journalTarget: json['journalTarget'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      metadataCollapsed: json['metadataCollapsed'] as bool? ?? false,
      referencesCollapsed: json['referencesCollapsed'] as bool? ?? false,
      formulasCollapsed: json['formulasCollapsed'] as bool? ?? false,
      figuresCollapsed: json['figuresCollapsed'] as bool? ?? false,
      attachmentsCollapsed: json['attachmentsCollapsed'] as bool? ?? false,
      analysesCollapsed: json['analysesCollapsed'] as bool? ?? false,
      format: json['format'] == null
          ? ManuscriptFormat()
          : ManuscriptFormat.fromJson(
              Map<String, dynamic>.from(json['format'] as Map),
            ),
      sections: decodedSections.isEmpty ? defaultSections() : decodedSections,
      formulas: (json['formulas'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ManuscriptFormula.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      figures: (json['figures'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ManuscriptFigure.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      dataAttachments: (json['dataAttachments'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) =>
                ManuscriptDataAttachment.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'authors': authors,
      'affiliation': affiliation,
      'abstractText': abstractText,
      'keywords': keywords,
      'journalTarget': journalTarget,
      'notes': notes,
      'metadataCollapsed': metadataCollapsed,
      'referencesCollapsed': referencesCollapsed,
      'formulasCollapsed': formulasCollapsed,
      'figuresCollapsed': figuresCollapsed,
      'attachmentsCollapsed': attachmentsCollapsed,
      'analysesCollapsed': analysesCollapsed,
      'format': format.toJson(),
      'sections': sections.map((e) => e.toJson()).toList(),
      'formulas': formulas.map((e) => e.toJson()).toList(),
      'figures': figures.map((e) => e.toJson()).toList(),
      'dataAttachments': dataAttachments.map((e) => e.toJson()).toList(),
    };
  }

  static List<ManuscriptSection> defaultSections() {
    return [
      ManuscriptSection(id: 'title_page', title: 'Title Page'),
      ManuscriptSection(id: 'abstract', title: 'Abstract'),
      ManuscriptSection(id: 'keywords', title: 'Keywords'),
      ManuscriptSection(id: 'introduction', title: 'Introduction'),
      ManuscriptSection(id: 'background', title: 'Background / Rationale'),
      ManuscriptSection(id: 'objectives', title: 'Objectives'),
      ManuscriptSection(id: 'methods', title: 'Methods'),
      ManuscriptSection(id: 'study_design', title: 'Study Design'),
      ManuscriptSection(
        id: 'participants',
        title: 'Participants / Data Source',
      ),
      ManuscriptSection(id: 'variables', title: 'Variables'),
      ManuscriptSection(id: 'statistics', title: 'Statistical Analysis'),
      ManuscriptSection(id: 'results', title: 'Results'),
      ManuscriptSection(id: 'figures_tables', title: 'Figures and Tables'),
      ManuscriptSection(id: 'discussion', title: 'Discussion'),
      ManuscriptSection(id: 'interpretation', title: 'Interpretation'),
      ManuscriptSection(id: 'limitations', title: 'Limitations'),
      ManuscriptSection(id: 'conclusion', title: 'Conclusion'),
      ManuscriptSection(id: 'ethics', title: 'Ethics Statement'),
      ManuscriptSection(id: 'data_availability', title: 'Data Availability'),
      ManuscriptSection(id: 'funding', title: 'Funding'),
      ManuscriptSection(id: 'conflicts', title: 'Conflicts of Interest'),
      ManuscriptSection(id: 'acknowledgements', title: 'Acknowledgements'),
      ManuscriptSection(id: 'supplementary', title: 'Supplementary Material'),
    ];
  }
}
