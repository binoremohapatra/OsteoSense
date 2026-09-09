import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joint_saathi/theme/app_motion.dart';
import 'package:joint_saathi/widgets/common/index.dart';

const _items = [
  NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home'),
  NavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people_rounded,
      label: 'Patients'),
  NavItem(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      label: 'Screen'),
  NavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'Reports'),
  NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings'),
];

void main() {
  testWidgets(
      'full-width tab taps slide the pill and emit one haptic per change',
      (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const _Harness());
    final pill = find.descendant(
      of: find.byType(GlassBottomNav),
      matching: find.byType(AnimatedPositioned),
    );
    var previousX = tester.getTopLeft(pill).dx;

    for (var index = 1; index < _items.length; index++) {
      // Tap the edge of the destination, outside its icon and label.
      final target = tester.getRect(find.byTooltip(_items[index].label));
      await tester.tapAt(Offset(target.left + 2, target.top + 2));
      await tester.pump();
      expect(tester.getTopLeft(pill).dx, previousX);
      await tester.pump(const Duration(milliseconds: 75));
      final intermediateX = tester.getTopLeft(pill).dx;
      expect(intermediateX, greaterThan(previousX));
      await tester.pump(AppMotion.fast);
      final finalX = tester.getTopLeft(pill).dx;
      expect(intermediateX, lessThan(finalX));
      expect(find.byIcon(_items[index].selectedIcon!), findsOneWidget);
      expect(haptics.length, index);
      expect(haptics.last.arguments, 'HapticFeedbackType.selectionClick');
      previousX = finalX;
    }

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump(AppMotion.fast);
    expect(haptics, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'switches retain state and crossfade both screens, including rapid taps',
      (tester) async {
    final homeKey = GlobalKey<_ProbeState>();
    final patientsKey = GlobalKey<_ProbeState>();
    await tester.pumpWidget(_Harness(children: [
      _Probe(key: homeKey, label: 'Home content'),
      _Probe(key: patientsKey, label: 'Patients content'),
      const Center(child: Text('Screen content')),
      const Center(child: Text('Reports content')),
      const Center(child: Text('Settings content')),
    ]));
    final originalHome = homeKey.currentState;
    final originalPatients = patientsKey.currentState;
    await tester.tap(find.text('Home content: 0'));
    await tester.pump();
    await tester.tap(find.byTooltip('Patients'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    for (final key in [homeKey, patientsKey]) {
      final fade = tester.widget<FadeTransition>(find
          .ancestor(
            of: find.byKey(key),
            matching: find.byType(FadeTransition),
          )
          .first);
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));
    }
    await tester.tap(find.byTooltip('Reports'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(find.byTooltip('Home'));
    await tester.pump();
    await tester.pump(AppMotion.fast);
    expect(homeKey.currentState, same(originalHome));
    expect(patientsKey.currentState, same(originalPatients));
    expect(find.text('Home content: 1'), findsOneWidget);
    expect(find.text('Patients content: 0'), findsNothing);

    // Hidden destinations cannot retain keyboard focus or receive taps.
    patientsKey.currentState!.focusNode.requestFocus();
    await tester.pump();
    expect(patientsKey.currentState!.focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav respects safe areas, constrained widths, RTL and large text',
      (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    for (final size in [const Size(375, 812), const Size(812, 375)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final dark in [false, true]) {
        await tester.pumpWidget(_Harness(
          dark: dark,
          data: const MediaQueryData(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 34),
            viewPadding: EdgeInsets.fromLTRB(24, 0, 24, 34),
            textScaler: TextScaler.linear(3),
            disableAnimations: true,
          ),
          direction: TextDirection.rtl,
        ));
        await tester.pump();
        final bar = tester.getRect(find.descendant(
          of: find.byType(GlassBottomNav),
          matching: find.byType(BackdropFilter),
        ));
        expect(bar.left, 44);
        expect(bar.right, size.width - 44);
        expect(bar.bottom, size.height - 50);
        expect(bar.height, 72);
        final home = tester.getRect(find.byTooltip('Home'));
        final settings = tester.getRect(find.byTooltip('Settings'));
        expect(home.left, greaterThan(settings.left));
        expect(home.width, greaterThanOrEqualTo(48));
        expect(home.height, greaterThanOrEqualTo(48));
        expect(
            tester.getSemantics(find.bySemanticsLabel('Home')),
            matchesSemantics(
                label: 'Home',
                isButton: true,
                isSelected: true,
                hasTapAction: true));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'keyboard selection works and reduced motion switches immediately',
      (tester) async {
    await tester.pumpWidget(const _Harness(
      data: MediaQueryData(disableAnimations: true),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.byIcon(Icons.people_rounded), findsOneWidget);
    expect(find.text('Patients content'), findsOneWidget);
    expect(find.text('Home content'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Harness extends StatefulWidget {
  final List<Widget>? children;
  final MediaQueryData data;
  final TextDirection direction;
  final bool dark;

  const _Harness({
    this.children,
    this.data = const MediaQueryData(),
    this.direction = TextDirection.ltr,
    this.dark = false,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: widget.dark ? ThemeData.dark() : ThemeData.light(),
      home: MediaQuery(
        data: widget.data,
        child: Directionality(
          textDirection: widget.direction,
          child: Scaffold(
            extendBody: true,
            body: RetainedTabSwitcher(
              currentIndex: index,
              children: widget.children ??
                  [
                    for (final item in _items)
                      Center(child: Text('${item.label} content')),
                  ],
            ),
            bottomNavigationBar: GlassBottomNav(
              currentIndex: index,
              items: _items,
              onTap: (value) => setState(() => index = value),
            ),
          ),
        ),
      ),
    );
  }
}

class _Probe extends StatefulWidget {
  final String label;
  const _Probe({super.key, required this.label});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int count = 0;
  final focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          focusNode: focusNode,
          onPressed: () => setState(() => count++),
          child: Text('${widget.label}: $count'),
        ),
      );
}
