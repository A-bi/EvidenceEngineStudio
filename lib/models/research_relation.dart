import 'package:uuid/uuid.dart';

enum ResearchRelationKind {
  supports,
  contradicts,
  open,
  basedOn,
  testedBy,
  linkedTo,
}

extension ResearchRelationKindInfo on ResearchRelationKind {
  String get rawValue {
    switch (this) {
      case ResearchRelationKind.supports:
        return 'supports';
      case ResearchRelationKind.contradicts:
        return 'contradicts';
      case ResearchRelationKind.open:
        return 'open';
      case ResearchRelationKind.basedOn:
        return 'based_on';
      case ResearchRelationKind.testedBy:
        return 'tested_by';
      case ResearchRelationKind.linkedTo:
        return 'linked_to';
    }
  }

  String get displayName {
    switch (this) {
      case ResearchRelationKind.supports:
        return 'Supports';
      case ResearchRelationKind.contradicts:
        return 'Contradicts';
      case ResearchRelationKind.open:
        return 'Open';
      case ResearchRelationKind.basedOn:
        return 'Based on';
      case ResearchRelationKind.testedBy:
        return 'Tested by';
      case ResearchRelationKind.linkedTo:
        return 'Linked to';
    }
  }

  static ResearchRelationKind fromRawValue(String? value) {
    switch (value) {
      case 'supports':
        return ResearchRelationKind.supports;
      case 'contradicts':
        return ResearchRelationKind.contradicts;
      case 'open':
        return ResearchRelationKind.open;
      case 'based_on':
        return ResearchRelationKind.basedOn;
      case 'tested_by':
        return ResearchRelationKind.testedBy;
      case 'linked_to':
      default:
        return ResearchRelationKind.linkedTo;
    }
  }
}

class ResearchRelation {
  final String id;
  String sourceId;
  String targetId;
  ResearchRelationKind kind;

  ResearchRelation({
    String? id,
    required this.sourceId,
    required this.targetId,
    required this.kind,
  }) : id = id ?? const Uuid().v4();

  factory ResearchRelation.fromJson(Map<String, dynamic> json) {
    return ResearchRelation(
      id: json['id'] as String?,
      sourceId: json['sourceId'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      kind: ResearchRelationKindInfo.fromRawValue(json['kind'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'targetId': targetId,
      'kind': kind.rawValue,
    };
  }
}
