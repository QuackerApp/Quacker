import 'package:flutter/material.dart';
import 'package:quacker/constants.dart';
import 'package:quacker/generated/l10n.dart';
import 'package:quacker/profile/profile.dart';
import 'package:quacker/search/results_screen.dart';
import 'package:quacker/trends/_list.dart';
import 'package:quacker/trends/_settings.dart';
import 'package:quacker/trends/_tabs.dart';

class SearchScreen extends StatefulWidget {
  final ScrollController scrollController;

  const SearchScreen({Key? key, required this.scrollController}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin<SearchScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    TextEditingController _searchController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
          flexibleSpace: Padding(
              padding: EdgeInsets.fromLTRB(8.0, 36.0, 8.0, 8.0),
              child: SearchBar(
                controller: _searchController,
                hintText: L10n.of(context).search,
                leading: Padding(
                    padding: EdgeInsets.all(8.0), child: Icon(Icons.search, size: Theme.of(context).iconTheme.size)),
                onSubmitted: (value) {
                  if (Uri.decodeQueryComponent(_searchController.text)[0] == '@' &&
                      Uri.decodeQueryComponent(_searchController.text).split(" ").last.isNotEmpty) {
                    Navigator.pushNamed(context, routeProfile,
                        arguments: ProfileScreenArguments(
                            null, Uri.decodeQueryComponent(_searchController.text).substring(1)));
                  } else {
                    Navigator.pushNamed(context, routeSearch,
                        arguments: SearchArguments(0,
                            focusInputOnOpen: false, query: Uri.decodeQueryComponent(_searchController.text)));
                  }
                  _searchController.clear();
                },
              )),
          bottom: const TrendsTabBar()),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async => showModalBottomSheet(
                context: context,
                builder: (context) => const TrendsSettings(),
              )),
      body: TrendsList(
        scrollController: widget.scrollController,
      ),
    );
  }
}
