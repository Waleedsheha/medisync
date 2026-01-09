//lib/features/calculators/presentation/medicalc_detail_screen.dart
library;

/// Medicalc Calculator Detail Screen
/// Displays a single calculator with dynamic input form and results.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/presentation/glass_widgets.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';
import '../domain/calculators.dart';

class MedicalcDetailScreen extends StatefulWidget {
  final String calculatorId;

  const MedicalcDetailScreen({super.key, required this.calculatorId});

  @override
  State<MedicalcDetailScreen> createState() => _MedicalcDetailScreenState();
}

class _MedicalcDetailScreenState extends State<MedicalcDetailScreen> {
  late MedicalCalculator _calculator;
  final Map<String, dynamic> _inputs = {};
  final Map<String, TextEditingController> _controllers = {};
  CalculationResult? _result;

  @override
  void initState() {
    super.initState();
    _calculator =
        findCalculatorById(widget.calculatorId) ?? defaultCalculators().first;
    _initializeControllers();
    _initializeDefaults();
  }

  void _initializeControllers() {
    for (final spec in _calculator.inputSpecs) {
      if (spec.type is InputTypeInteger ||
          spec.type is InputTypeDecimal ||
          spec.type is InputTypeDate) {
        _controllers[spec.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeDefaults() {
    for (final spec in _calculator.inputSpecs) {
      if (spec.defaultValue != null) {
        _inputs[spec.key] = spec.defaultValue;
      } else if (spec.type is InputTypeOptions) {
        _inputs[spec.key] = (spec.type as InputTypeOptions).defaultIndex;
      } else if (spec.type is InputTypeCheckbox) {
        _inputs[spec.key] = false;
      }
    }
    _calculate();
  }

  void _updateInput(String key, dynamic value) {
    setState(() {
      _inputs[key] = value;
      _calculate();
    });
  }

  void _calculate() {
    setState(() {
      _result = _calculator.calculate(_inputs);
    });
  }

  void _clearInputs() {
    setState(() {
      // Clear all text controllers
      for (final controller in _controllers.values) {
        controller.clear();
      }
      // Clear inputs map
      _inputs.clear();
      // Re-initialize defaults
      _initializeDefaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _calculator.shortName,
      actions: [
        GlassIconButton(icon: LucideIcons.rotateCcw, onTap: _clearInputs),
        const SizedBox(width: 16),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            GlassContainer(
              width: double.infinity,
              isGlowing: true,
              glowColor: GlassTheme.neonBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _calculator.fullName,
                    style: GlassTheme.textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _calculator.description,
                    style: GlassTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Inputs Section
            Text(
              'Inputs',
              style: GlassTheme.textTheme.headlineMedium?.copyWith(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            ..._calculator.inputSpecs.map((spec) => _buildInputWidget(spec)),

            const SizedBox(height: 24),

            // Result Section
            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputWidget(InputSpec spec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: switch (spec.type) {
        InputTypeInteger() || InputTypeDecimal() => _buildNumberInput(spec),
        InputTypeOptions options => _buildOptionsInput(spec, options),
        InputTypeCheckbox() => _buildCheckboxInput(spec),
        InputTypeDate() => _buildNumberInput(spec), // Simplified for now
      },
    );
  }

  Widget _buildNumberInput(InputSpec spec) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(spec.label, style: GlassTheme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _controllers[spec.key],
              keyboardType: spec.type is InputTypeDecimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              style: GlassTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: GlassTheme.neonCyan,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: spec.placeholder ?? '',
                hintStyle: GlassTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white24,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                final parsed = spec.type is InputTypeDecimal
                    ? double.tryParse(value)
                    : int.tryParse(value);
                _updateInput(spec.key, parsed);
              },
            ),
          ),
          if (spec.unitHint != null)
            Text(
              spec.unitHint!,
              style: GlassTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionsInput(InputSpec spec, InputTypeOptions options) {
    final currentIndex = _inputs[spec.key] as int? ?? options.defaultIndex;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.label, style: GlassTheme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(options.entries.length, (index) {
              final isSelected = currentIndex == index;
              return GestureDetector(
                onTap: () => _updateInput(spec.key, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? GlassTheme.neonCyan.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? GlassTheme.neonCyan.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    options.entries[index],
                    style: GlassTheme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxInput(InputSpec spec) {
    final isChecked = _inputs[spec.key] as bool? ?? false;

    return GestureDetector(
      onTap: () => _updateInput(spec.key, !isChecked),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked
                    ? GlassTheme.neonCyan.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? GlassTheme.neonCyan : Colors.white38,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      LucideIcons.check,
                      color: GlassTheme.neonCyan,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                spec.label,
                style: GlassTheme.textTheme.bodyMedium?.copyWith(
                  color: isChecked ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _result!;
    final isError = result.isError;
    final isAwaiting = result.isAwaiting;

    // Determine colors based on state
    Color glowColor;
    Color iconColor;
    IconData iconData;
    String headerText;

    if (isError) {
      glowColor = Colors.red;
      iconColor = Colors.red;
      iconData = LucideIcons.alertTriangle;
      headerText = 'Error';
    } else if (isAwaiting) {
      glowColor = Colors.white54;
      iconColor = Colors.white70;
      iconData = LucideIcons.edit3;
      headerText = 'Awaiting Input';
    } else {
      glowColor = GlassTheme.neonCyan;
      iconColor = GlassTheme.neonCyan;
      iconData = LucideIcons.calculator;
      headerText = 'Result';
    }

    return GlassContainer(
      width: double.infinity,
      isGlowing: !isAwaiting,
      glowColor: glowColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Header
          Row(
            children: [
              Icon(iconData, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Text(
                headerText,
                style: GlassTheme.textTheme.headlineMedium?.copyWith(
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (isError)
            Text(
              result.error ?? 'Unknown error',
              style: GlassTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.red[300],
              ),
            )
          else if (isAwaiting)
            Text(
              result.awaitingMessage ?? 'Enter values to calculate',
              style: GlassTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            )
          else ...[
            // Main Value
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  result.value?.toStringAsFixed(
                        result.value! == result.value!.roundToDouble() ? 0 : 2,
                      ) ??
                      '--',
                  style: GlassTheme.textTheme.displayLarge?.copyWith(
                    fontSize: 48,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.unit != null && result.unit!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      result.unit!,
                      style: GlassTheme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white60,
                        fontSize: 18,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Interpretation
            if (result.interpretation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.interpretation!,
                  style: GlassTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),

            // Normal Range
            if (result.normalRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Normal: ${result.normalRange}',
                      style: GlassTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
