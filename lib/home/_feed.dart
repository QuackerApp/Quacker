import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pref/pref.dart';
import 'package:provider/provider.dart';
import 'package:quacker/client/client.dart';
import 'package:quacker/constants.dart';
import 'package:quacker/home/_forYou.dart';
import 'package:quacker/generated/l10n.dart';
import 'package:quacker/group/_settings.dart';
import 'package:quacker/group/group_model.dart';
import 'package:quacker/group/group_screen.dart';
import 'package:quacker/home/home_screen.dart';
import 'package:quacker/user.dart';

class FeedScreen extends StatefulWidget {
  final ScrollController scrollController;
  final String id;
  final String name;

  const FeedScreen({super.key, required this.scrollController, required this.id, required this.name});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with AutomaticKeepAliveClientMixin<FeedScreen>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  UserWithExtra user = UserWithExtra();

  PagingController<String?, TweetChain> _pagingController = PagingController(firstPageKey: null);
  late TabController _tabController;
  int _tab = 0;
  Duration animationDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation!.addListener(_tabListener);
  }

  void _tabListener() {
    if (_tab != _tabController.animation!.value.round()) {
      setState(() {
        _tab = _tabController.animation!.value.round();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool _disableAnimations = PrefService.of(context).get(optionDisableAnimations) == true;

    return Provider<GroupModel>(create: (context) {
      var model = GroupModel(widget.id);
      model.loadGroup();

      return model;
    }, builder: (context, child) {
      var model = context.read<GroupModel>();

      return NestedScrollView(
          controller: widget.scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                pinned: false,
                snap: true,
                floating: true,
                title: DropdownMenu(
                    inputDecorationTheme: InputDecorationTheme(
                        isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    initialSelection: L10n.current.following,
                    textStyle: Theme.of(context).appBarTheme.titleTextStyle,
                    onSelected: (value) => setState(() {
                          if (value == L10n.current.foryou) {
                            _tab = 1;
                          } else if (value == L10n.current.following) {
                            _tab = 0;
                          }
                        }),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: L10n.current.following, label: L10n.current.following),
                      DropdownMenuEntry(value: L10n.current.foryou, label: L10n.current.foryou)
                    ]),
                actions: [
                  if (_tab == 0)
                    IconButton(icon: const Icon(Icons.more_vert), onPressed: () => showFeedSettings(context, model)),
                  IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: () async {
                        if (_disableAnimations == false) {
                          await widget.scrollController
                              .animateTo(0, duration: const Duration(seconds: 1), curve: Curves.easeInOut);
                        } else {
                          widget.scrollController.jumpTo(0);
                        }
                      }),
                  IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        if (_tab == 0) {
                          await model.loadGroup();
                        } else {
                          _pagingController.refresh();
                        }
                      }),
                  ...createCommonAppBarActions(context)
                ],
              ),
            ];
          },
          body: [
            SubscriptionGroupScreenContent(
              id: widget.id,
            ),
            ForYouTweets(_pagingController,
                type: 'profile', includeReplies: false, pinnedTweets: [], pref: PrefService.of(context)),
          ][_tab]);
    });
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
