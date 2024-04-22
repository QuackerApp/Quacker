import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pref/pref.dart';
import 'dart:async';
import "dart:math";
import 'package:quacker/constants.dart';
import 'package:quacker/database/entities.dart';
import 'package:quacker/database/repository.dart';
import 'package:quacker/generated/l10n.dart';

Future<String> addAccount(BasePrefService prefs, String username, String password, String email) async {
  var database = await Repository.writable();
  final model = XRegularAccount(prefs);

  try {
    final authHeader = await model.GetAuthHeader(username: username, password: password, email: email);

    if (authHeader != null) {
      database.insert(tableAccounts,
          {"id": username, "password": password, "email": email, "auth_header": json.encode(authHeader)});

      return L10n.current.login_success;
    } else {
      return L10n.current.oops_something_went_wrong;
    }
  } catch (e) {
    return e.toString();
  }
}

Future<void> deleteAccount(String username) async {
  var database = await Repository.writable();
  database.delete(tableAccounts, where: 'id = ?', whereArgs: [username]);
}

Future<List<Map<String, Object?>>> getAccounts() async {
  var database = await Repository.readOnly();

  return database.query(tableAccounts);
}

Future<Map<dynamic, dynamic>?> getAuthHeader(BasePrefService prefs) async {
  final accounts = await getAccounts();

  if (accounts.isNotEmpty) {
    Account account = Account.fromMap(accounts[Random().nextInt(accounts.length)]);
    final authHeader = Map.castFrom<String, dynamic, String, String>(json.decode(account.authHeader));

    return authHeader;
  } else {
    return null;
  }
}

class XRegularAccount extends ChangeNotifier {
  static final log = Logger('XRegularAccount');

  XRegularAccount(this.prefs) : super();
  final BasePrefService prefs;

  static http.Client client = http.Client();
  static List<String> cookies = [];

  static Map<String, String>? _authHeader;
  static var _tokenLimit = -1;
  static var _tokenRemaining = -1;
  static var _expiresAt = -1;

  static var gtToken,
      flowToken1,
      flowToken2,
      flowTokenUserName,
      flowTokenPassword,
      flowToken2FA,
      auth_token,
      csrf_token;
  static var kdt_Coookie;

  Future<http.Response?> fetch(Uri uri,
      {Map<String, String>? headers,
      required Logger log,
      required BasePrefService prefs,
      required Map<dynamic, dynamic> authHeader}) async {
    log.info('Fetching $uri');

    XRegularAccount xRegularAccount = XRegularAccount(prefs);
    var response = await http.get(uri, headers: {
      ...?headers,
      ...authHeader,
      ...userAgentHeader,
      'authorization': bearerToken,
      'x-guest-token': (await xRegularAccount.GetGT(userAgentHeader)).toString(),
      'x-twitter-active-user': 'yes',
      'user-agent': userAgentHeader.toString()
    });

    return response;
  }

  static Future<PrefServiceShared> GetSharedPrefs() async {
    return await PrefServiceShared.init(prefix: 'pref_');
    // prefs = await SharedPreferences.getInstance();
  }

  Future<void> GetGuestId(Map<String, String> userAgentHeader) async {
    kdt_Coookie = await GetKdtCookie();
    if (kdt_Coookie != null) cookies.add(kdt_Coookie!);

    var request = http.Request("GET", Uri.parse('https://twitter.com/i/flow/login'))..followRedirects = false;
    request.headers.addAll(userAgentHeader);
    var response = await client.send(request);

    if (response.statusCode == 200) {
      var responseHeader = response.headers.toString();
      RegExpMatch? match = RegExp(r'(guest_id=.+?);').firstMatch(responseHeader);
      if (match != null) {
        var guest_id = match.group(1).toString();

        cookies.add(guest_id);
      } else {
        throw Exception("Guest ID not found in response headers");
      }
    } else {
      throw Exception("Return Status is (${response.statusCode}), it should be 302");
    }
  }

  Future<String?> GetGT(Map<String, String> userAgentHeader) async {
    var request = http.Request("Get", Uri.parse('https://twitter.com/i/flow/login'))..followRedirects = false;
    request.headers.addAll(userAgentHeader);
    request.headers.addAll({"Host": "twitter.com"});
    request.headers.addAll({"Cookie": cookies.join(";")});
    var response = await client.send(request);
    if (response.statusCode == 200) {
      final stringData = await response.stream.transform(utf8.decoder).join();
      RegExpMatch? match = RegExp(r'(gt=(.+?));').firstMatch(stringData);
      gtToken = match?.group(2).toString();
      var gtToken_cookie = match?.group(1).toString();
      if (gtToken_cookie != null) {
        cookies.add(gtToken_cookie);
        return gtToken_cookie;
      }
    } else
      throw Exception("Return Status is (${response.statusCode}), it should be 200");
  }

  Future<void> GetFlowToken1(Map<String, String> userAgentHeader) async {
    Map<String, String> result = new Map<String, String>();
    var body = {
      "input_flow_data": {
        "flow_context": {
          "debug_overrides": {},
          "start_location": {"location": "manual_link"}
        }
      },
      "subtask_versions": {
        "action_list": 2,
        "alert_dialog": 1,
        "app_download_cta": 1,
        "check_logged_in_account": 1,
        "choice_selection": 3,
        "contacts_live_sync_permission_prompt": 0,
        "cta": 7,
        "email_verification": 2,
        "end_flow": 1,
        "enter_date": 1,
        "enter_email": 2,
        "enter_password": 5,
        "enter_phone": 2,
        "enter_recaptcha": 1,
        "enter_text": 5,
        "enter_username": 2,
        "generic_urt": 3,
        "in_app_notification": 1,
        "interest_picker": 3,
        "js_instrumentation": 1,
        "menu_dialog": 1,
        "notifications_permission_prompt": 2,
        "open_account": 2,
        "open_home_timeline": 1,
        "open_link": 1,
        "phone_verification": 4,
        "privacy_options": 1,
        "security_key": 3,
        "select_avatar": 4,
        "select_banner": 2,
        "settings_list": 7,
        "show_code": 1,
        "sign_up": 2,
        "sign_up_review": 4,
        "tweet_selection_urt": 1,
        "update_users": 1,
        "upload_media": 1,
        "user_recommendations_list": 4,
        "user_recommendations_urt": 1,
        "wait_spinner": 3,
        "web_modal": 1
      }
    };
    var request = http.Request("Post", Uri.parse('https://api.twitter.com/1.1/onboarding/task.json?flow_name=login'));
    request.headers.addAll(userAgentHeader);
    request.headers.addAll({"content-type": "application/json"});
    request.headers.addAll({"authorization": bearerToken});
    request.headers.addAll({"x-guest-token": gtToken});
    request.headers.addAll({"Cookie": cookies.join(";")});
    request.headers.addAll({"Host": "api.twitter.com"});
    request.body = json.encode(body);
    var response = await client.send(request);
    if (response.statusCode == 200) {
      final stringData = await response.stream.transform(utf8.decoder).join();
      final exp = RegExp(r'flow_token":"(.+?)"');
      RegExpMatch? match = exp.firstMatch(stringData);
      flowToken1 = match!.group(1).toString();
      result.addAll({"flow_token1": flowToken1});
      var responseHeader = response.headers.toString();
      match = RegExp(r'(att=.+?);').firstMatch(responseHeader);
      var att = match!.group(1).toString();
      cookies.add(att);
    } else {
      final stringData = await response.stream.transform(utf8.decoder).join();
      throw Exception("Return Status is (${response.statusCode}), it should be 200, Message ${stringData}");
    }
  }

  Future<void> GetFlowToken2(Map<String, String> userAgentHeader) async {
    var body = {"flow_token": flowToken1, "subtask_inputs": []};
    var request = http.Request("Post", Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'));
    request.headers.addAll(userAgentHeader);
    request.headers.addAll({"content-type": "application/json"});
    request.headers.addAll({"authorization": bearerToken});
    request.headers.addAll({"x-guest-token": gtToken});
    request.headers.addAll({"Cookie": cookies.join(";")});
    request.headers.addAll({"Host": "api.twitter.com"});
    request.body = json.encode(body);
    var response = await client.send(request);
    if (response.statusCode == 200) {
      final stringData = await response.stream.transform(utf8.decoder).join();
      final exp = RegExp(r'flow_token":"(.+?)"');
      RegExpMatch? match = exp.firstMatch(stringData);
      flowToken2 = match!.group(1).toString();
    } else
      throw Exception("Return Status is (${response.statusCode}), it should be 200");
  }

  Future<void> PassUsername(String username, String? email) async {
    var body = {
      "flow_token": flowToken2,
      "subtask_inputs": [
        {
          "subtask_id": "LoginEnterUserIdentifierSSO",
          "settings_list": {
            "setting_responses": [
              {
                "key": "user_identifier",
                "response_data": {
                  "text_data": {"result": username}
                }
              }
            ],
            "link": "next_link"
          }
        }
      ]
    };

    var request = http.Request("Post", Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'));
    request.headers.addAll(userAgentHeader);
    request.headers.addAll({"content-type": "application/json"});
    request.headers.addAll({"authorization": bearerToken});
    request.headers.addAll({"x-guest-token": gtToken});
    request.headers.addAll({"Cookie": cookies.join(";")});
    request.headers.addAll({"Host": "api.twitter.com"});
    request.body = json.encode(body);
    var response = await client.send(request);
    if (response.statusCode == 200) {
      String stringData = await response.stream.transform(utf8.decoder).join();
      final exp = RegExp(r'flow_token":"(.+?)"');
      RegExpMatch? match = exp.firstMatch(stringData);
      flowTokenUserName = match!.group(1).toString();
      if (stringData.contains("LoginEnterAlternateIdentifierSubtask")) {
        var request = http.Request("Post", Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'));
        body = {
          "flow_token": flowTokenUserName,
          "subtask_inputs": [
            {
              "subtask_id": "LoginEnterAlternateIdentifierSubtask",
              "enter_text": {"text": email, "link": "next_link"}
            }
          ]
        };
        request.headers.addAll(userAgentHeader);
        request.headers.addAll({"content-type": "application/json"});
        request.headers.addAll({"authorization": bearerToken});
        request.headers.addAll({"x-guest-token": gtToken});
        request.headers.addAll({"Cookie": cookies.join(";")});
        request.headers.addAll({"Host": "api.twitter.com"});
        request.body = json.encode(body);
        var response = await client.send(request);
        if (response.statusCode == 200) {
          String stringData = await response.stream.transform(utf8.decoder).join();
          final exp = RegExp(r'flow_token":"(.+?)"');
          RegExpMatch? match = exp.firstMatch(stringData);
          flowTokenUserName = match!.group(1).toString();
        } else if (response.statusCode == 400) {
          final stringData = await response.stream.transform(utf8.decoder).join();
          if (stringData.contains("errors")) {
            var parsedError = json.decode(stringData);
            var errors = StringBuffer();
            for (var error in parsedError["errors"]) {
              errors.writeln(error["message"] ?? "null");
            }
            throw Exception(errors);
          }
        } else
          throw Exception("Return Status is (${response.statusCode}), it should be 200");
      }
    } else if (response.statusCode == 400) {
      final stringData = await response.stream.transform(utf8.decoder).join();
      if (stringData.contains("errors")) {
        var parsedError = json.decode(stringData);
        var errors = StringBuffer();
        for (var error in parsedError["errors"]) {
          errors.writeln(error["message"] ?? "null");
        }
        throw Exception(errors);
      }
    } else
      throw Exception("Return Status is (${response.statusCode}), it should be 200");
  }

  Future<void> PassPassword(String password, Map<String, String> userAgentHeader) async {
    var body = {
      "flow_token": flowTokenUserName,
      "subtask_inputs": [
        {
          "subtask_id": "LoginEnterPassword",
          "enter_password": {"password": password, "link": "next_link"}
        }
      ]
    };
    var request = http.Request("Post", Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'));
    request.headers.addAll(userAgentHeader);
    request.headers.addAll({"content-type": "application/json"});
    request.headers.addAll({"authorization": bearerToken});
    request.headers.addAll({"x-guest-token": gtToken});
    request.headers.addAll({"Cookie": cookies.join(";")});
    request.headers.addAll({"Host": "api.twitter.com"});
    request.body = json.encode(body);
    var response = await client.send(request);
    if (response.statusCode == 200) {
      final stringData = await response.stream.transform(utf8.decoder).join();
      final exp = RegExp(r'flow_token":"(.+?)"');
      RegExpMatch? match = exp.firstMatch(stringData);
      flowTokenPassword = match!.group(1).toString();
    } else if (response.statusCode == 400) {
      final stringData = await response.stream.transform(utf8.decoder).join();
      if (stringData.contains("errors")) {
        var parsedError = json.decode(stringData);
        var errors = StringBuffer();
        for (var error in parsedError["errors"]) {
          errors.writeln(error["message"] ?? "null");
        }
        throw Exception(errors);
      }
    } else
      throw Exception("Return Status is (${response.statusCode}), it should be 200");
  }

  Future<void> GetAuthTokenCsrf(Map<String, String> userAgentHeader) async {
    var body = {
      "flow_token": flowTokenPassword,
      "subtask_inputs": [
        {
          "subtask_id": "AccountDuplicationCheck",
          "check_logged_in_account": {"link": "AccountDuplicationCheck_false"}
        }
      ]
    };
    var request = http.Request("Post", Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'));
    request.headers.addAll(userAgentHeader);
    request.headers.addAll({"content-type": "application/json"});
    request.headers.addAll({"authorization": bearerToken});
    request.headers.addAll({"x-guest-token": gtToken});
    request.headers.addAll({"Cookie": cookies.join(";")});
    request.headers.addAll({"Host": "api.twitter.com"});
    request.body = json.encode(body);

    var response = await client.send(request);

    if (response.statusCode == 200) {
      var responseHeader = response.headers.toString();
      final expAuthToken = RegExp(r'(auth_token=(.+?));');
      RegExpMatch? matchAuthToken = expAuthToken.firstMatch(responseHeader);
      final String? auth_token = matchAuthToken?.group(2).toString();
      if (auth_token != null) {
        var auth_token_Coookie = matchAuthToken!.group(1).toString();
        cookies.add(auth_token_Coookie);
      }
      GetAuthTokenLimits(responseHeader);
      final expCt0 = RegExp(r'(ct0=(.+?));');
      RegExpMatch? matchCt0 = expCt0.firstMatch(responseHeader);
      csrf_token = matchCt0?.group(2).toString();
      if (csrf_token != null) {
        var csrf_token_Coookie = matchCt0!.group(1).toString();
        cookies.add(csrf_token_Coookie);
      }

      if (kdt_Coookie == null) {
        //extract KDT cookie to authenticate unknown device and prevent twitter
        // from sending email about New Login.
        final expKdt = RegExp(r'(kdt=(.+?));');
        RegExpMatch? matchKdt = expKdt.firstMatch(responseHeader);
        kdt_Coookie = matchKdt?.group(1).toString();
        if (kdt_Coookie != null) {
          await SetKdtCookie(kdt_Coookie);
        }
      }
      // final exptwid = RegExp(r'(twid="(.+?))"');
      // RegExpMatch? matchtwid = exptwid.firstMatch(responseHeader);
      // var twid_Coookie=matchtwid!.group(2).toString();
      // cookies.add("twid="+twid_Coookie);
    } else
      throw Exception("Return Status is (${response.statusCode}), it should be 200");
  }

  Future<void> BuildAuthHeader() async {
    _authHeader = Map<String, String>();
    _authHeader?.addAll({"Cookie": cookies.join(";")});
    _authHeader?.addAll({"authorization": bearerToken});
    _authHeader?.addAll({"x-csrf-token": csrf_token});
    //_authHeader!.addAll(userAgentHeader);
    //authHeader.addAll({"Host": "api.twitter.com"});
  }

  Future<bool> IsTokenExpired() async {
    if (_authHeader != null) {
      // If we don't have an expiry or limit, it's probably because we haven't made a request yet, so assume they're OK
      if (_expiresAt == -1 && _tokenLimit == -1 && _tokenRemaining == -1) {
        // TODO: Null safety with concurrent threads
        return true;
      }
      // Check if the token we have hasn't expired yet
      if (DateTime.now().millisecondsSinceEpoch < _expiresAt) {
        // Check if the token we have still has usages remaining
        if (_tokenRemaining < _tokenLimit) {
          // TODO: Null safety with concurrent threads
          return false;
        } else
          return false;
      }
      return false;
    } else
      return true;

    //log.info('Refreshing the Twitter token');
  }

  Future<void> getAuthTokenFromPref() async {
    if (_expiresAt == -1) _expiresAt = await GetTokenExpires();
    if (_tokenRemaining == -1) _tokenRemaining = await GetTokenRemaining();
    if (_tokenLimit == -1) _tokenLimit = await GetTokenLimit();
  }

  Future<void> GetAuthTokenLimits(
    String responseHeader,
  ) async {
    // Update our token's rate limit counters
    final expAuthTokenLimitReset = RegExp(r'(x-rate-limit-reset:(.+?)),');
    RegExpMatch? matchAuthTokenLimitReset = expAuthTokenLimitReset.firstMatch(responseHeader);
    var limitReset = matchAuthTokenLimitReset?.group(2).toString();

    final expAuthTokenLimitRemaining = RegExp(r'(x-rate-limit-remaining:(.+?)),');
    RegExpMatch? matchAuthTokenLimitRemaining = expAuthTokenLimitRemaining.firstMatch(responseHeader);
    var limitRemaining = matchAuthTokenLimitRemaining?.group(2).toString();

    final expAuthTokenLimitLimit = RegExp(r'(x-rate-limit-limit:(.+?)),');
    RegExpMatch? matchAuthTokenLimitLimit = expAuthTokenLimitLimit.firstMatch(responseHeader);
    var limitLimit = matchAuthTokenLimitLimit?.group(2).toString();

    if (limitReset != null && limitRemaining != null && _tokenLimit != null) {
      _expiresAt = int.parse(limitReset) * 1000;
      _tokenRemaining = int.parse(limitRemaining);
      _tokenLimit = int.parse(limitLimit!);

      await SetTokenExpires(_expiresAt);
      await SetTokenExpires(_tokenRemaining);
      await SetTokenExpires(_tokenLimit);
    }
  }

  Future<Map<dynamic, dynamic>?> GetAuthHeader(
      {required String username, required String password, String? email, BuildContext? context}) async {
    try {
      DeleteAllCookies();
      if (_authHeader == null) await getAuthTokenFromPref();
      if (!await IsTokenExpired() && _authHeader != null) return _authHeader!;
      await GetGuestId(userAgentHeader);
      await GetGT(userAgentHeader);
      await GetFlowToken1(userAgentHeader);
      await GetFlowToken2(userAgentHeader);
      await PassUsername(username, email);
      await PassPassword(password, userAgentHeader);

      await GetAuthTokenCsrf(userAgentHeader);
      await BuildAuthHeader();
    } on Exception catch (e) {
      this.DeleteAllCookies();
      throw Exception(e);
    }

    if (_authHeader != null) {
      return _authHeader!;
    }
  }

  Future DeleteAllCookies() async {
    this.DeleteTokenExpires();
    this.DeleteTokenLimit();
    this.DeleteTokenRemaining();
    _expiresAt = -1;
    _tokenLimit = -1;
    _tokenRemaining = -1;
    cookies.clear();
  }

  Future SetKdtCookie(String cookie) async {
    await prefs.set("KDT_Cookie", cookie);
  }

  Future<String?> GetKdtCookie() async {
    return prefs.get("KDT_Cookie");
  }

  Future DeleteKdtCookie() async {
    return prefs.remove("KDT_Cookie");
  }

  Future SetTokenExpires(int expiresAt) async {
    await prefs.set("auth_expiresAt", expiresAt);
  }

  Future<int> GetTokenExpires() async {
    return prefs.get("auth_expiresAt") ?? -1;
  }

  Future DeleteTokenExpires() async {
    return prefs.remove("auth_expiresAt");
  }

  Future SetTokenRemaining(int tokenRemaining) async {
    await prefs.set("auth_tokenRemaining", tokenRemaining);
  }

  Future<int> GetTokenRemaining() async {
    return prefs.get("auth_tokenRemaining") ?? -1;
  }

  Future DeleteTokenRemaining() async {
    return prefs.remove("auth_tokenRemaining");
  }

  Future SetTokenLimit(int tokenLimit) async {
    await prefs.set("auth_tokenLimit", tokenLimit);
  }

  Future<int> GetTokenLimit() async {
    return prefs.get("auth_tokenLimit") ?? -1;
  }

  Future DeleteTokenLimit() async {
    return prefs.remove("auth_tokenLimit");
  }

  // log.info('Imported data into ${}');
}
