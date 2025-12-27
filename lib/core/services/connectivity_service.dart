import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:muvam_rider/core/utils/app_logger.dart';
import 'package:muvam_rider/core/utils/custom_flushbar.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool _isInitialized = false;
  BuildContext? _context;

  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) {
      AppLogger.log(
        '🌐 ConnectivityService already initialized, updating context',
      );
      _context = context;
      return;
    }

    _context = context;
    _isInitialized = true;

    AppLogger.log('🌐 ═══════════════════════════════════════');
    AppLogger.log('🌐 Initializing ConnectivityService');
    AppLogger.log('🌐 ═══════════════════════════════════════');

    try {
      // Check initial connectivity status
      final result = await _connectivity.checkConnectivity();
      AppLogger.log('🌐 Initial connectivity check: $result');
      _updateConnectionStatus(result, isInitial: true);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          AppLogger.log('🌐 📡 Connectivity changed event received: $results');
          _updateConnectionStatus(results, isInitial: false);
        },
        onError: (error) {
          AppLogger.log('🌐 ❌ Connectivity stream error: $error');
        },
      );

      AppLogger.log('🌐 ✅ ConnectivityService initialized successfully');
      AppLogger.log('🌐 ═══════════════════════════════════════');
    } catch (e) {
      AppLogger.log('🌐 ❌ Error initializing ConnectivityService: $e');
    }
  }

  /// Update connection status and show notification
  void _updateConnectionStatus(
    List<ConnectivityResult> results, {
    required bool isInitial,
  }) {
    final wasConnected = _isConnected;

    // Check if any of the results indicate connectivity
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );

    AppLogger.log('🌐 ═══════════════════════════════════════');
    AppLogger.log('🌐 Connection Status Update:');
    AppLogger.log('   Was Connected: $wasConnected');
    AppLogger.log('   Is Connected: $_isConnected');
    AppLogger.log('   Results: $results');
    AppLogger.log('   Is Initial: $isInitial');
    AppLogger.log('   Context Valid: ${_context != null && _context!.mounted}');
    AppLogger.log('🌐 ═══════════════════════════════════════');

    // Don't show notification on initial check, only on changes
    if (!isInitial && wasConnected != _isConnected) {
      AppLogger.log('🌐 Status changed! Showing notification...');
      if (_context != null && _context!.mounted) {
        if (_isConnected) {
          _showConnectedNotification();
        } else {
          _showDisconnectedNotification();
        }
      } else {
        AppLogger.log('🌐 ❌ Cannot show notification - context not valid');
      }
    } else {
      AppLogger.log(
        '🌐 No notification needed (initial: $isInitial, changed: ${wasConnected != _isConnected})',
      );
    }
  }

  /// Show connected notification (green)
  void _showConnectedNotification() {
    if (_context == null || !_context!.mounted) {
      AppLogger.log(
        '🌐 ❌ Cannot show connected notification - invalid context',
      );
      return;
    }

    AppLogger.log('🌐 ✅ Showing CONNECTED notification');
    CustomFlushbar.showSuccess(
      context: _context!,
      message: 'Internet is connected',
      title: 'Connected',
      duration: const Duration(seconds: 3),
    );
  }

  /// Show disconnected notification (red)
  void _showDisconnectedNotification() {
    if (_context == null || !_context!.mounted) {
      AppLogger.log(
        '🌐 ❌ Cannot show disconnected notification - invalid context',
      );
      return;
    }

    AppLogger.log('🌐 ❌ Showing DISCONNECTED notification');
    CustomFlushbar.showError(
      context: _context!,
      message: 'No internet connection',
      title: 'Disconnected',
      duration: const Duration(seconds: 3),
    );
  }

  /// Update context (useful when navigating between screens)
  void updateContext(BuildContext context) {
    _context = context;
    AppLogger.log('🌐 Context updated');
  }

  /// Dispose the service
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _context = null;
    _isInitialized = false;
    AppLogger.log('🌐 ConnectivityService disposed');
  }
}
