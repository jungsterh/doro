import 'package:flutter/material.dart';
import '../../../widgets/glass_card.dart';

class CommentInput extends StatefulWidget {
  final TextEditingController controller;
  final String? hint;

  const CommentInput({
    super.key,
    required this.controller,
    this.hint,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderColor: _focused
          ? accent.withValues(alpha: 0.6)
          : null,
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        child: TextField(
          controller: widget.controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                widget.hint ?? 'Add a note about this session...',
            border: InputBorder.none,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
                ),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
