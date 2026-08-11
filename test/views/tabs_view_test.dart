import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/main.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => Model(PersistenceService(prefs)),
          ),
          ChangeNotifierProvider(create: (_) => ConnectionController()),
        ],
        child: const Admincraft(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop workspace renders without layout errors',
      (tester) async {
    await pumpApp(tester, const Size(1280, 720));

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Data & Sync'), findsOneWidget);
    expect(find.text('Configuration'), findsOneWidget);
    expect(find.text('Docs'), findsOneWidget);
    expect(find.text('Automatic cloud sync'), findsNothing);
    expect(tester.widget<Image>(find.byType(Image).first).width, 32);
    expect(
      tester.widget<Text>(find.text('Admincraft')).style?.fontWeight,
      FontWeight.w700,
    );

    await tester.tap(find.text('Data & Sync'));
    await tester.pumpAndSettle();

    expect(find.text('Automatic cloud sync'), findsOneWidget);
    expect(find.text('Back up and transfer application data'), findsOneWidget);
    expect(find.text('Bedrock Edition'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    expect(find.text('Data & Sync'), findsWidgets);
    expect(find.text('Automatic cloud sync'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('color theme changes the palette and pixel-art logo',
      (tester) async {
    await pumpApp(tester, const Size(1280, 720));

    final initialContext = tester.element(find.text('Admincraft'));
    final initialPrimary = Theme.of(initialContext).colorScheme.primary;
    final initialLogo = tester.widget<Image>(find.byType(Image).first);
    expect(
      (initialLogo.image as AssetImage).assetName,
      'docs/logo/variants/dirt.png',
    );

    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app-theme-diamond')));
    await tester.pumpAndSettle();

    final themedContext = tester.element(find.text('Admincraft'));
    final themedLogo = tester.widget<Image>(find.byType(Image).first);
    expect(Theme.of(themedContext).colorScheme.primary, isNot(initialPrimary));
    expect(
      (themedLogo.image as AssetImage).assetName,
      'docs/logo/variants/diamond.png',
    );
    expect(themedLogo.width, 32);
    expect(themedLogo.fit, BoxFit.fill);
    expect(themedLogo.filterQuality, FilterQuality.none);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appTheme'), 'diamond');
    expect(tester.takeException(), isNull);
  });

  testWidgets('server switcher exposes add server as its final action',
      (tester) async {
    await pumpApp(tester, const Size(390, 844));

    await tester.tap(find.byTooltip('Switch server'));
    await tester.pumpAndSettle();

    expect(find.text('Add server'), findsOneWidget);
    expect(find.text('Create a new server profile'), findsOneWidget);

    await tester.tap(find.text('Add server'));
    await tester.pumpAndSettle();

    expect(find.text('Edit server'), findsWidgets);
    expect(find.text('Save changes'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Save changes')).dy,
      lessThan(tester.getTopLeft(find.text('Danger zone')).dy),
    );

    final aliasField = find.widgetWithText(TextFormField, 'Alias');
    await tester.enterText(aliasField, 'Unsaved draft');
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Docs'), findsOneWidget);
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Edit server'));
    await tester.tap(find.byTooltip('Edit server'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(aliasField).controller?.text,
      'Unsaved draft',
    );

    await tester.tap(find.byTooltip('Back to Servers'));
    await tester.pumpAndSettle();
    expect(find.text('Servers'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
