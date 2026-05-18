import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/evidence_paper.dart';
import '../../models/literature_search_result.dart';
import '../../services/evidence_engine_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class EvidenceScreen extends StatefulWidget {
  const EvidenceScreen({super.key});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  final TextEditingController queryController = TextEditingController();
  bool isSearching = false;
  String? errorMessage;
  List<LiteratureSearchResult> results = [];

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final project = state.selectedProject;
    final linkedPapers = state.papersForProject(project?.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Evidence Dock',
            subtitle:
                'Search scientific literature, import papers, and keep sources linked to the current project.',
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current project',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  project?.title ?? 'No project selected',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                if (project != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    project.question,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _searchCard(),
          const SizedBox(height: 20),
          if (errorMessage != null)
            GlassCard(
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          if (results.isNotEmpty) ...[
            if (errorMessage != null) const SizedBox(height: 20),
            _resultsCard(),
            const SizedBox(height: 20),
          ],
          _linkedPapersCard(linkedPapers),
        ],
      ),
    );
  }

  Widget _searchCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search literature',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: queryController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. amyloidosis CIDP neuropathy diagnostic differentiation',
            ),
            onSubmitted: (_) => _runSearch(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: isSearching ? null : _runSearch,
                icon: isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: Text(isSearching ? 'Searching…' : 'Search EvidenceEngine'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final state = context.read<AppState>();
                  final project = state.selectedProject;
                  if (project == null) return;

                  queryController.text = project.question;
                },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Use project question'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search results (${results.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          ...results.map(
            (paper) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SearchResultTile(result: paper),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedPapersCard(List<EvidencePaper> linkedPapers) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linked papers (${linkedPapers.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          if (linkedPapers.isEmpty)
            const Text(
              'No papers linked to this project yet.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryText,
              ),
            )
          else
            ...linkedPapers.map(
              (paper) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _LinkedPaperTile(paper: paper),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _runSearch() async {
    final query = queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      errorMessage = null;
      results = [];
    });

    try {
      final found = await EvidenceEngineService.instance.searchRemotePapers(query);

      setState(() {
        results = found;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Search failed: $error';
      });
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }
}

class _SearchResultTile extends StatelessWidget {
  final LiteratureSearchResult result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final alreadyImported = state.papers.any((paper) {
      final sameDoi = paper.doi != null &&
          result.doi != null &&
          paper.doi!.toLowerCase() == result.doi!.toLowerCase();

      final sameTitle = paper.title.toLowerCase() == result.title.toLowerCase();

      return sameDoi || sameTitle;
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.canvas.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${result.authors.isEmpty ? 'Unknown authors' : result.authors} · ${result.journal} · ${result.year == 0 ? 'n.d.' : result.year}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
          if (result.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: alreadyImported
                    ? null
                    : () async {
                        await context
                            .read<AppState>()
                            .importLiteratureResult(result);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Paper imported.')),
                          );
                        }
                      },
                icon: const Icon(Icons.add_rounded),
                label: Text(alreadyImported ? 'Imported' : 'Import'),
              ),
              if (result.url != null && result.url!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openUrl(result.url!),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
              if (result.doi != null && result.doi!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openUrl('https://doi.org/${result.doi!}'),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('DOI'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkedPaperTile extends StatelessWidget {
  final EvidencePaper paper;

  const _LinkedPaperTile({required this.paper});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.selectedCard.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paper.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${paper.authors ?? 'Unknown authors'} · ${paper.journal} · ${paper.year == 0 ? 'n.d.' : paper.year}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
          if (paper.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              paper.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (paper.url != null && paper.url!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openUrl(paper.url!),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
              if (paper.doi != null && paper.doi!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openUrl('https://doi.org/${paper.doi!}'),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('DOI'),
                ),
              TextButton.icon(
                onPressed: () {
                  context.read<AppState>().removeEvidencePaper(paper);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
