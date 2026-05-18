import 'project.dart';
import 'dataset.dart';
import 'evidence_paper.dart';
import 'hypothesis_node.dart';
import 'research_relation.dart';
import 'dataset_summary.dart';
import 'analysis_history_item.dart';
import 'canvas_box.dart';
import 'manuscript.dart';
import 'inspected_file.dart';

class AppSnapshot {
  final List<Project> projects;
  final List<Dataset> datasets;
  final List<EvidencePaper> papers;
  final List<HypothesisNode> hypotheses;
  final List<ResearchRelation> relations;
  final List<AnalysisHistoryItem> analysisHistory;
  final List<CanvasBox> canvasBoxes;
  final Manuscript manuscript;
  final List<InspectedFile> inspectedFiles;
  final String? exportDirectoryPath;
  final String? selectedProjectId;
  final String? selectedDatasetId;
  final DatasetSummary? importedSummary;

  AppSnapshot({
    required this.projects,
    required this.datasets,
    required this.papers,
    required this.hypotheses,
    required this.relations,
    this.analysisHistory = const [],
    this.canvasBoxes = const [],
    Manuscript? manuscript,
    this.inspectedFiles = const [],
    this.exportDirectoryPath,
    this.selectedProjectId,
    this.selectedDatasetId,
    this.importedSummary,
  }) : manuscript = manuscript ?? Manuscript();

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    return AppSnapshot(
      projects: (json['projects'] as List? ?? [])
          .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      datasets: (json['datasets'] as List? ?? [])
          .map((e) => Dataset.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      papers: (json['papers'] as List? ?? [])
          .map((e) => EvidencePaper.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      hypotheses: (json['hypotheses'] as List? ?? [])
          .map((e) => HypothesisNode.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      relations: (json['relations'] as List? ?? [])
          .map((e) => ResearchRelation.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      analysisHistory: (json['analysisHistory'] as List? ?? [])
          .map(
            (e) => AnalysisHistoryItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      canvasBoxes: (json['canvasBoxes'] as List? ?? [])
          .map((e) => CanvasBox.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      manuscript: json['manuscript'] == null
          ? Manuscript()
          : Manuscript.fromJson(
              Map<String, dynamic>.from(json['manuscript'] as Map),
            ),
      exportDirectoryPath: json['exportDirectoryPath'] as String?,
      selectedProjectId: json['selectedProjectId'] as String?,
      selectedDatasetId: json['selectedDatasetId'] as String?,
      importedSummary: json['importedSummary'] == null
          ? null
          : DatasetSummary.fromJson(
              Map<String, dynamic>.from(json['importedSummary'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projects': projects.map((e) => e.toJson()).toList(),
      'datasets': datasets.map((e) => e.toJson()).toList(),
      'papers': papers.map((e) => e.toJson()).toList(),
      'hypotheses': hypotheses.map((e) => e.toJson()).toList(),
      'relations': relations.map((e) => e.toJson()).toList(),
      'analysisHistory': analysisHistory.map((e) => e.toJson()).toList(),
      'canvasBoxes': canvasBoxes.map((e) => e.toJson()).toList(),
      'manuscript': manuscript.toJson(),
      'inspectedFiles': inspectedFiles.map((e) => e.toJson()).toList(),
      'exportDirectoryPath': exportDirectoryPath,
      'selectedProjectId': selectedProjectId,
      'selectedDatasetId': selectedDatasetId,
      'importedSummary': importedSummary?.toJson(),
    };
  }
}
