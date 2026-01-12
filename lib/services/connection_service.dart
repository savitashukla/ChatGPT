import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ConnectionService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final RxBool _isConnected = true.obs; // Start optimistic
  final RxString _connectionType = 'unknown'.obs;
  final RxBool _isOnlineMode = true.obs; // Start in online mode
  bool _isShowingDialog = false; // Add this flag

  // Getters
  bool get isConnected => _isConnected.value;
  String get connectionType => _connectionType.value;
  bool get isOnlineMode => _isOnlineMode.value;
  bool get isOfflineMode => !_isOnlineMode.value;

  @override
  void onInit() {
    super.onInit();
    // On web, start with optimistic connectivity
    if (kIsWeb) {
      print('🌐 Running on web - starting in online mode');
      _isConnected.value = true;
      _isOnlineMode.value = true;
    }
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
      bool hasInternet = false;

      if (kIsWeb) {
        // For web, be optimistic - assume we have internet unless proven otherwise
        // Web apps are served over HTTP, so if the page loaded, we likely have internet
        print('🌐 Web platform detected - checking connectivity...');

        try {
          final response = await http.head(
            Uri.parse('https://www.google.com'),
          ).timeout(const Duration(seconds: 3));
          hasInternet = response.statusCode >= 200 && response.statusCode < 500;
          print('🌐 Web connectivity check: ${response.statusCode} - $hasInternet');
        } catch (e) {
          print('⚠️ Web connectivity check failed: $e');
          // On web, assume we have internet if the check fails
          // (could be CORS, firewall, etc.)
          hasInternet = true;
          print('🌐 Assuming online mode for web (check failed but page is loaded)');
        }
      } else {
        // For native platforms, use InternetAddress lookup
        final result = await InternetAddress.lookup('google.com').timeout(
          const Duration(seconds: 5),
        );
        hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        print('📱 Native connectivity check: $hasInternet');
      }

      _isConnected.value = hasInternet;

      // If we have internet and mode is offline, ask user if they want to switch
      if (_isConnected.value && !_isOnlineMode.value && !_isShowingDialog) {
        _showOnlineAvailableDialog();
      } else if (_isConnected.value && _isOnlineMode.value) {
        // If we have internet and already in online mode, ensure it stays online
        print('✅ Internet available and online mode active');
      } else if (!_isConnected.value) {
        print('❌ No internet connection detected');
      }
    } catch (e) {
      print('❌ Error verifying internet access: $e');

      // On web, be lenient - don't force offline mode if check fails
      if (kIsWeb) {
        print('🌐 Web platform - keeping online mode despite error');
        _isConnected.value = true;
      } else {
        _isConnected.value = false;
        _forceOfflineMode();
      }
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
    if (_isShowingDialog) return; // Prevent duplicate dialogs

    _isShowingDialog = true;

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
              _isShowingDialog = false;
              Get.back();
              // Stay in offline mode
            },
            child: const Text('Stay Offline'),
          ),
          ElevatedButton(
            onPressed: () {
              _isShowingDialog = false;
              Get.back();
              switchToOnlineMode();
            },
            child: const Text('Go Online'),
          ),
        ],
      ),
      barrierDismissible: false,
    ).then((_) {
      _isShowingDialog = false; // Reset flag when dialog is dismissed
    });
  }

  /// Notify about connection changes
  void _notifyConnectionChange() {
    print('Connection status: ${_isConnected.value ? 'Connected' : 'Disconnected'} (${_connectionType.value})');
    print('Mode: ${_isOnlineMode.value ? 'Online' : 'Offline'}');
  }

  /// Force online mode (bypass connection check) - useful for debugging or when connection check fails
  void forceOnlineMode() {
    _isOnlineMode.value = true;
    _isConnected.value = true; // Override connection status
    Get.snackbar(
      '🌐 Forced Online Mode',
      'Manually enabled online mode. Make sure you have internet connection!',
      backgroundColor: Colors.orange.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
    print('⚠️ FORCED online mode - bypassing connection check');
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
      print('✅ Switched to online mode');
    } else {
      Get.snackbar(
        '❌ No Internet',
        'Cannot switch to online mode. No internet connection available.',
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
      print('❌ Cannot switch to online mode - no internet');
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

  /// Force check internet connection
  Future<void> forceCheckConnection() async {
    print('🔄 Force checking internet connection...');
    await _initConnectivity();
  }
}
