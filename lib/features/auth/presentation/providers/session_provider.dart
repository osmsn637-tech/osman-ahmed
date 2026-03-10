import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';

class SessionState {
  const SessionState({this.user, this.accessToken});

  final User? user;
  final String? accessToken;

  bool get isAuthenticated => user != null;

  SessionState copyWith({
    User? user,
    String? accessToken,
    bool clearAccessToken = false,
  }) =>
      SessionState(
        user: user ?? this.user,
        accessToken: clearAccessToken ? null : (accessToken ?? this.accessToken),
      );
}

class SessionController extends ChangeNotifier {
  SessionController();

  final _authStream = StreamController<SessionState>.broadcast();
  SessionState _state = const SessionState();

  SessionState get state => _state;
  Stream<SessionState> get authChanges => _authStream.stream;

  void setUser(User user, {String? accessToken}) {
    _state = _state.copyWith(user: user, accessToken: accessToken);
    _authStream.add(_state);
    notifyListeners();
  }

  void clear() {
    _state = const SessionState();
    _authStream.add(_state);
    notifyListeners();
  }

  @override
  void dispose() {
    _authStream.close();
    super.dispose();
  }
}
