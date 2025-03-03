import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:quacker/client/client_regular_account.dart';
import 'package:quacker/client/login_webview.dart';
import 'package:quacker/generated/l10n.dart';

class SettingsAccountFragment extends StatefulWidget {
  const SettingsAccountFragment({super.key});

  @override
  State<SettingsAccountFragment> createState() => _SettingsAccountFragment();
}

class _SettingsAccountFragment extends State<SettingsAccountFragment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.current.account),
        actions: [
          IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwitterLoginWebview())),
              icon: const Icon(Icons.add))
        ],
      ),
      body: FutureBuilder(
          future: getAccounts(),
          builder: (BuildContext listContext, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator();
            } else {
              List<Map<String, Object?>> data = snapshot.data;
              return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (BuildContext itemContext, int index) {
                    return Card(
                        child: ListTile(
                            title: Text(L10n.of(context).account),
                            subtitle: Text(
                              data[index]['id'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: Icon(Icons.account_circle),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await deleteAccount(data[index]['id'].toString());
                                setState(() {});
                              },
                            )));
                  });
            }
          }),
    );
  }
}
