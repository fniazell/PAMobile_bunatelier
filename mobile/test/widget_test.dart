import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';
import 'package:go_router/go_router.dart';

// 1x1 transparent PNG bytes
final List<int> _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier() : super(const AuthState(isLoading: false, isAuthenticated: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('Bun Atelier App smoke test - verifies brand wordmark and UI elements',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProviderScope(
          child: HomeScreen(autoCheck: false),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify brand wordmark is rendered
    expect(find.text('BUN ATELIER'), findsOneWidget);
    expect(find.text('Best Sellers'), findsOneWidget);
    expect(find.text('NEAREST ATELIER'), findsOneWidget);
  });

  testWidgets('Dashboard Header renders cleanly on compact mobile (360x640) with zero overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProviderScope(
          child: HomeScreen(autoCheck: false),
        ),
      ),
    );

    await tester.pump();

    // Verify all header elements are rendered
    expect(find.text('BUN ATELIER'), findsOneWidget);
    expect(find.text('CRAFTED TO CRAVE'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Verify no RenderFlex overflow exception was caught
    expect(tester.takeException(), isNull);
  });

  testWidgets('BurgerHeroCarousel displays initial slide and auto-slides automatically',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProviderScope(
          child: HomeScreen(autoCheck: false),
        ),
      ),
    );

    await tester.pump();

    // Initial slide: OG Main Character
    expect(find.text('OG Main\nCharacter'), findsOneWidget);
    expect(find.text('THE BUN DROP / 01'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BurgerHeroCarousel),
        matching: find.text('Rp 65.000'),
      ),
      findsOneWidget,
    );
    expect(find.text('ORDER NOW'), findsAtLeastNWidgets(1));

    // Fast-forward 4.5 seconds for auto-slide
    await tester.pump(const Duration(milliseconds: 4500));
    await tester.pumpAndSettle();

    // Second slide should now be visible: Hot Mess Express
    expect(find.text('Hot Mess\nExpress'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BurgerHeroCarousel),
        matching: find.text('Rp 72.000'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('BurgerHeroCarousel supports manual swipe gesture',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProviderScope(
          child: HomeScreen(autoCheck: false),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('OG Main\nCharacter'), findsOneWidget);

    // Perform manual drag/swipe to left within right burger image carousel area
    await tester.drag(find.byType(PageView), const Offset(-120, 0));
    await tester.pumpAndSettle();

    // Should advance to next slide
    expect(find.text('Hot Mess\nExpress'), findsOneWidget);
  });

  testWidgets('BurgerHeroCarousel allows tapping indicator dots to jump directly to slide',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProviderScope(
          child: HomeScreen(autoCheck: false),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('OG Main\nCharacter'), findsOneWidget);

    // Tap on the 4th indicator dot (index 3) corresponding to "Crunch Culture"
    final dotsFinder = find.descendant(
      of: find.byType(BurgerHeroCarousel),
      matching: find.byType(AnimatedContainer),
    );
    expect(dotsFinder, findsNWidgets(4));

    await tester.tap(dotsFinder.at(3));
    await tester.pumpAndSettle();

    // Fourth slide should now be active
    expect(find.text('Crunch\nCulture'), findsOneWidget);
    expect(find.text('CRUNCHY / 04'), findsOneWidget);
  });

  testWidgets('SplashScreen renders AnimatedEatingMascotLogo, wordmark, and tagline WORTH THE MESS.',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProviderScope(
          child: SplashScreen(autoNavigate: false),
        ),
      ),
    );

    await tester.pump();

    // Verify AnimatedEatingMascotLogo is present
    expect(find.byType(AnimatedEatingMascotLogo), findsOneWidget);

    // Verify editorial wordmark BUN ATELIER
    expect(find.text('BUN ATELIER'), findsOneWidget);

    // Verify tagline WORTH THE MESS. is intact
    expect(find.text('WORTH THE MESS.'), findsOneWidget);

    // Verify scaffold has AppColors.cream background
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.cream);

    // Verify initial Frame 1 (Burger utuh) is displayed
    final imageFinder = find.descendant(
      of: find.byType(AnimatedEatingMascotLogo),
      matching: find.byType(Image),
    );
    expect(imageFinder, findsOneWidget);
    final initialImage = tester.widget<Image>(imageFinder);
    expect((initialImage.image as AssetImage).assetName, 'assets/images/splash/splash_frame_1.png');

    // Advance time by 600ms (to Frame 2: Mulai menggigit)
    await tester.pump(const Duration(milliseconds: 600));
    final frame2Image = tester.widget<Image>(imageFinder);
    expect((frame2Image.image as AssetImage).assetName, 'assets/images/splash/splash_frame_2.png');

    // Advance time by 500ms (to Frame 3: Burger digigit / chomp)
    await tester.pump(const Duration(milliseconds: 500));
    final frame3Image = tester.widget<Image>(imageFinder);
    expect((frame3Image.image as AssetImage).assetName, 'assets/images/splash/splash_frame_3.png');

    // Advance time by 500ms (to Frame 4: Burger sudah tergigit)
    await tester.pump(const Duration(milliseconds: 500));
    final frame4Image = tester.widget<Image>(imageFinder);
    expect((frame4Image.image as AssetImage).assetName, 'assets/images/splash/splash_frame_4.png');

    // Advance time by 500ms (to Frame 5: Mengunyah)
    await tester.pump(const Duration(milliseconds: 500));
    final frame5Image = tester.widget<Image>(imageFinder);
    expect((frame5Image.image as AssetImage).assetName, 'assets/images/splash/splash_frame_5.png');

    // Advance time by 400ms (loop back to Frame 1: Burger utuh)
    await tester.pump(const Duration(milliseconds: 400));
    final loopedImage = tester.widget<Image>(imageFinder);
    expect((loopedImage.image as AssetImage).assetName, 'assets/images/splash/splash_frame_1.png');
  });

  testWidgets('SplashScreen stays active for 4.5s before navigating (preventing premature 2s exit)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3.0, 844 * 3.0);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(autoNavigate: true),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const Scaffold(body: Text('WELCOME_PAGE')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('WELCOME_PAGE'), findsNothing);

    // At 2 seconds: SplashScreen is STILL active (old bug exited here prematurely)
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('WELCOME_PAGE'), findsNothing);

    // At 4 seconds: SplashScreen is STILL active, logo animation playing smoothly
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('WELCOME_PAGE'), findsNothing);

    // At 4.6 seconds (exceeding 4.5s): Navigates cleanly to welcome screen
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('WELCOME_PAGE'), findsOneWidget);
  });
}
