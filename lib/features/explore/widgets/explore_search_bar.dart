import 'package:flutter/material.dart';

class ExploreSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const ExploreSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
  });

  @override
  State<ExploreSearchBar> createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends State<ExploreSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.15),
            width: _isFocused ? 2 : 1,
          ),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search places, categories...',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _isFocused
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: colorScheme.onSurfaceVariant),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  ),
                if (widget.onFilterTap != null)
                  IconButton(
                    icon: Icon(
                      Icons.tune_rounded,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    onPressed: widget.onFilterTap,
                  ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
