import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectionService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final RxBool _isConnected = true.obs;
  final RxString _connectionType = 'unknown'.obs;
  final RxBool _isOnlineMode = true.obs;

  // Getters
  bool get isConnected => _isConnected.value;
  String get connectionType => _connectionType.value;
  bool get isOnlineMode => _isOnlineMode.value;
  bool get isOfflineMode => !_isOnlineMode.value;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _setupConnectivityListener();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
    } catch (e) {
      print('Failed to get connectivity: $e');
      _isConnected.value = false;
    }
  }

  /// Setup connectivity change listener
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        print('Connectivity stream error: $error');
        _isConnected.value = false;
      },
    );
  }

  /// Update connection status based on connectivity result
  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.none:
        _isConnected.value = false;
        _connectionType.value = 'none';
        _forceOfflineMode();
        break;
      case ConnectivityResult.mobile:
        _connectionType.value = 'mobile';
        await _verifyInternetAccess();
        break;
      case ConnectivityResult.wifi:
        _connectionType.value = 'wifi';
        await _verifyInternetAccess();
        break;
      case ConnectivityResult.ethernet:
        _connectionType.value = 'ethernet';
        await _verifyInternetAccess();
        break;
      case ConnectivityResult.bluetooth:
        _connectionType.value = 'bluetooth';
        _isConnected.value = false; // Bluetooth doesn't provide internet
        break;
      case ConnectivityResult.vpn:
        _connectionType.value = 'vpn';
        await _verifyInternetAccess();
        break;
      case ConnectivityResult.other:
        _connectionType.value = 'other';
        await _verifyInternetAccess();
        break;
    }

    _notifyConnectionChange();
  }

  /// Verify actual internet access by attempting to connect to a reliable service
  Future<void> _verifyInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected.value = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      // If we have internet but mode is offline, ask user if they want to switch
      if (_isConnected.value && !_isOnlineMode.value) {
        _showOnlineAvailableDialog();
      }
    } catch (e) {
      _isConnected.value = false;
      _forceOfflineMode();
    }
  }

  /// Force offline mode when no connection
  void _forceOfflineMode() {
    if (_isOnlineMode.value) {
      _isOnlineMode.value = false;
      Get.snackbar(
        '📴 Offline Mode',
        'No internet connection. Switched to offline mode with on-device AI.',
        backgroundColor: Get.theme.primaryColor.withOpacity(0.9),
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Show dialog when internet becomes available
  void _showOnlineAvailableDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.green),
            SizedBox(width: 8),
            Text('Internet Available'),
          ],
        ),
        content: const Text(
          'Internet connection is now available. Would you like to switch to online mode for enhanced AI responses?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(closeOverlays: false);
              // Stay in offline mode
            },
            child: const Text('Stay Offline'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(closeOverlays: false);
              switchToOnlineMode();
            },
            child: const Text('Go Online'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Notify about connection changes
  void _notifyConnectionChange() {
    print('Connection status: ${_isConnected.value ? 'Connected' : 'Disconnected'} (${_connectionType.value})');
    print('Mode: ${_isOnlineMode.value ? 'Online' : 'Offline'}');
  }

  /// Manually switch to online mode
  void switchToOnlineMode() {
    if (_isConnected.value) {
      _isOnlineMode.value = true;
      Get.snackbar(
        '🌐 Online Mode',
        'Switched to online mode. Using cloud-based AI for enhanced responses.',
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
    } else {
      Get.snackbar(
        '❌ No Internet',
        'Cannot switch to online mode. No internet connection available.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  /// Manually switch to offline mode
  void switchToOfflineMode() {
    _isOnlineMode.value = false;
    Get.snackbar(
      '📱 Offline Mode',
      'Switched to offline mode. Using on-device AI.',
      backgroundColor: Get.theme.primaryColor.withOpacity(0.9),
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// Toggle between online and offline modes
  void toggleMode() {
    if (_isOnlineMode.value) {
      switchToOfflineMode();
    } else {
      switchToOnlineMode();
    }
  }

  /// Get connection status info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected.value,
      'connectionType': _connectionType.value,
      'isOnlineMode': _isOnlineMode.value,
      'canSwitchToOnline': _isConnected.value && !_isOnlineMode.value,
    };
  }
}
