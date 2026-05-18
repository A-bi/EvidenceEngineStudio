import 'package:flutter/material.dart';

enum AppSection {
  home,
  projects,
  evidence,
  data,
  analysis,
  hypotheses,
  writing,
  critique,
  exports,
  settings,
}

extension AppSectionInfo on AppSection {
  String get label {
    switch (this) {
      case AppSection.home:
        return 'Home';
      case AppSection.projects:
        return 'Projects';
      case AppSection.evidence:
        return 'Evidence';
      case AppSection.data:
        return 'Data';
      case AppSection.analysis:
        return 'Analysis';
      case AppSection.hypotheses:
        return 'Hypotheses';
      case AppSection.writing:
        return 'Writing';
      case AppSection.critique:
        return 'Critique';
      case AppSection.exports:
        return 'Exports';
      case AppSection.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppSection.home:
        return Icons.home_rounded;
      case AppSection.projects:
        return Icons.folder_rounded;
      case AppSection.evidence:
        return Icons.menu_book_rounded;
      case AppSection.data:
        return Icons.table_chart_rounded;
      case AppSection.analysis:
        return Icons.monitor_heart_rounded;
      case AppSection.hypotheses:
        return Icons.account_tree_rounded;
      case AppSection.writing:
        return Icons.edit_square;
      case AppSection.critique:
        return Icons.feedback_rounded;
      case AppSection.exports:
        return Icons.ios_share_rounded;
      case AppSection.settings:
        return Icons.settings_rounded;
    }
  }
}
