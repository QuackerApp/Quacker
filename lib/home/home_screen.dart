import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:quacker/constants.dart';
import 'package:quacker/generated/l10n.dart';
import 'package:quacker/group/group_screen.dart';
import 'package:quacker/home/_feed.dart';
import 'package:quacker/home/_missing.dart';
import 'package:quacker/home/_saved.dart';
import 'package:quacker/home/home_model.dart';
import 'package:quacker/subscriptions/subscriptions.dart';
import 'package:quacker/search/search_screen.dart';
import 'package:quacker/ui/errors.dart';
import 'package:quacker/ui/physics.dart';
import 'package:quacker/utils/debounce.dart';
import 'package:pref/pref.dart';
import 'package:provider/provider.dart';

typedef NavigationTitleBuilder = String Function(BuildContext context);

class NavigationPage {
  final String id;
  final NavigationTitleBuilder titleBuilder;
  final Widget icon;
  final Widget selectedIcon;

  NavigationPage(this.id, this.titleBuilder, this.icon, this.selectedIcon);
}

List<Widget> createCommonAppBarActions(BuildContext context) {
  return [
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => Navigator.pushNamed(context, routeSettings),
    )
  ];
}

final List<NavigationPage> defaultHomePages = [
  NavigationPage('feed', (c) => L10n.of(c).home, Icon(Icons.home_outlined), Icon(Icons.home)),
  NavigationPage('trending', (c) => L10n.of(c).search, Icon(Icons.search_outlined), Icon(Icons.search)),
  NavigationPage(
      'subscriptions', (c) => L10n.of(c).subscriptions, Icon(Icons.subscriptions_outlined), Icon(Icons.subscriptions)),
  NavigationPage('saved', (c) => L10n.of(c).saved, Icon(Icons.bookmark_border_outlined), Icon(Icons.bookmark)),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var prefs = PrefService.of(context);
    var model = context.read<HomeModel>();

    return _HomeScreen(prefs: prefs, model: model);
  }
}

class _HomeScreen extends StatefulWidget {
  final BasePrefService prefs;
  final HomeModel model;

  const _HomeScreen({Key? key, required this.prefs, required this.model}) : super(key: key);

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _initialPage = 0;
  List<NavigationPage> _pages = [];

  @override
  void initState() {
    super.initState();

    _buildPages(widget.model.state);
    widget.model.observer(onState: _buildPages);
  }

  void _buildPages(List<HomePage> state) {
    var pages = state.where((element) => element.selected).map((e) => e.page).toList();

    if (widget.prefs.getKeys().contains(optionHomeInitialTab)) {
      _initialPage = max(0, pages.indexWhere((element) => element.id == widget.prefs.get(optionHomeInitialTab)));
    }

    setState(() {
      _pages = pages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedBuilder<HomeModel, List<HomePage>>.transition(
        store: widget.model,
        onError: (_, e) => ScaffoldErrorWidget(
              prefix: L10n.current.unable_to_load_home_pages,
              error: e,
              stackTrace: null,
              onRetry: () async => await widget.model.resetPages(),
              retryText: L10n.current.reset_home_pages,
            ),
        onLoading: (_) => const Center(child: CircularProgressIndicator()),
        onState: (_, state) {
          return ScaffoldWithBottomNavigation(
              pages: _pages,
              initialPage: _initialPage,
              builder: (scrollController) {
                return [
                  ..._pages.map((e) {
                    if (e.id.startsWith('group-')) {
                      return SubscriptionGroupScreen(
                        scrollController: scrollController,
                        id: e.id.replaceAll('group-', ''),
                        actions: createCommonAppBarActions(context),
                        name: '',
                      );
                    }

                    switch (e.id) {
                      case 'feed':
                        return FeedScreen(scrollController: scrollController, id: '-1', name: L10n.current.feed);
                      case 'subscriptions':
                        return SubscriptionsScreen(
                          scrollController: scrollController,
                        );
                      case 'trending':
                        return SearchScreen(scrollController: scrollController);
                      case 'saved':
                        return SavedScreen(scrollController: scrollController);
                      default:
                        return const MissingScreen();
                    }
                  })
                ];
              });
        });
  }
}

class ScaffoldWithBottomNavigation extends StatefulWidget {
  final List<NavigationPage> pages;
  final int initialPage;
  final List<Widget> Function(ScrollController scrollController) builder;

  const ScaffoldWithBottomNavigation({Key? key, required this.pages, required this.initialPage, required this.builder})
      : super(key: key);

  @override
  State<ScaffoldWithBottomNavigation> createState() => _ScaffoldWithBottomNavigationState();
}

class _ScaffoldWithBottomNavigationState extends State<ScaffoldWithBottomNavigation> {
  final ScrollController scrollController = ScrollController();

  PageController? _pageController;
  late List<Widget> _children;
  late List<NavigationPage> _pages;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    currentPage = widget.initialPage;

    _pages = _padToMinimumPagesLength(widget.pages);

    _pageController = PageController(initialPage: widget.initialPage);

    _children = widget.builder(scrollController);
  }

  List<NavigationPage> _padToMinimumPagesLength(List<NavigationPage> pages) {
    var widgetPages = pages;
    if (widgetPages.length < 2) {
      widgetPages.addAll(List.generate(2 - widgetPages.length, (index) {
        return NavigationPage('none', (context) => L10n.current.missing_page, Icon(Icons.disabled_by_default_outlined),
            Icon(Icons.disabled_by_default));
      }));
    }

    return widgetPages;
  }

  @override
  void didUpdateWidget(ScaffoldWithBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);

    var newPages = _padToMinimumPagesLength(widget.pages);
    if (oldWidget.pages != widget.pages) {
      setState(() {
        _children = widget.builder(scrollController);
        _pages = newPages;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showNavigationLabels = PrefService.of(context).get(optionShowNavigationLabels);
    final trueDark = PrefService.of(context).get(optionThemeTrueBlack);
    final _disableAnimations = PrefService.of(context).get(optionDisableAnimations);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const LessSensitiveScrollPhysics(),
        onPageChanged: (page) => Debouncer.debounce('page-change', const Duration(milliseconds: 200), () {
          setState(() {
            currentPage = page;
          });
        }),
        children: _children,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        surfaceTintColor: Theme.of(context).brightness == Brightness.dark && trueDark == true ? Colors.black : null,
        height: !showNavigationLabels ? 40 : 80,
        labelBehavior: showNavigationLabels
            ? NavigationDestinationLabelBehavior.alwaysShow
            : NavigationDestinationLabelBehavior.alwaysHide,
        animationDuration: _disableAnimations == true ? Duration.zero : null,
        destinations: [
          ..._pages.map(
              (e) => NavigationDestination(icon: e.icon, selectedIcon: e.selectedIcon, label: e.titleBuilder(context)))
        ],
        onDestinationSelected: (int value) {
          setState(() {
            currentPage = value;
            _disableAnimations == true
                ? _pageController?.jumpToPage(value)
                : _pageController?.animateToPage(value, duration: Durations.medium1, curve: Curves.ease);
          });
        },
      ),
    );
  }
}
