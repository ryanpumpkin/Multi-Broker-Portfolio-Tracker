import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/presentation/widgets/empty_state.dart';
import 'package:multi_broker_portfolio/presentation/widgets/error_banner.dart';

import 'presentation_test_harness.dart';

void main() {
  testWidgets('ErrorBanner shows retry and invokes callback', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: ErrorBanner(
            error: StateError('network failed'),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.textContaining('network failed'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('EmptyState renders message and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrapForTest(
        Scaffold(
          body: EmptyState(
            title: 'Nothing here',
            message: 'Create your first item',
            action: FilledButton(
              onPressed: () => tapped = true,
              child: const Text('Create'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Create your first item'), findsOneWidget);
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
