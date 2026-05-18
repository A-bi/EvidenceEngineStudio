import 'package:uuid/uuid.dart';

import 'research_node.dart';

class CanvasBox {
  final String id;
  String title;
  String subtitle;
  ResearchNodeKind kind;
  double x;
  double y;
  String colorHex;

  CanvasBox({
    String? id,
    required this.title,
    this.subtitle = '',
    this.kind = ResearchNodeKind.note,
    required this.x,
    required this.y,
    this.colorHex = '#477D54',
  }) : id = id ?? const Uuid().v4();

  factory CanvasBox.fromJson(Map<String, dynamic> json) {
    return CanvasBox(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      kind: _kindFromString(json['kind'] as String?),
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      colorHex: json['colorHex'] as String? ?? '#477D54',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'kind': kind.name,
      'x': x,
      'y': y,
      'colorHex': colorHex,
    };
  }

  static ResearchNodeKind _kindFromString(String? value) {
    return ResearchNodeKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => ResearchNodeKind.note,
    );
  }
}
