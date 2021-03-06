import 'package:flutter/widgets.dart';
import 'package:flutter_complete_guide/models/http_exception.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDateOfToken;
  String _userId;
  bool _isAdmin = false;
  Timer _authTimer;

  bool get isLoggedIn {
    return token != null;
  }

  bool get isAdmin {
    return _isAdmin;
  }

  String get uid {
    return _userId;
  }

  String get token {
    if (_expiryDateOfToken != null &&
        _expiryDateOfToken.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<void> _authenticate(email, password, urlSegment) async {
    final url = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCC1ao4IfZs9wzeLVEU6cA2Woa9D8bg5rM");
    try {
      final res = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final res_data = json.decode(res.body);
      print(res_data);
      if (res_data['error'] != null) {
        throw HttpException(res_data['error']['message']);
      }
      _token = res_data['idToken'];
      _userId = res_data['localId'];
      _expiryDateOfToken = DateTime.now().add(
        Duration(seconds: int.parse(res_data['expiresIn'])),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance(); // storage on device
      final userData = json.encode({
        "token": _token,
        "userId": _userId,
        "expiryDateOfToken": _expiryDateOfToken.toIso8601String(),
        "isAdmin": _isAdmin
      });
      prefs.setString('userData', userData);
    } catch (err) {
      throw err;
    }
  }

  Future<void> signUp(email, password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> signIn(email, password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<void> checkAdminStatus() async {
    final url = Uri.parse(
        'https://shop-app-2bbe2-default-rtdb.europe-west1.firebasedatabase.app/admins.json?auth=$token');
    final res = await http.get(url);
    final res_data = json.decode(res.body);
    if (res_data != null && res_data[uid] != null && res_data[uid] == true) {
      _isAdmin = true;
    }
    print(isAdmin);
  }

  Future<void> logout() async {
    _expiryDateOfToken = null;
    _token = null;
    _userId = null;
    _isAdmin = false;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDateOfToken']);
    print(extractedUserData);
    print(expiryDate);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    } else {
      print(extractedUserData['isAdmin']);
      _isAdmin = extractedUserData['isAdmin'];
      _token = extractedUserData['token'];

      _expiryDateOfToken = expiryDate;

      _userId = extractedUserData['userId'];
      notifyListeners();
      return true;
    }
  }

  void _autoLogout() {
    final timeToExpiry =
        _expiryDateOfToken.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    notifyListeners();
  }
}
