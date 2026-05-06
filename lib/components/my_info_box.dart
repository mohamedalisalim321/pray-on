import 'package:flutter/material.dart';

import '../themes/theme_extensions.dart';

class MyInfoBox extends StatelessWidget {
  final String text;
  const MyInfoBox({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: context.radiusLG,
        color: theme.surface,
        border: Border.all(color: theme.primary),
      ),
      padding: context.paddingSM,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: theme.onSurface,
          ),
        ),
      ),
    );
  }
}
