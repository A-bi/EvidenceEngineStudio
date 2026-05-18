import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/manuscript.dart';
import '../../models/manuscript_format.dart';
import '../../services/manuscript_export_service.dart';
import '../../services/export_library_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  late TextEditingController titleController;
  late TextEditingController authorsController;
  late TextEditingController affiliationController;
  late TextEditingController abstractController;
  late TextEditingController keywordsController;
  late TextEditingController journalController;
  late TextEditingController notesController;

  final Map<String, TextEditingController> sectionControllers = {};

  final formulaTitleController = TextEditingController();
  final formulaLatexController = TextEditingController();
  final formulaNoteController = TextEditingController();

  final figureTitleController = TextEditingController();
  final figureCaptionController = TextEditingController();
  final figurePathController = TextEditingController();

  final attachmentNameController = TextEditingController();
  final attachmentPathController = TextEditingController();
  final attachmentDescriptionController = TextEditingController();

  String activeInsertSection = 'results';

  @override
  void initState() {
    super.initState();

    final manuscript = context.read<AppState>().manuscript;

    titleController = TextEditingController(text: manuscript.title);
    authorsController = TextEditingController(text: manuscript.authors);
    affiliationController = TextEditingController(text: manuscript.affiliation);
    abstractController = TextEditingController(text: manuscript.abstractText);
    keywordsController = TextEditingController(text: manuscript.keywords);
    journalController = TextEditingController(text: manuscript.journalTarget);
    notesController = TextEditingController(text: manuscript.notes);

    for (final section in manuscript.sections) {
      sectionControllers[section.id] = TextEditingController(
        text: section.content,
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorsController.dispose();
    affiliationController.dispose();
    abstractController.dispose();
    keywordsController.dispose();
    journalController.dispose();
    notesController.dispose();

    formulaTitleController.dispose();
    formulaLatexController.dispose();
    formulaNoteController.dispose();

    figureTitleController.dispose();
    figureCaptionController.dispose();
    figurePathController.dispose();

    attachmentNameController.dispose();
    attachmentPathController.dispose();
    attachmentDescriptionController.dispose();

    for (final controller in sectionControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().ensureDefaultManuscriptSections();
    });
    final project = state.selectedProject;
    final dataset = state.selectedDataset;
    final papers = state.papersForProject(project?.id);
    final manuscript = state.manuscript;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Writing Studio',
            subtitle:
                'A structured manuscript cockpit with sections, formulas, references, figures, analyses and exports.',
          ),
          const SizedBox(height: 14),
          _topToolbar(context),
          const SizedBox(height: 16),
          _journalFormatPanel(state.manuscript),
          const SizedBox(height: 16),
          _insertPanel(),
          const SizedBox(height: 16),
          _contextCard(
            project?.title ?? 'No project selected',
            dataset?.name ?? 'No dataset selected',
            papers.length,
            state.analysisHistory.length,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1100) {
                return Column(
                  children: [
                    _leftEditor(manuscript),
                    const SizedBox(height: 16),
                    _rightTools(manuscript, papers),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _leftEditor(manuscript)),
                  const SizedBox(width: 16),
                  Expanded(child: _rightTools(manuscript, papers)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _topToolbar(BuildContext context) {
    final manuscript = context.watch<AppState>().manuscript;
    final format = manuscript.format;

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _toolbarButton(
            icon: Icons.save_rounded,
            label: 'Save',
            filled: true,
            onPressed: () {
              _saveAll(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
            },
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
            child: DropdownButtonFormField<String>(
              value: activeInsertSection,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Insert into',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
              items: manuscript.sections
                  .map(
                    (section) => DropdownMenuItem(
                      value: section.id,
                      child: Text(
                        section.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => activeInsertSection = value);
              },
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
            child: DropdownButtonFormField<ManuscriptPreset>(
              value: format.preset,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Journal preset',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
              items: ManuscriptPreset.values
                  .map(
                    (preset) => DropdownMenuItem(
                      value: preset,
                      child: Text(
                        preset.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                context.read<AppState>().applyManuscriptPreset(value);
              },
            ),
          ),
          _toolbarButton(
            icon: Icons.folder_open_rounded,
            label: 'Choose folder',
            onPressed: () async {
              final selected = await getDirectoryPath(
                confirmButtonText: 'Use this export folder',
              );

              if (selected == null) return;

              if (context.mounted) {
                context.read<AppState>().setExportDirectoryPath(selected);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export folder selected.')),
                );
              }
            },
          ),
          _toolbarButton(
            icon: Icons.description_rounded,
            label: 'MD',
            onPressed: () async {
              _saveAll(context);
              final file = await _exportMarkdown(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Markdown exported: ${file.uri.pathSegments.last}',
                    ),
                  ),
                );
              }
            },
          ),
          _toolbarButton(
            icon: Icons.article_rounded,
            label: 'TeX',
            onPressed: () async {
              _saveAll(context);
              final file = await _exportLatex(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'LaTeX exported: ${file.uri.pathSegments.last}',
                    ),
                  ),
                );
              }
            },
          ),
          _toolbarButton(
            icon: Icons.notes_rounded,
            label: 'TXT',
            onPressed: () async {
              _saveAll(context);
              final file = await _exportText(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'TXT exported: ${file.uri.pathSegments.last}',
                    ),
                  ),
                );
              }
            },
          ),
          _toolbarButton(
            icon: Icons.code_rounded,
            label: 'Rmd',
            onPressed: () async {
              _saveAll(context);
              final file = await _exportRMarkdown(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'RMarkdown exported: ${file.uri.pathSegments.last}',
                    ),
                  ),
                );
              }
            },
          ),
          _toolbarButton(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            onPressed: () async {
              _saveAll(context);
              try {
                final file = await _exportPdf(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'PDF exported: ${file.uri.pathSegments.last}',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF export failed: $error')),
                  );
                }
              }
            },
          ),
          _toolbarButton(
            icon: Icons.data_object_rounded,
            label: 'JSON',
            onPressed: () async {
              _saveAll(context);
              final file = await _exportReproJson(context);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Repro JSON exported: ${file.uri.pathSegments.last}',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final style = filled
        ? FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            visualDensity: VisualDensity.compact,
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            visualDensity: VisualDensity.compact,
          );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
    );

    if (filled) {
      return FilledButton(onPressed: onPressed, style: style, child: child);
    }

    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  Widget _journalFormatPanel(Manuscript manuscript) {
    final format = manuscript.format;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Journal / Export Format',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
                child: DropdownButtonFormField<ManuscriptPreset>(
                  value: format.preset,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Preset',
                  ),
                  items: ManuscriptPreset.values
                      .map(
                        (preset) => DropdownMenuItem(
                          value: preset,
                          child: Text(preset.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<AppState>().applyManuscriptPreset(value);
                  },
                ),
              ),
              _FormatChip('Font', format.fontFamily),
              _FormatChip('Size', '${format.fontSize.toStringAsFixed(0)} pt'),
              _FormatChip('Spacing', format.lineSpacing.toStringAsFixed(1)),
              _FormatChip('Citations', format.citationStyle),
              _FormatChip(
                'Line numbers',
                format.includeLineNumbers ? 'Yes' : 'No',
              ),
              _FormatChip('Title page', format.includeTitlePage ? 'Yes' : 'No'),
              _FormatChip(
                'Structured abstract',
                format.includeStructuredAbstract ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'These presets help with export formatting. Final submission formatting should still be checked against the current journal author guidelines.',
            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _insertPanel() {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insert',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _insertButton('Insert project question', () {
                final project = context.read<AppState>().selectedProject;
                if (project == null) return;
                _insertToActiveSection(
                  '**Research question:** ${project.question}',
                );
              }),
              _insertButton('Insert project notes', () {
                final project = context.read<AppState>().selectedProject;
                if (project == null) return;
                _insertToActiveSection(
                  '**Project notes:**\n\n${project.notes}',
                );
              }),
              _insertButton('Insert latest analysis', () {
                final result = context.read<AppState>().latestAnalysisResult;
                if (result == null) return;
                _insertToActiveSection(
                  '### ${result.analysis}\n\n${result.interpretation}',
                );
              }),
              _insertButton('Insert full results block', () {
                final result = context.read<AppState>().latestAnalysisResult;
                if (result == null) return;

                final metrics =
                    result.metrics?.entries
                        .map((e) => '- ${e.key}: ${e.value}')
                        .join('\n') ??
                    '';

                _insertToActiveSection(
                  '### ${result.analysis}\n\n'
                  '**Outcome:** ${result.outcome ?? '-'}\n\n'
                  '**Predictor / group:** ${result.predictor ?? result.group ?? '-'}\n\n'
                  '**N:** ${result.n}\n\n'
                  '**Interpretation:** ${result.interpretation}\n\n'
                  '**Metrics:**\n$metrics',
                );
              }),
              _insertButton('Insert linked paper titles', () {
                final state = context.read<AppState>();
                final project = state.selectedProject;
                final papers = state.papersForProject(project?.id);

                if (papers.isEmpty) return;

                final text = papers
                    .map(
                      (p) => '- ${p.title} (${p.year == 0 ? 'n.d.' : p.year})',
                    )
                    .join('\n');

                _insertToActiveSection(text);
              }),
              _insertButton('Insert structured abstract', () {
                abstractController.text =
                    'Background:\n\n'
                    'Objective:\n\n'
                    'Methods:\n\n'
                    'Results:\n\n'
                    'Conclusion:';
                _saveAll(context);
              }),
              _insertButton('Insert equation scaffold', () {
                _insertToActiveSection(
                  r'''$$
Y_i = \beta_0 + \beta_1 X_i + \varepsilon_i
$$

Where \(Y_i\) denotes the outcome, \(X_i\) the predictor and \(\varepsilon_i\) the residual error term.''',
                );
              }),
              _insertButton('Insert regression formula', () {
                _insertToActiveSection(
                  r'''$$
\hat{\beta} = (X^T X)^{-1} X^T y
$$

Linear regression was used to estimate the association between predictor variables and the continuous outcome.''',
                );
              }),
              _insertButton('Insert logistic model', () {
                _insertToActiveSection(r'''$$
\log \left(\frac{p}{1-p}\right) = \beta_0 + \beta_1 X_1 + \cdots + \beta_k X_k
$$

Logistic regression was used for binary outcome modelling.''');
              }),
              _insertButton('Insert hazard model', () {
                _insertToActiveSection(
                  r'''$$
h(t|X) = h_0(t) \exp(\beta^T X)
$$

A proportional hazards model was used to estimate time-to-event associations.''',
                );
              }),
              _insertButton('Insert methods scaffold', () {
                _insertToActiveSection('''### Study design

### Data source

### Participants / inclusion criteria

### Variables

### Statistical analysis

### Reproducibility''');
              }),
              _insertButton('Insert statistical analysis scaffold', () {
                _insertToActiveSection(
                  '''Continuous variables were summarized using means and standard deviations or medians and interquartile ranges, depending on distributional characteristics. Categorical variables were summarized as counts and percentages.

Group comparisons were performed using parametric or non-parametric tests as appropriate. Associations between variables were assessed using correlation analysis and regression modelling. Model performance was evaluated using appropriate discrimination and calibration metrics.

All analyses were performed reproducibly using the integrated analysis pipeline.''',
                );
              }),
              _insertButton('Import latest analysis figure', () {
                final result = context.read<AppState>().latestAnalysisResult;
                final path = result?.plotPath;
                if (path == null || path.isEmpty) return;

                context.read<AppState>().addFigure(
                  title: result?.analysis ?? 'Analysis figure',
                  caption: result?.interpretation ?? '',
                  path: path,
                );

                _insertToActiveSection(
                  '![${result?.analysis ?? 'Analysis figure'}]($path)\n\n'
                  '**Figure. ${result?.analysis ?? 'Analysis figure'}.** ${result?.interpretation ?? ''}',
                );
              }),
              _insertButton('Import figure / graph', () async {
                final file = await openFile();
                if (file == null) return;

                context.read<AppState>().addFigure(
                  title: file.name,
                  caption: '',
                  path: file.path,
                );

                _insertToActiveSection(
                  '![${file.name}](${file.path})\n\n'
                  '**Figure.** Caption to be added.',
                );
              }, filled: true),
              _insertButton('Import data attachment', () async {
                final file = await openFile();
                if (file == null) return;

                context.read<AppState>().addDataAttachment(
                  name: file.name,
                  path: file.path,
                  description: '',
                );

                _insertToActiveSection(
                  '**Data attachment:** ${file.name}\n\nPath: `${file.path}`',
                );
              }),
              _insertButton('Insert figure placeholder', () {
                _insertToActiveSection(
                  '''![Figure X](path/to/figure.png)

**Figure X. Title.** Detailed legend describing the plotted variables, sample size, statistical method and main interpretation.''',
                );
              }),
              _insertButton('Insert table placeholder', () {
                _insertToActiveSection(
                  '''| Variable | Group A | Group B | Effect size | p-value |
|---|---:|---:|---:|---:|
| Variable 1 |  |  |  |  |
| Variable 2 |  |  |  |  |

**Table X.** Summary of key variables and statistical comparisons.''',
                );
              }),
              _insertButton('Insert Nature figure legend scaffold', () {
                _insertToActiveSection(
                  '''**Figure X | Main title of the figure.**  
a, Description of panel a, including sample size, condition and measurement.  
b, Description of panel b, including statistical test and effect direction.  
c, Description of panel c and interpretation.  
Data are shown as mean ± s.e.m. unless otherwise stated. Statistical testing and exact n values are reported in the Methods.''',
                );
              }),
              _insertButton('Insert ethics/data availability', () {
                _insertToActiveSection('''### Ethics statement

This study was conducted in accordance with applicable ethical standards. Ethical approval and consent procedures should be described here.

### Data availability

The data sources, access conditions and restrictions should be described here.

### Code availability

Analysis code and reproducibility materials should be described here.''');
              }),
              _insertButton('Insert limitations scaffold', () {
                _insertToActiveSection(
                  '''Several limitations should be considered. First, ... Second, ... Third, ... Future work should validate these findings in independent cohorts and assess generalizability across settings.''',
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insertButton(
    String label,
    VoidCallback onPressed, {
    bool filled = false,
  }) {
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      ),
      child: Text(label),
    );
  }

  void _insertToActiveSection(String text) {
    context.read<AppState>().insertTextIntoSection(activeInsertSection, text);
    _syncControllersFromState();
  }

  Widget _contextCard(
    String projectTitle,
    String datasetName,
    int papers,
    int analyses,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Pill('Project', projectTitle),
          _Pill('Dataset', datasetName),
          _Pill('Papers', '$papers'),
          _Pill('Analyses', '$analyses'),
          _Pill(
            'Export folder',
            context.watch<AppState>().exportDirectoryPath == null
                ? 'Default'
                : 'Custom',
          ),
          _Pill('Insert target', activeInsertSection),
        ],
      ),
    );
  }

  Widget _leftEditor(Manuscript manuscript) {
    return Column(
      children: [
        _collapsiblePanel(
          title: 'Metadata',
          collapsed: manuscript.metadataCollapsed,
          onToggle: () =>
              context.read<AppState>().toggleManuscriptPanel('metadata'),
          child: _metadataCard(),
        ),
        const SizedBox(height: 16),
        ...manuscript.sections.map((section) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _sectionEditor(section),
          );
        }),
        _collapsiblePanel(
          title: 'Internal Notes',
          collapsed: false,
          onToggle: () {},
          child: TextField(
            controller: notesController,
            maxLines: 7,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  'Internal writing notes, reviewer thoughts, unresolved issues…',
            ),
            onChanged: (value) =>
                context.read<AppState>().updateManuscriptNotes(value),
          ),
        ),
      ],
    );
  }

  Widget _rightTools(Manuscript manuscript, List papers) {
    return Column(
      children: [
        _collapsiblePanel(
          title: 'References',
          collapsed: manuscript.referencesCollapsed,
          onToggle: () =>
              context.read<AppState>().toggleManuscriptPanel('references'),
          child: _referencesPanel(papers),
        ),
        const SizedBox(height: 16),
        _collapsiblePanel(
          title: 'Formulas',
          collapsed: manuscript.formulasCollapsed,
          onToggle: () =>
              context.read<AppState>().toggleManuscriptPanel('formulas'),
          child: _formulasPanel(manuscript),
        ),
        const SizedBox(height: 16),
        _collapsiblePanel(
          title: 'Figures',
          collapsed: manuscript.figuresCollapsed,
          onToggle: () =>
              context.read<AppState>().toggleManuscriptPanel('figures'),
          child: _figuresPanel(manuscript),
        ),
        const SizedBox(height: 16),
        _collapsiblePanel(
          title: 'Data Attachments',
          collapsed: manuscript.attachmentsCollapsed,
          onToggle: () =>
              context.read<AppState>().toggleManuscriptPanel('attachments'),
          child: _attachmentsPanel(manuscript),
        ),
        const SizedBox(height: 16),
        _collapsiblePanel(
          title: 'Analyses',
          collapsed: manuscript.analysesCollapsed,
          onToggle: () =>
              context.read<AppState>().toggleManuscriptPanel('analyses'),
          child: _analysesPanel(),
        ),
      ],
    );
  }

  Widget _collapsiblePanel({
    required String title,
    required bool collapsed,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.expand_more_rounded,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!collapsed) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }

  Widget _metadataCard() {
    return Column(
      children: [
        _textField('Title', titleController),
        const SizedBox(height: 12),
        _textField('Authors', authorsController),
        const SizedBox(height: 12),
        _textField('Affiliation', affiliationController),
        const SizedBox(height: 12),
        _textField('Target journal', journalController),
        const SizedBox(height: 12),
        _textField('Keywords', keywordsController),
        const SizedBox(height: 12),
        _textField('Structured Abstract', abstractController, maxLines: 7),
      ],
    );
  }

  Widget _sectionEditor(ManuscriptSection section) {
    final controller = sectionControllers.putIfAbsent(
      section.id,
      () => TextEditingController(text: section.content),
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                context.read<AppState>().toggleManuscriptSection(section.id),
            child: Row(
              children: [
                Icon(
                  section.collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.expand_more_rounded,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => activeInsertSection = section.id);
                  },
                  icon: const Icon(Icons.input_rounded),
                  label: const Text('Target'),
                ),
              ],
            ),
          ),
          if (!section.collapsed) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 12,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write Markdown / LaTeX style manuscript text here…',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                context.read<AppState>().updateManuscriptSection(
                  section.id,
                  value,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _formatPanel(Manuscript manuscript) {
    final format = manuscript.format;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Journal / Export Format',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ManuscriptPreset>(
            value: format.preset,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Preset',
            ),
            items: ManuscriptPreset.values
                .map(
                  (preset) => DropdownMenuItem(
                    value: preset,
                    child: Text(preset.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              context.read<AppState>().applyManuscriptPreset(value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FormatChip('Font', format.fontFamily),
              _FormatChip('Size', '${format.fontSize.toStringAsFixed(0)} pt'),
              _FormatChip('Spacing', format.lineSpacing.toStringAsFixed(1)),
              _FormatChip('Citations', format.citationStyle),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'These presets are export helpers. Final journal typography should still be checked against the current author guidelines.',
            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _referencesPanel(List papers) {
    final state = context.watch<AppState>();

    if (papers.isEmpty) {
      return const Text(
        'No linked papers yet. Import papers in Evidence.',
        style: TextStyle(color: AppTheme.secondaryText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: papers.map<Widget>((paper) {
        final key = state.citationKeyForPaper(paper);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.canvas.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${paper.authors ?? 'Unknown authors'} · ${paper.year == 0 ? 'n.d.' : paper.year}',
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedText),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _insertMarkdown('[@$key]'),
                    icon: const Icon(Icons.format_quote_rounded),
                    label: Text('Insert @$key'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final text =
                          '${paper.title} (${paper.year == 0 ? 'n.d.' : paper.year}). ${paper.summary} [@$key]';
                      context.read<AppState>().insertTextIntoSection(
                        activeInsertSection,
                        text,
                      );
                      _syncControllersFromState();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add summary'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _formulasPanel(Manuscript manuscript) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField('Formula title', formulaTitleController),
        const SizedBox(height: 8),
        _textField('LaTeX formula', formulaLatexController, maxLines: 4),
        const SizedBox(height: 8),
        _textField('Formula note', formulaNoteController, maxLines: 2),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () {
                final latex = formulaLatexController.text.trim();
                if (latex.isEmpty) return;

                context.read<AppState>().addFormula(
                  title: formulaTitleController.text.trim().isEmpty
                      ? 'Formula'
                      : formulaTitleController.text.trim(),
                  latex: latex,
                  note: formulaNoteController.text.trim(),
                );

                formulaTitleController.clear();
                formulaLatexController.clear();
                formulaNoteController.clear();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add formula'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                formulaLatexController.text =
                    r'\hat{\beta} = (X^T X)^{-1}X^T y';
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Regression template'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                formulaLatexController.text = r'HR(t) = h_1(t) / h_0(t)';
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Survival template'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (manuscript.formulas.isEmpty)
          const Text(
            'No formulas added yet.',
            style: TextStyle(color: AppTheme.secondaryText),
          )
        else
          ...manuscript.formulas.map(
            (formula) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.canvas.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formula.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    formula.latex,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  if (formula.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      formula.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<AppState>().insertTextIntoSection(
                            activeInsertSection,
                            r'$$'
                            '\n${formula.latex}\n'
                            r'$$',
                          );
                          _syncControllersFromState();
                        },
                        icon: const Icon(Icons.input_rounded),
                        label: const Text('Insert'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<AppState>().removeFormula(formula.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _figuresPanel(Manuscript manuscript) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField('Figure title', figureTitleController),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _textField('Figure path', figurePathController)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final file = await openFile();
                if (file == null) return;
                figurePathController.text = file.path;
              },
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Choose'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _textField('Caption', figureCaptionController, maxLines: 3),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            final path = figurePathController.text.trim();
            if (path.isEmpty) return;

            context.read<AppState>().addFigure(
              title: figureTitleController.text.trim().isEmpty
                  ? 'Figure'
                  : figureTitleController.text.trim(),
              caption: figureCaptionController.text.trim(),
              path: path,
            );

            figureTitleController.clear();
            figureCaptionController.clear();
            figurePathController.clear();
          },
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Add figure'),
        ),
        const SizedBox(height: 14),
        if (manuscript.figures.isEmpty)
          const Text(
            'No figures added yet.',
            style: TextStyle(color: AppTheme.secondaryText),
          )
        else
          ...manuscript.figures.map(
            (fig) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.canvas.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fig.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fig.caption,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fig.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  if (File(fig.path).existsSync()) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(fig.path),
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final text =
                              '![${fig.title}](${fig.path})\n\n**Figure. ${fig.title}.** ${fig.caption}';
                          context.read<AppState>().insertTextIntoSection(
                            activeInsertSection,
                            text,
                          );
                          _syncControllersFromState();
                        },
                        icon: const Icon(Icons.input_rounded),
                        label: const Text('Insert'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<AppState>().removeFigure(fig.id),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _attachmentsPanel(Manuscript manuscript) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField('Attachment name', attachmentNameController),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _textField('Path', attachmentPathController)),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final file = await openFile();
                if (file == null) return;
                attachmentPathController.text = file.path;
                if (attachmentNameController.text.trim().isEmpty) {
                  attachmentNameController.text = file.name;
                }
              },
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Choose'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _textField('Description', attachmentDescriptionController, maxLines: 3),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            final path = attachmentPathController.text.trim();
            if (path.isEmpty) return;

            context.read<AppState>().addDataAttachment(
              name: attachmentNameController.text.trim().isEmpty
                  ? 'Data attachment'
                  : attachmentNameController.text.trim(),
              path: path,
              description: attachmentDescriptionController.text.trim(),
            );

            attachmentNameController.clear();
            attachmentPathController.clear();
            attachmentDescriptionController.clear();
          },
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('Add attachment'),
        ),
        const SizedBox(height: 14),
        if (manuscript.dataAttachments.isEmpty)
          const Text(
            'No data attachments added yet.',
            style: TextStyle(color: AppTheme.secondaryText),
          )
        else
          ...manuscript.dataAttachments.map(
            (attachment) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.canvas.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attachment.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  if (attachment.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      attachment.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => context
                        .read<AppState>()
                        .removeDataAttachment(attachment.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _exportLibraryPanel() {
    return GlassCard(
      child: FutureBuilder<List<ExportFileItem>>(
        future: ExportLibraryService.instance.listExports(
          customPath: context.watch<AppState>().exportDirectoryPath,
        ),
        builder: (context, snapshot) {
          final files = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Export Library',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    onPressed: () async {
                      await ExportLibraryService.instance.openExportFolder(
                        customPath: context
                            .read<AppState>()
                            .exportDirectoryPath,
                      );
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    tooltip: 'Open export folder',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (files.isEmpty)
                const Text(
                  'No exports yet.',
                  style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                )
              else
                ...files
                    .take(12)
                    .map(
                      (file) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.canvas.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            _ExportIcon(extension: file.extension),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${ExportLibraryService.instance.humanSize(file.sizeBytes)} · ${file.modifiedAt.toLocal()}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ExportLibraryService.instance.openFile(
                                  file.path,
                                );
                              },
                              icon: const Icon(Icons.open_in_new_rounded),
                              tooltip: 'Open file',
                            ),
                            IconButton(
                              onPressed: () async {
                                await ExportLibraryService.instance
                                    .deleteExport(file.path);
                                setState(() {});
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Delete export',
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _analysesPanel() {
    final state = context.watch<AppState>();

    if (state.analysisHistory.isEmpty) {
      return const Text(
        'No analyses yet.',
        style: TextStyle(color: AppTheme.secondaryText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.analysisHistory.take(12).map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.canvas.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.method,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.summary,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AppState>().insertTextIntoSection(
                    activeInsertSection,
                    '### ${item.method}\n\n${item.summary}',
                  );
                  _syncControllersFromState();
                },
                icon: const Icon(Icons.input_rounded),
                label: const Text('Insert'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  void _insertMarkdown(String text) {
    context.read<AppState>().insertTextIntoSection(activeInsertSection, text);
    _syncControllersFromState();
  }

  void _saveAll(BuildContext context) {
    final state = context.read<AppState>();

    state.updateManuscriptMetadata(
      title: titleController.text,
      authors: authorsController.text,
      affiliation: affiliationController.text,
      abstractText: abstractController.text,
      keywords: keywordsController.text,
    );

    state.updateManuscriptJournalTarget(journalController.text);
    state.updateManuscriptNotes(notesController.text);

    for (final entry in sectionControllers.entries) {
      state.updateManuscriptSection(entry.key, entry.value.text);
    }
  }

  void _syncControllersFromState() {
    final manuscript = context.read<AppState>().manuscript;

    titleController.text = manuscript.title;
    authorsController.text = manuscript.authors;
    affiliationController.text = manuscript.affiliation;
    abstractController.text = manuscript.abstractText;
    keywordsController.text = manuscript.keywords;
    journalController.text = manuscript.journalTarget;
    notesController.text = manuscript.notes;

    for (final section in manuscript.sections) {
      final controller = sectionControllers.putIfAbsent(
        section.id,
        () => TextEditingController(),
      );
      controller.text = section.content;
    }

    setState(() {});
  }

  Future<File> _exportText(BuildContext context) {
    final state = context.read<AppState>();
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);

    return ManuscriptExportService.instance.exportText(
      manuscript: state.manuscript,
      project: project,
      dataset: state.selectedDataset,
      papers: papers,
      analyses: state.analysisHistory,
      exportDirectoryPath: state.exportDirectoryPath,
    );
  }

  Future<File> _exportRMarkdown(BuildContext context) {
    final state = context.read<AppState>();
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);

    return ManuscriptExportService.instance.exportRMarkdown(
      manuscript: state.manuscript,
      project: project,
      dataset: state.selectedDataset,
      papers: papers,
      analyses: state.analysisHistory,
      exportDirectoryPath: state.exportDirectoryPath,
    );
  }

  Future<File> _exportPdf(BuildContext context) {
    final state = context.read<AppState>();
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);

    return ManuscriptExportService.instance.exportPdf(
      manuscript: state.manuscript,
      project: project,
      dataset: state.selectedDataset,
      papers: papers,
      analyses: state.analysisHistory,
      exportDirectoryPath: state.exportDirectoryPath,
    );
  }

  Future<File> _exportMarkdown(BuildContext context) {
    final state = context.read<AppState>();
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);

    return ManuscriptExportService.instance.exportMarkdown(
      manuscript: state.manuscript,
      project: project,
      dataset: state.selectedDataset,
      papers: papers,
      analyses: state.analysisHistory,
      exportDirectoryPath: state.exportDirectoryPath,
    );
  }

  Future<File> _exportLatex(BuildContext context) {
    final state = context.read<AppState>();
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);

    return ManuscriptExportService.instance.exportLatex(
      manuscript: state.manuscript,
      project: project,
      dataset: state.selectedDataset,
      papers: papers,
      analyses: state.analysisHistory,
      exportDirectoryPath: state.exportDirectoryPath,
    );
  }

  Future<File> _exportReproJson(BuildContext context) {
    final state = context.read<AppState>();
    final project = state.selectedProject;
    final papers = state.papersForProject(project?.id);

    return ManuscriptExportService.instance.exportReproducibilityJson(
      manuscript: state.manuscript,
      project: project,
      dataset: state.selectedDataset,
      papers: papers,
      analyses: state.analysisHistory,
      exportDirectoryPath: state.exportDirectoryPath,
    );
  }
}

class _ExportIcon extends StatelessWidget {
  final String extension;

  const _ExportIcon({required this.extension});

  @override
  Widget build(BuildContext context) {
    final icon = switch (extension) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'tex' => Icons.article_rounded,
      'rmd' => Icons.code_rounded,
      'json' => Icons.data_object_rounded,
      'txt' => Icons.notes_rounded,
      'md' => Icons.description_rounded,
      _ => Icons.insert_drive_file_rounded,
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, size: 18, color: AppTheme.primaryText),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final String value;

  const _FormatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.selectedCard.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;

  const _Pill(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryText,
        ),
      ),
    );
  }
}
