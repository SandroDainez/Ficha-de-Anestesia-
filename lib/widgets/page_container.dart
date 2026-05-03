import 'package:flutter/material.dart';

import 'ui_tokens.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: UiLayout.pageMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
