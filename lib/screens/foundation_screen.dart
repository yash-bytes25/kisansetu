import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Foundation Screen for KisanSetu.
///
/// Serves as the verified, high-contrast entry placeholder confirming
/// the project architecture, Material 3 theme tokens, and team attribution.
class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KisanSetu'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SIH26032',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.agriculture_rounded,
                              size: 36,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KisanSetu',
                                  style: AppTextStyles.headlineMedium,
                                ),
                                Text(
                                  'किसान सेतु • Smart Procurement',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Project Foundation Established',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Architecture, theme tokens, and Material 3 design system are configured for mobile-first Android execution.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Architectural Highlights Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Design & Interaction Standards',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        icon: Icons.visibility_rounded,
                        title: 'RECOGNIZE → TAP → UNDERSTAND',
                        description:
                            'Visual-first cards, large touch targets, short labels, and minimal typing.',
                      ),
                      const SizedBox(height: 14),
                      _buildInfoItem(
                        icon: Icons.palette_outlined,
                        title: 'Agricultural Color Scheme',
                        description:
                            'Deep agricultural green (#1B5E20) on clean off-white (#F7F9F6) for outdoor readability.',
                      ),
                      const SizedBox(height: 14),
                      _buildInfoItem(
                        icon: Icons.group_work_outlined,
                        title: 'Application Roles (Upcoming)',
                        description:
                            'Dedicated experiences for Farmer and Procurement Officer.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Attribution Footer Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 20,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Team: ODE TO CODE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
