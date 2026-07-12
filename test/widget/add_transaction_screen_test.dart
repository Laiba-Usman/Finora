import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finora/screens/transactions/add_transaction_screen.dart';
import 'package:finora/providers/auth_provider.dart';
import 'package:finora/providers/transaction_provider.dart';
import 'package:finora/providers/category_provider.dart';
import 'package:finora/providers/budget_provider.dart';

void main() {
  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: const MaterialApp(
        home: AddTransactionScreen(),
      ),
    );
  }

  testWidgets('AddTransactionScreen form elements render successfully', (WidgetTester tester) async {
    // Pump the screen
    await tester.pumpWidget(createTestWidget());

    // Verify Expense Choice Chip is selected by default
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Verify key fields are present
    expect(find.byIcon(Icons.attach_money), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);

    // Verify Save Button is present
    expect(find.text('Save Transaction'), findsOneWidget);
  });
}
