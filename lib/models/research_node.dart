enum ResearchNodeKind {
  project,
  dataset,
  hypothesis,
  paper,
  analysis,
  note,
}

extension ResearchNodeKindInfo on ResearchNodeKind {
  String get label {
    switch (this) {
      case ResearchNodeKind.project:
        return 'Project';
      case ResearchNodeKind.dataset:
        return 'Dataset';
      case ResearchNodeKind.hypothesis:
        return 'Hypothesis';
      case ResearchNodeKind.paper:
        return 'Paper';
      case ResearchNodeKind.analysis:
        return 'Analysis';
      case ResearchNodeKind.note:
        return 'Note';
    }
  }
}

class ResearchNode {
  final String id;
  final ResearchNodeKind kind;
  final String title;
  final String subtitle;
  final double x;
  final double y;
  final String? colorHex;

  ResearchNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.x,
    required this.y,
    this.colorHex,
  });
}
