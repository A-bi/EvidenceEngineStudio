import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/export_library_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class ExportCenterScreen extends StatefulWidget {
  const ExportCenterScreen({super.key});

  @override
  State<ExportCenterScreen> createState() => _ExportCenterScreenState();
}

class _ExportCenterScreenState extends State<ExportCenterScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final exportPath = context.watch<AppState>().exportDirectoryPath;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            'Export Center',
            subtitle:
                'Manage manuscript exports, reproducibility files, PDFs, RMarkdown, LaTeX and text outputs.',
          ),
          const SizedBox(height: 20),
          _exportFolderCard(exportPath),
          const SizedBox(height: 20),
          _filterBar(),
          const SizedBox(height: 20),
          _exportList(exportPath),
        ],
      ),
    );
  }

  Widget _exportFolderCard(String? exportPath) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active export location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            exportPath == null
                ? 'Default export folder'
                : 'Custom export folder selected',
            style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () async {
                  final selected = await getDirectoryPath(
                    confirmButtonText: 'Use this export folder',
                  );

                  if (selected == null) return;

                  if (mounted) {
                    context.read<AppState>().setExportDirectoryPath(selected);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export folder selected.')),
                    );
                  }
                },
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Choose folder'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await ExportLibraryService.instance.openExportFolder(
                    customPath: context.read<AppState>().exportDirectoryPath,
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open folder'),
              ),
              OutlinedButton.icon(
                onPressed: exportPath == null
                    ? null
                    : () {
                        context.read<AppState>().setExportDirectoryPath(null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Export folder reset to default.'),
                          ),
                        );
                      },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterChip('all', 'All'),
          _filterChip('pdf', 'PDF'),
          _filterChip('md', 'Markdown'),
          _filterChip('rmd', 'Rmd'),
          _filterChip('tex', 'TeX'),
          _filterChip('txt', 'TXT'),
          _filterChip('json', 'JSON'),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = filter == value;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() => filter = value);
      },
    );
  }

  Widget _exportList(String? exportPath) {
    return FutureBuilder<List<ExportFileItem>>(
      future: ExportLibraryService.instance.listExports(customPath: exportPath),
      builder: (context, snapshot) {
        final allFiles = snapshot.data ?? [];

        final files = filter == 'all'
            ? allFiles
            : allFiles.where((file) => file.extension == filter).toList();

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Exported files',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator()
              else if (files.isEmpty)
                const Text(
                  'No exports found for this filter.',
                  style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                )
              else
                ...files.map((file) => _ExportFileTile(file: file)),
            ],
          ),
        );
      },
    );
  }
}

class _ExportFileTile extends StatelessWidget {
  final ExportFileItem file;

  const _ExportFileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
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
              await ExportLibraryService.instance.openFile(file.path);
            },
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open file',
          ),
          IconButton(
            onPressed: () async {
              await ExportLibraryService.instance.deleteExport(file.path);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${file.name} deleted.')),
                );
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
          ),
        ],
      ),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Icon(icon, size: 20, color: AppTheme.primaryText),
    );
  }
}
