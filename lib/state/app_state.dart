import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/analysis_result.dart';
import '../models/analysis_history_item.dart';
import '../models/app_snapshot.dart';
import '../models/project.dart';
import '../models/dataset.dart';
import '../models/dataset_summary.dart';
import '../models/evidence_paper.dart';
import '../models/hypothesis_node.dart';
import '../models/literature_search_result.dart';
import '../models/research_relation.dart';
import '../models/research_node.dart';
import '../models/canvas_box.dart';
import '../models/manuscript.dart';
import '../models/manuscript_format.dart';
import '../models/inspected_file.dart';
import '../services/app_persistence_service.dart';
import '../services/dataset_import_service.dart';
import '../services/analysis_service.dart';
import '../services/python_analysis_service.dart';
import '../services/bibtex_service.dart';

class AppState extends ChangeNotifier {
  final List<Project> projects = [];
  final List<Dataset> datasets = [];
  final List<EvidencePaper> papers = [];
  final List<HypothesisNode> hypotheses = [];
  final List<ResearchRelation> relations = [];
  final List<AnalysisHistoryItem> analysisHistory = [];
  final List<CanvasBox> canvasBoxes = [];

  AnalysisResult? latestAnalysisResult;
  Manuscript manuscript = Manuscript();
  final List<InspectedFile> inspectedFiles = [];

  String? selectedProjectId;
  String? exportDirectoryPath;
  String? selectedDatasetId;
  DatasetSummary? importedSummary;

  bool isLoaded = false;
  Timer? _saveDebounce;

  AppState() {
    _loadOrSeed();
  }

  Project? get selectedProject {
    if (projects.isEmpty) return null;
    if (selectedProjectId == null) return projects.first;
    return projects.firstWhere(
      (project) => project.id == selectedProjectId,
      orElse: () => projects.first,
    );
  }

  Dataset? get selectedDataset {
    if (datasets.isEmpty) return null;
    if (selectedDatasetId == null) return datasets.first;
    return datasets.firstWhere(
      (dataset) => dataset.id == selectedDatasetId,
      orElse: () => datasets.first,
    );
  }

  List<HypothesisNode> hypothesesForProject(String? projectId) {
    if (projectId == null) return hypotheses;
    return hypotheses.where((h) => h.projectId == projectId).toList();
  }

  List<EvidencePaper> papersForProject(String? projectId) {
    if (projectId == null) return papers;
    return papers.where((p) => p.projectId == projectId).toList();
  }

  List<ResearchNode> researchNodesForSelectedProject() {
    final project = selectedProject;

    if (project == null) return [];

    final projectHypotheses = hypothesesForProject(project.id);
    final projectPapers = papersForProject(project.id);
    final dataset = selectedDataset;

    final nodes = <ResearchNode>[
      ResearchNode(
        id: project.id,
        kind: ResearchNodeKind.project,
        title: project.title,
        subtitle: project.question,
        x: 0.50,
        y: 0.14,
      ),
    ];

    if (dataset != null) {
      nodes.add(
        ResearchNode(
          id: dataset.id,
          kind: ResearchNodeKind.dataset,
          title: dataset.name,
          subtitle: '${dataset.rows} rows · ${dataset.columns} columns',
          x: 0.18,
          y: 0.45,
        ),
      );
    }

    for (var i = 0; i < projectHypotheses.length; i++) {
      final h = projectHypotheses[i];
      final spread = projectHypotheses.length <= 1
          ? 0.0
          : (i / (projectHypotheses.length - 1) - 0.5);
      nodes.add(
        ResearchNode(
          id: h.id,
          kind: ResearchNodeKind.hypothesis,
          title: h.title,
          subtitle: '${h.status} · ${h.evidenceStrength}',
          x: 0.50 + spread * 0.42,
          y: 0.48,
        ),
      );
    }

    for (var i = 0; i < projectPapers.take(8).length; i++) {
      final paper = projectPapers[i];
      final count = projectPapers.take(8).length;
      final spread = count <= 1 ? 0.0 : (i / (count - 1) - 0.5);
      nodes.add(
        ResearchNode(
          id: paper.id,
          kind: ResearchNodeKind.paper,
          title: paper.title,
          subtitle: '${paper.journal} · ${paper.year}',
          x: 0.50 + spread * 0.70,
          y: 0.74,
        ),
      );
    }

    for (var i = 0; i < analysisHistory.take(5).length; i++) {
      final item = analysisHistory[i];
      nodes.add(
        ResearchNode(
          id: item.id,
          kind: ResearchNodeKind.analysis,
          title: item.method,
          subtitle: item.outcome,
          x: 0.82,
          y: 0.38 + i * 0.09,
        ),
      );
    }

    for (final box in canvasBoxes) {
      nodes.add(
        ResearchNode(
          id: box.id,
          kind: box.kind,
          title: box.title,
          subtitle: box.subtitle,
          x: box.x,
          y: box.y,
          colorHex: box.colorHex,
        ),
      );
    }

    return nodes;
  }

  void addCanvasBox({
    required String title,
    required String subtitle,
    required ResearchNodeKind kind,
    required String colorHex,
  }) {
    final box = CanvasBox(
      title: title,
      subtitle: subtitle,
      kind: kind,
      x: 0.50,
      y: 0.50,
      colorHex: colorHex,
    );

    canvasBoxes.add(box);
    _changed();
  }

  void updateCanvasBoxPosition(String id, double x, double y) {
    final index = canvasBoxes.indexWhere((box) => box.id == id);
    if (index == -1) return;

    canvasBoxes[index].x = x.clamp(0.05, 0.95);
    canvasBoxes[index].y = y.clamp(0.06, 0.94);
    _changed();
  }

  void updateCanvasBoxColor(String id, String colorHex) {
    final index = canvasBoxes.indexWhere((box) => box.id == id);
    if (index == -1) return;

    canvasBoxes[index].colorHex = colorHex;
    _changed();
  }

  void removeCanvasBox(String id) {
    canvasBoxes.removeWhere((box) => box.id == id);
    relations.removeWhere(
      (relation) => relation.sourceId == id || relation.targetId == id,
    );
    _changed();
  }

  void connectNodes(
    String sourceId,
    String targetId,
    ResearchRelationKind kind,
  ) {
    if (sourceId == targetId) return;

    final exists = relations.any(
      (relation) =>
          relation.sourceId == sourceId &&
          relation.targetId == targetId &&
          relation.kind == kind,
    );

    if (exists) return;

    relations.insert(
      0,
      ResearchRelation(sourceId: sourceId, targetId: targetId, kind: kind),
    );

    _changed();
  }

  List<ResearchRelation> relationsForSelectedProjectGraph() {
    final nodes = researchNodesForSelectedProject();
    final nodeIds = nodes.map((node) => node.id).toSet();

    final existing = relations
        .where(
          (relation) =>
              nodeIds.contains(relation.sourceId) &&
              nodeIds.contains(relation.targetId),
        )
        .toList();

    final project = selectedProject;
    final dataset = selectedDataset;

    if (project == null) return existing;

    final auto = <ResearchRelation>[];

    if (dataset != null && nodeIds.contains(dataset.id)) {
      auto.add(
        ResearchRelation(
          sourceId: project.id,
          targetId: dataset.id,
          kind: ResearchRelationKind.basedOn,
        ),
      );
    }

    for (final h in hypothesesForProject(project.id)) {
      if (nodeIds.contains(h.id)) {
        auto.add(
          ResearchRelation(
            sourceId: project.id,
            targetId: h.id,
            kind: ResearchRelationKind.linkedTo,
          ),
        );
      }
    }

    for (final paper in papersForProject(project.id).take(8)) {
      if (nodeIds.contains(paper.id)) {
        auto.add(
          ResearchRelation(
            sourceId: project.id,
            targetId: paper.id,
            kind: ResearchRelationKind.linkedTo,
          ),
        );
      }
    }

    for (final item in analysisHistory.take(5)) {
      if (dataset != null &&
          nodeIds.contains(item.id) &&
          nodeIds.contains(dataset.id)) {
        auto.add(
          ResearchRelation(
            sourceId: dataset.id,
            targetId: item.id,
            kind: ResearchRelationKind.testedBy,
          ),
        );
      }
    }

    final merged = <ResearchRelation>[];
    final seen = <String>{};

    for (final relation in [...existing, ...auto]) {
      final key =
          '${relation.sourceId}-${relation.targetId}-${relation.kind.rawValue}';
      if (seen.add(key)) {
        merged.add(relation);
      }
    }

    return merged;
  }

  Future<void> importLiteratureResult(LiteratureSearchResult result) async {
    final project = selectedProject;

    final alreadyExists = papers.any((paper) {
      final sameDoi =
          paper.doi != null &&
          result.doi != null &&
          paper.doi!.toLowerCase() == result.doi!.toLowerCase();

      final sameUrl =
          paper.url != null &&
          result.url != null &&
          paper.url!.toLowerCase() == result.url!.toLowerCase();

      final sameTitle = paper.title.toLowerCase() == result.title.toLowerCase();

      return sameDoi || sameUrl || sameTitle;
    });

    if (alreadyExists) {
      return;
    }

    final paper = EvidencePaper(
      title: result.title,
      journal: result.journal,
      year: result.year,
      summary: result.summary,
      authors: result.authors,
      doi: result.doi,
      url: result.url,
      projectId: project?.id,
    );

    papers.insert(0, paper);

    if (project != null) {
      relations.insert(
        0,
        ResearchRelation(
          sourceId: project.id,
          targetId: paper.id,
          kind: ResearchRelationKind.linkedTo,
        ),
      );

      project.evidenceCount += 1;
    }

    final bib = BibTeXService.instance.makeBibTeXEntry(
      title: result.title,
      authors: result.authors,
      journal: result.journal,
      year: result.year,
      doi: result.doi,
      url: result.url,
    );

    await BibTeXService.instance.appendEntry(
      bib.entry,
      projectName: project?.title,
    );

    _changed();
  }

  void removeEvidencePaper(EvidencePaper paper) {
    papers.removeWhere((p) => p.id == paper.id);
    relations.removeWhere(
      (relation) =>
          relation.sourceId == paper.id || relation.targetId == paper.id,
    );

    final pid = paper.projectId;
    if (pid != null) {
      final index = projects.indexWhere((project) => project.id == pid);
      if (index != -1 && projects[index].evidenceCount > 0) {
        projects[index].evidenceCount -= 1;
      }
    }

    _changed();
  }

  Future<void> _loadOrSeed() async {
    final snapshot = await AppPersistenceService.instance.load();

    if (snapshot != null && snapshot.projects.isNotEmpty) {
      projects
        ..clear()
        ..addAll(snapshot.projects);
      datasets
        ..clear()
        ..addAll(snapshot.datasets);
      papers
        ..clear()
        ..addAll(snapshot.papers);
      hypotheses
        ..clear()
        ..addAll(snapshot.hypotheses);
      relations
        ..clear()
        ..addAll(snapshot.relations);
      analysisHistory
        ..clear()
        ..addAll(snapshot.analysisHistory);
      canvasBoxes
        ..clear()
        ..addAll(snapshot.canvasBoxes);
      manuscript = snapshot.manuscript;
      inspectedFiles
        ..clear()
        ..addAll(snapshot.inspectedFiles);

      selectedProjectId = snapshot.selectedProjectId;
      exportDirectoryPath = snapshot.exportDirectoryPath;
      selectedDatasetId = snapshot.selectedDatasetId;
      importedSummary = snapshot.importedSummary;
    } else {
      _seedDemoData();
      await saveNow();
    }

    isLoaded = true;
    notifyListeners();
  }

  AppSnapshot snapshot() {
    return AppSnapshot(
      projects: List<Project>.from(projects),
      datasets: List<Dataset>.from(datasets),
      papers: List<EvidencePaper>.from(papers),
      hypotheses: List<HypothesisNode>.from(hypotheses),
      relations: List<ResearchRelation>.from(relations),
      analysisHistory: List<AnalysisHistoryItem>.from(analysisHistory),
      canvasBoxes: List<CanvasBox>.from(canvasBoxes),
      manuscript: manuscript,
      inspectedFiles: List<InspectedFile>.from(inspectedFiles),
      exportDirectoryPath: exportDirectoryPath,
      selectedProjectId: selectedProjectId,
      selectedDatasetId: selectedDatasetId,
      importedSummary: importedSummary,
    );
  }

  Future<void> saveNow() async {
    await AppPersistenceService.instance.save(snapshot());
  }

  void _changed() {
    notifyListeners();

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), () {
      saveNow();
    });
  }

  Future<void> resetPersistedState() async {
    await AppPersistenceService.instance.reset();

    projects.clear();
    datasets.clear();
    papers.clear();
    hypotheses.clear();
    relations.clear();
    analysisHistory.clear();
    canvasBoxes.clear();
    latestAnalysisResult = null;
    manuscript = Manuscript();
    inspectedFiles.clear();

    selectedProjectId = null;
    selectedDatasetId = null;
    importedSummary = null;

    _seedDemoData();
    await saveNow();

    notifyListeners();
  }

  void selectProject(Project project) {
    selectedProjectId = project.id;
    _changed();
  }

  void selectDataset(Dataset dataset) {
    selectedDatasetId = dataset.id;
    _changed();
  }

  void addDemoDataset() {
    final dataset = Dataset(
      name: 'Imported demo dataset',
      rows: 120,
      columns: 6,
      source: 'CSV',
      filePath: '/demo/imported_dataset.csv',
    );

    datasets.insert(0, dataset);
    selectedDatasetId = dataset.id;

    importedSummary = DatasetSummary(
      file: dataset.filePath,
      rows: dataset.rows,
      columns: dataset.columns,
      columnNames: [
        'age',
        'group',
        'score',
        'diagnosis',
        'biomarker',
        'outcome',
      ],
      variableTypes: {
        'age': 'numeric_continuous',
        'group': 'categorical',
        'score': 'numeric_continuous',
        'diagnosis': 'categorical',
        'biomarker': 'numeric_continuous',
        'outcome': 'boolean',
      },
      missingCounts: {
        'age': 0,
        'group': 0,
        'score': 3,
        'diagnosis': 1,
        'biomarker': 5,
        'outcome': 0,
      },
      preview: [
        {
          'age': 62,
          'group': 'A',
          'score': 27.4,
          'diagnosis': 'MCI',
          'biomarker': 1.42,
          'outcome': true,
        },
        {
          'age': 71,
          'group': 'B',
          'score': 21.8,
          'diagnosis': 'AD',
          'biomarker': 2.13,
          'outcome': false,
        },
        {
          'age': 58,
          'group': 'A',
          'score': 30.1,
          'diagnosis': 'Control',
          'biomarker': 0.87,
          'outcome': true,
        },
      ],
    );

    _changed();
  }

  Future<void> importDataset(String path) async {
    final result = await DatasetImportService.instance.importDataset(path);

    datasets.insert(0, result.dataset);
    selectedDatasetId = result.dataset.id;
    importedSummary = result.summary;

    _changed();
  }

  Future<void> runAnalysis({
    required AnalysisMethod method,
    required String outcome,
    String? predictor,
    String? group,
  }) async {
    final dataset = selectedDataset;

    if (dataset?.filePath == null || dataset!.filePath!.isEmpty) {
      final summary = importedSummary;
      if (summary == null) return;

      final result = AnalysisService.instance.run(
        method: method,
        summary: summary,
        outcome: outcome,
        predictor: predictor,
        group: group,
      );

      latestAnalysisResult = result;
      analysisHistory.insert(
        0,
        AnalysisHistoryItem(
          method: result.analysis,
          datasetName: dataset?.name ?? 'Preview dataset',
          outcome: result.outcome ?? '',
          secondaryVariable: result.predictor ?? result.group ?? '',
          summary: result.interpretation,
        ),
      );

      _changed();
      return;
    }

    final result = await PythonAnalysisService.instance.run(
      filePath: dataset.filePath!,
      method: method,
      outcome: outcome,
      predictor: predictor,
      group: group,
    );

    latestAnalysisResult = result;

    analysisHistory.insert(
      0,
      AnalysisHistoryItem(
        method: result.analysis,
        datasetName: dataset.name,
        outcome: result.outcome ?? '',
        secondaryVariable: result.predictor ?? result.group ?? '',
        summary: result.interpretation,
      ),
    );

    _changed();
  }

  void removeDataset(Dataset dataset) {
    datasets.removeWhere((d) => d.id == dataset.id);

    if (selectedDatasetId == dataset.id) {
      selectedDatasetId = datasets.isNotEmpty ? datasets.first.id : null;
      if (datasets.isEmpty) {
        importedSummary = null;
      }
    }

    _changed();
  }

  void updateProjectNotes(String projectId, String notes) {
    final index = projects.indexWhere((p) => p.id == projectId);
    if (index == -1) return;
    projects[index].notes = notes;
    _changed();
  }

  void addHypothesis({
    required String title,
    String evidenceStrength = 'Open',
    String status = 'Open',
  }) {
    final project = selectedProject;
    if (project == null) return;

    final node = HypothesisNode(
      projectId: project.id,
      title: title,
      evidenceStrength: evidenceStrength,
      status: status,
    );

    hypotheses.insert(0, node);
    relations.insert(
      0,
      ResearchRelation(
        sourceId: project.id,
        targetId: node.id,
        kind: ResearchRelationKind.linkedTo,
      ),
    );

    project.hypothesisCount += 1;
    _changed();
  }

  void deleteHypothesis(HypothesisNode hypothesis) {
    hypotheses.removeWhere((h) => h.id == hypothesis.id);
    relations.removeWhere(
      (r) => r.sourceId == hypothesis.id || r.targetId == hypothesis.id,
    );

    final index = projects.indexWhere((p) => p.id == hypothesis.projectId);
    if (index != -1 && projects[index].hypothesisCount > 0) {
      projects[index].hypothesisCount -= 1;
    }

    _changed();
  }

  void removeProject(Project project) {
    final hypothesisIds = hypotheses
        .where((h) => h.projectId == project.id)
        .map((h) => h.id)
        .toSet();

    final paperIds = papers
        .where((p) => p.projectId == project.id)
        .map((p) => p.id)
        .toSet();

    final relatedIds = <String>{project.id, ...hypothesisIds, ...paperIds};

    projects.removeWhere((p) => p.id == project.id);
    hypotheses.removeWhere((h) => h.projectId == project.id);
    papers.removeWhere((p) => p.projectId == project.id);

    relations.removeWhere(
      (r) => relatedIds.contains(r.sourceId) || relatedIds.contains(r.targetId),
    );

    selectedProjectId = projects.isNotEmpty ? projects.first.id : null;
    exportDirectoryPath = null;
    _changed();
  }

  void _seedDemoData() {
    final projectA = Project(
      title: 'Dementia',
      question: 'Can dementia be predicted?',
      status: 'Active',
      datasetCount: 2,
      evidenceCount: 18,
      hypothesisCount: 2,
      notes: 'Neurology',
    );

    final projectB = Project(
      title: 'Neurodegeneration',
      question:
          'Which features differentiate different types of neurodegeneration?',
      status: 'Draft',
      datasetCount: 1,
      evidenceCount: 27,
      hypothesisCount: 2,
      notes:
          'Clinical differentiation, structured features, high-sensitivity screening logic.',
    );

    final datasetA = Dataset(
      name: 'MoCA merged',
      rows: 12483,
      columns: 32,
      source: 'CSV',
    );

    final datasetB = Dataset(
      name: 'BDI',
      rows: 214,
      columns: 46,
      source: 'Excel',
    );

    final paperA = EvidencePaper(
      title: 'Quantumphysics in microtubules',
      journal: 'Journal of Biophysics',
      year: 2025,
      summary:
          'Supports multimodal physiological predictors for short-term state changes.',
      authors: 'A. Example et al.',
      url: 'https://evidenceengine.eu',
      projectId: projectA.id,
    );

    final paperB = EvidencePaper(
      title:
          'Lifestyle intervention leads to less probability of dementia in population',
      journal: 'Dementia Research',
      year: 2024,
      summary:
          'Discusses discriminative features, confounders, and diagnostic overlap.',
      authors: 'B. Example et al.',
      url: 'https://evidenceengine.eu',
      projectId: projectB.id,
    );

    final hypothesisA1 = HypothesisNode(
      projectId: projectA.id,
      title: 'Dementia leads to loss of memory',
      evidenceStrength: 'Moderate',
      status: 'Active',
    );

    final hypothesisA2 = HypothesisNode(
      projectId: projectA.id,
      title: 'Age may confound the effect',
      evidenceStrength: 'Open',
      status: 'Open',
    );

    final hypothesisB1 = HypothesisNode(
      projectId: projectB.id,
      title: 'Involvement of lifestyle',
      evidenceStrength: 'Emerging',
      status: 'Open',
    );

    final hypothesisB2 = HypothesisNode(
      projectId: projectB.id,
      title: 'Questionnaire-derived features increase discrimination',
      evidenceStrength: 'Moderate',
      status: 'Active',
    );

    projects.addAll([projectA, projectB]);
    datasets.addAll([datasetA, datasetB]);
    papers.addAll([paperA, paperB]);
    hypotheses.addAll([hypothesisA1, hypothesisA2, hypothesisB1, hypothesisB2]);

    selectedProjectId = projectA.id;
    selectedDatasetId = datasetA.id;

    relations.addAll([
      ResearchRelation(
        sourceId: projectA.id,
        targetId: hypothesisA1.id,
        kind: ResearchRelationKind.linkedTo,
      ),
      ResearchRelation(
        sourceId: projectA.id,
        targetId: hypothesisA2.id,
        kind: ResearchRelationKind.linkedTo,
      ),
      ResearchRelation(
        sourceId: projectA.id,
        targetId: paperA.id,
        kind: ResearchRelationKind.linkedTo,
      ),
      ResearchRelation(
        sourceId: projectA.id,
        targetId: datasetA.id,
        kind: ResearchRelationKind.basedOn,
      ),
      ResearchRelation(
        sourceId: paperA.id,
        targetId: hypothesisA1.id,
        kind: ResearchRelationKind.supports,
      ),
      ResearchRelation(
        sourceId: projectB.id,
        targetId: hypothesisB1.id,
        kind: ResearchRelationKind.linkedTo,
      ),
      ResearchRelation(
        sourceId: projectB.id,
        targetId: hypothesisB2.id,
        kind: ResearchRelationKind.linkedTo,
      ),
      ResearchRelation(
        sourceId: projectB.id,
        targetId: paperB.id,
        kind: ResearchRelationKind.linkedTo,
      ),
      ResearchRelation(
        sourceId: projectB.id,
        targetId: datasetB.id,
        kind: ResearchRelationKind.basedOn,
      ),
      ResearchRelation(
        sourceId: paperB.id,
        targetId: hypothesisB1.id,
        kind: ResearchRelationKind.open,
      ),
    ]);
  }


  void addInspectedFile(InspectedFile file) {
    inspectedFiles.removeWhere((item) => item.path == file.path);
    inspectedFiles.insert(0, file);
    _changed();
  }

  void removeInspectedFile(String id) {
    inspectedFiles.removeWhere((file) => file.id == id);
    _changed();
  }

  void attachInspectedFileToManuscript(InspectedFile file) {
    addDataAttachment(
      name: file.name,
      path: file.path,
      description: 'Attached from File Inspector as ${file.role}.',
    );
  }

  void insertInspectedFileReference(InspectedFile file, String sectionId) {
    insertTextIntoSection(
      sectionId,
      '**Attached file:** ${file.name}\n\nType: ${file.role}',
    );
  }

  void setExportDirectoryPath(String? path) {
    exportDirectoryPath = path;
    _changed();
  }

  void applyManuscriptPreset(ManuscriptPreset preset) {
    manuscript.format.applyPreset(preset);
    _changed();
  }

  void updateManuscriptFormat({
    required String fontFamily,
    required double fontSize,
    required double lineSpacing,
    required String citationStyle,
    required bool includeLineNumbers,
    required bool includeTitlePage,
    required bool includeStructuredAbstract,
    required bool includeWordCount,
  }) {
    manuscript.format.fontFamily = fontFamily;
    manuscript.format.fontSize = fontSize;
    manuscript.format.lineSpacing = lineSpacing;
    manuscript.format.citationStyle = citationStyle;
    manuscript.format.includeLineNumbers = includeLineNumbers;
    manuscript.format.includeTitlePage = includeTitlePage;
    manuscript.format.includeStructuredAbstract = includeStructuredAbstract;
    manuscript.format.includeWordCount = includeWordCount;
    manuscript.format.preset = ManuscriptPreset.custom;
    _changed();
  }

  void updateManuscriptMetadata({
    required String title,
    required String authors,
    required String affiliation,
    required String abstractText,
    required String keywords,
  }) {
    manuscript.title = title;
    manuscript.authors = authors;
    manuscript.affiliation = affiliation;
    manuscript.abstractText = abstractText;
    manuscript.keywords = keywords;
    _changed();
  }

  void ensureDefaultManuscriptSections() {
    final existingIds = manuscript.sections
        .map((section) => section.id)
        .toSet();

    for (final section in Manuscript.defaultSections()) {
      if (!existingIds.contains(section.id)) {
        manuscript.sections.add(section);
      }
    }

    _changed();
  }

  void updateManuscriptSection(String sectionId, String content) {
    final index = manuscript.sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (index == -1) return;

    manuscript.sections[index].content = content;
    _changed();
  }

  void toggleManuscriptPanel(String panel) {
    switch (panel) {
      case 'metadata':
        manuscript.metadataCollapsed = !manuscript.metadataCollapsed;
        break;
      case 'references':
        manuscript.referencesCollapsed = !manuscript.referencesCollapsed;
        break;
      case 'formulas':
        manuscript.formulasCollapsed = !manuscript.formulasCollapsed;
        break;
      case 'figures':
        manuscript.figuresCollapsed = !manuscript.figuresCollapsed;
        break;
      case 'attachments':
        manuscript.attachmentsCollapsed = !manuscript.attachmentsCollapsed;
        break;
      case 'analyses':
        manuscript.analysesCollapsed = !manuscript.analysesCollapsed;
        break;
    }

    _changed();
  }

  void toggleManuscriptSection(String sectionId) {
    final index = manuscript.sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (index == -1) return;

    manuscript.sections[index].collapsed =
        !manuscript.sections[index].collapsed;
    _changed();
  }

  void updateManuscriptNotes(String notes) {
    manuscript.notes = notes;
    _changed();
  }

  void updateManuscriptJournalTarget(String journalTarget) {
    manuscript.journalTarget = journalTarget;
    _changed();
  }

  void insertTextIntoSection(String sectionId, String textToInsert) {
    final index = manuscript.sections.indexWhere(
      (section) => section.id == sectionId,
    );
    if (index == -1) return;

    final current = manuscript.sections[index].content.trim();
    manuscript.sections[index].content = current.isEmpty
        ? textToInsert.trim()
        : '$current\n\n${textToInsert.trim()}';

    _changed();
  }

  void addFormula({
    required String title,
    required String latex,
    String note = '',
  }) {
    manuscript.formulas.insert(
      0,
      ManuscriptFormula(title: title, latex: latex, note: note),
    );

    _changed();
  }

  void removeFormula(String id) {
    manuscript.formulas.removeWhere((formula) => formula.id == id);
    _changed();
  }

  void addFigure({
    required String title,
    required String caption,
    required String path,
    String note = '',
  }) {
    manuscript.figures.insert(
      0,
      ManuscriptFigure(title: title, caption: caption, path: path, note: note),
    );

    _changed();
  }

  void removeFigure(String id) {
    manuscript.figures.removeWhere((figure) => figure.id == id);
    _changed();
  }

  void addDataAttachment({
    required String name,
    required String path,
    String description = '',
  }) {
    manuscript.dataAttachments.insert(
      0,
      ManuscriptDataAttachment(
        name: name,
        path: path,
        description: description,
      ),
    );

    _changed();
  }

  void removeDataAttachment(String id) {
    manuscript.dataAttachments.removeWhere((attachment) => attachment.id == id);
    _changed();
  }

  String citationKeyForPaper(EvidencePaper paper) {
    final year = paper.year == 0 ? 'nd' : paper.year.toString();
    final author = (paper.authors ?? 'paper')
        .split(RegExp(r'[, ]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .firstOrNull;

    return '${author ?? 'paper'}$year';
  }

  void insertAnalysisIntoResults() {
    final result = latestAnalysisResult;
    if (result == null) return;

    final section = manuscript.sections.firstWhere(
      (section) => section.id == 'results',
      orElse: () => manuscript.sections.first,
    );

    final metrics =
        result.metrics?.entries
            .map((entry) => '- ${entry.key}: ${entry.value}')
            .join('\n') ??
        '';

    final text =
        '''
### ${result.analysis}

${result.interpretation}

${metrics.isNotEmpty ? metrics : ''}
''';

    section.content = section.content.trim().isEmpty
        ? text.trim()
        : '${section.content.trim()}\n\n${text.trim()}';

    _changed();
  }

  void insertEvidenceIntoIntroduction() {
    final project = selectedProject;
    if (project == null) return;

    final linked = papersForProject(project.id);
    if (linked.isEmpty) return;

    final section = manuscript.sections.firstWhere(
      (section) => section.id == 'introduction',
      orElse: () => manuscript.sections.first,
    );

    final citations = linked
        .take(5)
        .map((paper) {
          final year = paper.year == 0 ? 'n.d.' : paper.year.toString();
          return '- ${paper.title} (${year}). ${paper.summary}';
        })
        .join('\n');

    final text =
        '''
Current evidence linked to this project includes:

$citations
''';

    section.content = section.content.trim().isEmpty
        ? text.trim()
        : '${section.content.trim()}\n\n${text.trim()}';

    _changed();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}
