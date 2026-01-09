import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'ai_assistant/presentation/ai_chat_view.dart';
import '../core/widgets/app_scaffold.dart';
import '../core/presentation/glass_widgets.dart';
import 'drugs/presentation/drug_library_screen.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Assistant',
      showBottomNavBar: true,
      body: const AiChatView(isFullScreen: true),
    );
  }
}

/// Drug Helper Screen - Now uses the full Drug Library
class DrugHelperScreen extends StatelessWidget {
  const DrugHelperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrugLibraryScreen();
  }
}

class MedicalcScreen extends StatelessWidget {
  const MedicalcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Medicalc',
      body: Center(
        child: GlassContainer(
          width: 280,
          height: 280,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          isGlowing: true,
          glowColor: GlassTheme.neonBlue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.calculator,
                size: 64,
                color: GlassTheme.neonBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Medicalc',
                style: GlassTheme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Clinical calculators & scores',
                style: GlassTheme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfusionsScreen extends StatelessWidget {
  const InfusionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Infusions',
      showBottomNavBar: true,
      body: Center(
        child: GlassContainer(
          width: 280,
          height: 280,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.droplets, size: 64, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Infusions',
                style: GlassTheme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Drip rates & concentration tools',
                style: GlassTheme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
