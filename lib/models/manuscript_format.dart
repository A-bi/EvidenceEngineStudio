enum ManuscriptPreset {
  nature,
  jamaClinical,
  genericBiomedical,
  preprint,
  thesis,
  custom,
}

extension ManuscriptPresetInfo on ManuscriptPreset {
  String get label {
    switch (this) {
      case ManuscriptPreset.nature:
        return 'Nature-style';
      case ManuscriptPreset.jamaClinical:
        return 'JAMA / Clinical';
      case ManuscriptPreset.genericBiomedical:
        return 'Generic Biomedical';
      case ManuscriptPreset.preprint:
        return 'Preprint';
      case ManuscriptPreset.thesis:
        return 'Thesis / Long Report';
      case ManuscriptPreset.custom:
        return 'Custom';
    }
  }
}

class ManuscriptFormat {
  ManuscriptPreset preset;
  String fontFamily;
  double fontSize;
  double lineSpacing;
  String citationStyle;
  bool includeLineNumbers;
  bool includeTitlePage;
  bool includeStructuredAbstract;
  bool includeWordCount;

  ManuscriptFormat({
    this.preset = ManuscriptPreset.genericBiomedical,
    this.fontFamily = 'Helvetica',
    this.fontSize = 11,
    this.lineSpacing = 1.5,
    this.citationStyle = 'author-year',
    this.includeLineNumbers = false,
    this.includeTitlePage = true,
    this.includeStructuredAbstract = true,
    this.includeWordCount = false,
  });

  factory ManuscriptFormat.fromJson(Map<String, dynamic> json) {
    return ManuscriptFormat(
      preset: ManuscriptPreset.values.firstWhere(
        (p) => p.name == json['preset'],
        orElse: () => ManuscriptPreset.genericBiomedical,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'Helvetica',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 11,
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.5,
      citationStyle: json['citationStyle'] as String? ?? 'author-year',
      includeLineNumbers: json['includeLineNumbers'] as bool? ?? false,
      includeTitlePage: json['includeTitlePage'] as bool? ?? true,
      includeStructuredAbstract:
          json['includeStructuredAbstract'] as bool? ?? true,
      includeWordCount: json['includeWordCount'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preset': preset.name,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'citationStyle': citationStyle,
      'includeLineNumbers': includeLineNumbers,
      'includeTitlePage': includeTitlePage,
      'includeStructuredAbstract': includeStructuredAbstract,
      'includeWordCount': includeWordCount,
    };
  }

  void applyPreset(ManuscriptPreset value) {
    preset = value;

    switch (value) {
      case ManuscriptPreset.nature:
        fontFamily = 'Helvetica';
        fontSize = 10;
        lineSpacing = 1.0;
        citationStyle = 'numeric';
        includeLineNumbers = true;
        includeTitlePage = true;
        includeStructuredAbstract = false;
        includeWordCount = true;
        break;

      case ManuscriptPreset.jamaClinical:
        fontFamily = 'Times New Roman';
        fontSize = 12;
        lineSpacing = 2.0;
        citationStyle = 'numeric';
        includeLineNumbers = true;
        includeTitlePage = true;
        includeStructuredAbstract = true;
        includeWordCount = true;
        break;

      case ManuscriptPreset.genericBiomedical:
        fontFamily = 'Helvetica';
        fontSize = 11;
        lineSpacing = 1.5;
        citationStyle = 'author-year';
        includeLineNumbers = false;
        includeTitlePage = true;
        includeStructuredAbstract = true;
        includeWordCount = false;
        break;

      case ManuscriptPreset.preprint:
        fontFamily = 'Arial';
        fontSize = 11;
        lineSpacing = 1.25;
        citationStyle = 'author-year';
        includeLineNumbers = false;
        includeTitlePage = true;
        includeStructuredAbstract = true;
        includeWordCount = false;
        break;

      case ManuscriptPreset.thesis:
        fontFamily = 'Times New Roman';
        fontSize = 12;
        lineSpacing = 1.5;
        citationStyle = 'author-year';
        includeLineNumbers = false;
        includeTitlePage = true;
        includeStructuredAbstract = true;
        includeWordCount = false;
        break;

      case ManuscriptPreset.custom:
        break;
    }
  }
}
