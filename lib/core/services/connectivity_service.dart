import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityResult>.broadcast();
  Stream<ConnectivityResult> get stream => _controller.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      _controller.add(result);
      debugPrint('[Connectivity] $result');
    });
  }

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    debugPrint('[Connectivity] Initial: $result');
  }

  void dispose() {
    _controller.close();
  }
}
