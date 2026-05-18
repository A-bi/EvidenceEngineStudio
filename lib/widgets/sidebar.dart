import 'package:flutter/material.dart';
import '../models/app_section.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class Sidebar extends StatelessWidget {
  final AppSection selectedSection;
  final ValueChanged<AppSection> onSelected;

  const Sidebar({
    super.key,
    required this.selectedSection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandHeader(),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: AppSection.values.map((section) {
                final selected = section == selectedSection;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onSelected(section),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.selectedCard
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppTheme.borderStrong
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section.icon,
                            size: 20,
                            color: selected
                                ? AppTheme.primaryText
                                : Colors.white.withOpacity(0.72),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            section.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppTheme.primaryText
                                  : Colors.white.withOpacity(0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'One workspace',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'From hypothesis to manuscript.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Build, test, critique, and write in one calm research environment.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/branding/evidence_engine_128x128.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EvidenceEngine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Studio',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Local-first scientific workspace',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
