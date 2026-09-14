import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:controle_atendimento_app/core/widgets/loading_view.dart';

void main() {
  testWidgets('LoadingView exibe um indicador de progresso', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoadingView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
