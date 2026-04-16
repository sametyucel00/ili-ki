import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iliski_kocu_ai/shared/models/analysis_record.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.description,
    this.buttonText,
    this.onPressed,
    super.key,
  });

  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PrimaryCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.message,
    required this.onRetry,
    this.title = 'Bir sorun oluştu',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: title,
      description: message,
      buttonText: 'Tekrar dene',
      onPressed: onRetry,
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class AnalysisListTile extends StatelessWidget {
  const AnalysisListTile({required this.item, super.key});

  final AnalysisRecord item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(item.aiSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormat('d MMM, HH:mm', 'tr_TR').format(item.createdAt)),
      trailing: Icon(item.isFavorite ? Icons.favorite_rounded : Icons.chevron_right_rounded),
      onTap: () => context.push('/detail/${item.id}'),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return PrimaryCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class SelectionChipGroup extends StatelessWidget {
  const SelectionChipGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.helperText,
    super.key,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options
              .map(
                (option) => ChoiceChip(
                  label: Text(option),
                  selected: option == value,
                  onSelected: (_) => onChanged(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
