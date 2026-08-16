import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/controllers/google_drive_sync_controller.dart';
import 'package:admincraft/controllers/notification_controller.dart';
import 'dart:convert';

import 'package:admincraft/main.dart';
import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/services/connection_service.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/views/welcome_view.dart';
import 'package:flutter/foundation.dart';
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
    ConnectionService? connectionService,
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
          ChangeNotifierProvider(
            create: (_) =>
                ConnectionController(connectionService: connectionService),
          ),
          ChangeNotifierProvider(
            create: (_) => GoogleDriveSyncController(prefs),
          ),
          ChangeNotifierProvider(create: (_) => NotificationController(prefs)),
        ],
        child: const Admincraft(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desktop workspace renders without layout errors', (
    tester,
  ) async {
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
    final quickTransferCard = find
        .ancestor(of: find.text('Quick transfer'), matching: find.byType(Card))
        .first;
    final backupFileCard = find
        .ancestor(of: find.text('Backup file'), matching: find.byType(Card))
        .first;
    final driveSyncCard = find
        .ancestor(
          of: find.text('Google Drive sync'),
          matching: find.byType(Card),
        )
        .first;
    expect(tester.getSize(quickTransferCard).width, 350);
    expect(
      tester.getSize(backupFileCard).width,
      tester.getSize(driveSyncCard).width,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('color theme changes the palette and pixel-art logo', (
    tester,
  ) async {
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

  testWidgets('server switcher exposes add server as its final action', (
    tester,
  ) async {
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

    expect(tester.takeException(), isNull);
  });

  testWidgets('unsaved server changes guard back and tab navigation', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pumpApp(
      tester,
      const Size(390, 844),
      connectionService: _NoopConnectionService(),
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit server'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Alias'),
      'Saved before leaving',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Private address of the bridge'),
      '127.0.0.1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bridge secret key'),
      'test-key',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save server changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Edit server'), findsWidgets);

    await tester.tap(find.text('Console'));
    await tester.pumpAndSettle();
    expect(find.text('Save server changes?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save changes'),
      ),
    );
    // Saving reports connection and save notifications whose progress
    // indicators intentionally keep scheduling frames; bounded pumps cover
    // the dialog exit, persistence, and navigation without waiting out every
    // banner.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Connect to enable the Terminal.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final stored = (prefs.getStringList('servers') ?? const [])
        .map((server) => ServerProfile.fromJson(jsonDecode(server)))
        .single;
    expect(stored.alias, 'Saved before leaving');
    await tester.pump(const Duration(seconds: 3));
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid guarded save highlights fields and can be discarded', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Size(390, 844),
      connectionService: _NoopConnectionService(),
    );
    ToastUtils.initialize(
      tester.element(find.byType(Admincraft)).read<NotificationController>(),
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit server'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Alias'), '');
    await tester.tap(find.text('Console'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Discard changes'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save changes'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save changes'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Edit server'), findsWidgets);
    expect(find.text('Enter a name for this server.'), findsOneWidget);
    expect(find.text('Enter the server host.'), findsOneWidget);
    expect(find.text('Enter the bridge secret key.'), findsOneWidget);
    expect(
      find.text('Complete the highlighted server fields before saving.'),
      findsOneWidget,
    );

    ToastUtils.dismissPopups();
    await tester.pump();
    await tester.tap(find.text('Console'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();

    expect(find.text('Connect to enable the Terminal.'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit server'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'Alias'))
          .controller
          ?.text,
      'My World',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a server keeps the server list open', (tester) async {
    const first = ServerProfile(
      id: 'first',
      alias: 'First server',
      ip: '',
      port: 8080,
      secretKey: '',
      certificate: '',
      security: ConnectionSecurity.privateNetwork,
    );
    const second = ServerProfile(
      id: 'second',
      alias: 'Second server',
      ip: '',
      port: 8080,
      secretKey: '',
      certificate: '',
      security: ConnectionSecurity.privateNetwork,
    );
    await pumpApp(
      tester,
      const Size(390, 844),
      extraPrefs: {
        'servers': [jsonEncode(first.toJson()), jsonEncode(second.toJson())],
        'selectedServer': first.id,
      },
      connectionService: _NoopConnectionService(),
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second server'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose a server or create another profile.'),
      findsOneWidget,
    );
    expect(find.text('Players'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selectedServer'), second.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile header is concise and does not repeat the app logo', (
    tester,
  ) async {
    await pumpApp(tester, const Size(390, 844));

    final appLogos = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/logo.png',
    );
    expect(appLogos, findsNothing);
    expect(find.textContaining('The current state of'), findsNothing);
    expect(find.byTooltip('Notification history'), findsOneWidget);
    expect(
      tester
          .getTopRight(
            find.descendant(
              of: find.byKey(const ValueKey('mobile-connection-action')),
              matching: find.byType(IconButton),
            ),
          )
          .dx,
      382,
    );
    final navigation = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('mobile-bottom-navigation')),
    );
    final navigationColor = (navigation.decoration as BoxDecoration).color;
    final pageColor = Theme.of(
      tester.element(find.byKey(const ValueKey('mobile-bottom-navigation'))),
    ).scaffoldBackgroundColor;
    expect(navigationColor, isNot(pageColor));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'onboarding replaces the workspace until a server is configured',
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
    },
  );

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

  testWidgets('onboarding does not trap mobile users on the welcome screen', (
    tester,
  ) async {
    await pumpApp(tester, const Size(390, 844), withServer: false);

    // Mobile has no sidebar, so the app bar's back arrow is the only way out
    // of these pages. It used to land on a destination the onboarding gate
    // blocked, which bounced the user back to the welcome screen.
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeView), findsNothing);
    expect(find.text('Add, switch, and edit server profiles'), findsOneWidget);

    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving the server editor during onboarding reaches Servers', (
    tester,
  ) async {
    await pumpApp(tester, const Size(390, 844), withServer: false);

    await tester.tap(find.text('Add your first server'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Servers'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeView), findsNothing);
    expect(find.text('Servers'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long address stays on one line in the server list', (
    tester,
  ) async {
    // The tile used to be a ListTile whose trailing chip and edit button took
    // whatever width they wanted, leaving a Tailscale hostname stacked five
    // lines deep down a narrow column on a phone.
    // No key on purpose: a complete profile connects on startup, and the test
    // binding refuses real sockets. The address is what this test is about.
    const server = ServerProfile(
      id: 'long',
      alias: 'My World',
      ip: 'admincraft.tail4e1785.ts.net',
      port: 443,
      secretKey: '',
      certificate: '',
      security: ConnectionSecurity.trustedCertificate,
    );
    await pumpApp(
      tester,
      const Size(390, 844),
      extraPrefs: {
        'servers': [jsonEncode(server.toJson())],
        'selectedServer': server.id,
      },
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Servers'));
    await tester.pumpAndSettle();

    final address = tester.widget<Text>(
      find.text('admincraft.tail4e1785.ts.net:443'),
    );
    expect(address.maxLines, 1);
    expect(address.overflow, TextOverflow.ellipsis);

    final serverCard = find.ancestor(
      of: find.text('My World'),
      matching: find.byType(Card),
    );
    expect(tester.getSize(serverCard.first).height, lessThan(90));

    // A RenderFlex overflow is reported as an exception, so this catches the
    // tile being too cramped as well as the text wrapping.
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme picker stays one row until it is expanded', (
    tester,
  ) async {
    await pumpApp(tester, const Size(1280, 720));
    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();

    final tiles = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('app-theme-'),
    );

    final collapsed = tester.widgetList(tiles).length;
    expect(collapsed, lessThan(AppTheme.values.length));

    // Hard against the right edge of the tiles below it. Flexible plus a
    // Spacer put it halfway across the card, because both default to flex 1
    // and split the free space.
    final toggleRight = tester
        .getRect(find.byKey(const ValueKey('theme-expand-toggle')))
        .right;
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
      find.descendant(
        of: find.byType(WelcomeView),
        matching: find.byType(Image),
      ),
    );
    expect(
      (logo.image as AssetImage).assetName,
      'docs/logo/variants/creeper.png',
    );
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
        'These settings apply to Admincraft on this device, not to one server.',
      ),
      findsOneWidget,
    );
    // Mojang's usage guidelines ask for this wording, so it should not be able
    // to disappear in a refactor of the About card.
    expect(
      find.text(
        'NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR '
        'ASSOCIATED WITH MOJANG OR MICROSOFT.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _NoopConnectionService extends ConnectionService {
  @override
  Future<void> connect(Model model, {bool reconnect = false}) async {}
}
