import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map((result) => !_isNone(result));

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !_isNone(result);
  }

  bool _isNone(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.isEmpty ||
          result.every((item) => item == ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result == ConnectivityResult.none;
    }
    return false;
  }
}
