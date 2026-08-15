import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/controllers/google_drive_sync_controller.dart';
import 'package:admincraft/main.dart';
import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/views/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    Size size, {
    bool withServer = true,
    Map<String, Object> extraPrefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues({
      if (withServer) 'onboardingCompleted': true,
      ...extraPrefs,
    });
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
          ChangeNotifierProvider(
            create: (_) => GoogleDriveSyncController(prefs),
          ),
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
    expect(find.text('Google Drive sync'), findsNothing);
    expect(tester.widget<Image>(find.byType(Image).first).width, 32);
    expect(
      tester.widget<Text>(find.text('Admincraft')).style?.fontWeight,
      FontWeight.w700,
    );

    await tester.tap(find.text('Data & Sync'));
    await tester.pumpAndSettle();

    expect(find.text('Google Drive sync'), findsOneWidget);
    expect(find.text('Setup required'), findsOneWidget);
    expect(find.text('Back up and transfer application data'), findsOneWidget);
    expect(find.text('Bedrock Edition'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    expect(find.text('Data & Sync'), findsWidgets);
    expect(find.text('Google Drive sync'), findsOneWidget);
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
    await tester.tap(find.text('Settings'));
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

  testWidgets('onboarding replaces the workspace until a server is configured',
      (tester) async {
    await pumpApp(tester, const Size(390, 844), withServer: false);

    expect(find.text('Welcome to Admincraft'), findsOneWidget);
    expect(find.text('Add your first server'), findsOneWidget);
    // The workspace must not be reachable behind it.
    expect(find.text('Console'), findsNothing);
    expect(find.text('Controls'), findsNothing);

    await tester.tap(find.text('Add your first server'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeView), findsNothing);
    // The editor itself, not merely the absence of onboarding: landing on
    // Overview instead was a real bug that a weaker assertion hid.
    expect(find.text('Edit server'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding still allows reaching preferences', (tester) async {
    await pumpApp(tester, const Size(390, 844), withServer: false);

    expect(find.text('Welcome to Admincraft'), findsOneWidget);

    // Appearance settings have nothing to do with owning a server, so the
    // welcome screen must not be a dead end for them.
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeView), findsNothing);
    expect(find.text('Preferences'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme picker stays one row until it is expanded',
      (tester) async {
    await pumpApp(tester, const Size(1280, 720));
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();

    final tiles = find.byWidgetPredicate((widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('app-theme-'));

    final collapsed = tester.widgetList(tiles).length;
    expect(collapsed, lessThan(AppTheme.values.length));

    // Hard against the right edge of the tiles below it. Flexible plus a
    // Spacer put it halfway across the card, because both default to flex 1
    // and split the free space.
    final toggleRight =
        tester.getRect(find.byKey(const ValueKey('theme-expand-toggle'))).right;
    final tilesRight = tester.getRect(tiles.last).right;
    expect((toggleRight - tilesRight).abs(), lessThan(1));

    await tester.tap(find.byKey(const ValueKey('theme-expand-toggle')));
    await tester.pumpAndSettle();
    expect(tester.widgetList(tiles).length, AppTheme.values.length);

    // A theme from a hidden row stays on screen once chosen, or collapsing
    // would leave the picker showing no selection at all.
    await tester.tap(find.byKey(const ValueKey('app-theme-enderman')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-expand-toggle')));
    await tester.pumpAndSettle();

    expect(tester.widgetList(tiles).length, collapsed);
    expect(find.byKey(const ValueKey('app-theme-enderman')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the welcome logo follows the chosen theme', (tester) async {
    // Someone who changes theme during setup should see it there too: the
    // welcome screen used to show a fixed copy of the dirt logo.
    await pumpApp(
      tester,
      const Size(390, 844),
      withServer: false,
      extraPrefs: {'appTheme': 'creeper'},
    );

    expect(find.byType(WelcomeView), findsOneWidget);
    final logo = tester.widget<Image>(
      find.descendant(of: find.byType(WelcomeView), matching: find.byType(Image)),
    );
    expect((logo.image as AssetImage).assetName,
        'docs/logo/variants/creeper.png');
    expect(logo.width, 96);
    expect(logo.filterQuality, FilterQuality.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the app title opens preferences', (tester) async {
    await pumpApp(tester, const Size(1280, 720));

    await tester.tap(find.byKey(const ValueKey('app-title')));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'These settings apply to Admincraft on this device, not to one server.'),
      findsOneWidget,
    );
    // Mojang's usage guidelines ask for this wording, so it should not be able
    // to disappear in a refactor of the About card.
    expect(
      find.text('NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR '
          'ASSOCIATED WITH MOJANG OR MICROSOFT.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
