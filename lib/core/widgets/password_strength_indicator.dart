import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/password_strength_provider.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    this.showSuggestions = true,
    this.showCriteria = false,
    this.compact = false,
  });

  final bool showSuggestions;
  final bool showCriteria;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordStrengthProvider>(
      builder:
          (
            BuildContext context,
            PasswordStrengthProvider provider,
            Widget? child,
          ) {
            if (provider.result.message == 'Enter a password') {
              return const SizedBox.shrink();
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildProgressBar(context, provider),
                  const SizedBox(height: 8),
                  _buildStrengthMessage(context, provider),
                  if (showSuggestions && provider.suggestions.isNotEmpty && !compact) ...<Widget>[
                    const SizedBox(height: 8),
                    _buildSuggestions(context, provider),
                  ],
                  if (showCriteria && !compact) ...<Widget>[
                    const SizedBox(height: 8),
                    _buildCriteria(context, provider),
                  ],
                ],
              ),
            );
          },
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    PasswordStrengthProvider provider,
  ) {
    const double barHeight = 4;
    const double spacing = 2;

    return Row(
      children: <Widget>[
        for (int i = 0; i < 4; i++) ...<Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: barHeight,
              decoration: BoxDecoration(
                color: i < provider.progressLevel
                    ? provider.progressColors[i < provider.progressColors.length
                          ? i
                          : provider.progressColors.length - 1]
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: spacing),
        ],
      ],
    );
  }

  Widget _buildStrengthMessage(
    BuildContext context,
    PasswordStrengthProvider provider,
  ) {
    return Row(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: provider.strengthColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: provider.strengthColor,
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
          child: Text(provider.message),
        ),
        const Spacer(),
        if (!compact)
          Text(
            '${(provider.score * 100).round()}%',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestions(
    BuildContext context,
    PasswordStrengthProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Suggestions:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...provider.suggestions
              .take(3)
              .map(
                (String suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
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

  Widget _buildCriteria(
    BuildContext context,
    PasswordStrengthProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.checklist,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Requirements:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCriteriaItem('8+ characters', provider.criteria.hasMinLength),
          _buildCriteriaItem(
            'Uppercase letter',
            provider.criteria.hasUppercase,
          ),
          _buildCriteriaItem(
            'Lowercase letter',
            provider.criteria.hasLowercase,
          ),
          _buildCriteriaItem('Number', provider.criteria.hasNumbers),
          _buildCriteriaItem(
            'Special character',
            provider.criteria.hasSpecialChars,
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: met ? Colors.green.shade700 : Colors.grey.shade600,
                decoration: met ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
