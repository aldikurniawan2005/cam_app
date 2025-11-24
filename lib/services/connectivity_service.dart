import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<bool> _controller = StreamController<bool>.broadcast();

  static Stream<bool> get connectionStream => _controller.stream;

  static void init() {
    _connectivity.onConnectivityChanged.listen((result) {
      _controller.add(result != ConnectivityResult.none);
    });
  }

  static Future<bool> isConnected() async {
    final r = await _connectivity.checkConnectivity();
    return r != ConnectivityResult.none;
  }
}
