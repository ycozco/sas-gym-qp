import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../network/api_client.dart';

class WebSocketService {
  io.Socket? _socket;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  // Callbacks para eventos recibidos
  VoidCallback? onTenantSuspended;
  Function(String)? onMessageReceived;
  VoidCallback? onConnected;
  VoidCallback? onDisconnected;

  bool get isConnected => _socket != null && _socket!.connected;

  void connect() async {
    if (_socket != null || _isConnecting) return;
    _isConnecting = true;

    final tenantId = await SecureStorage.getTenantId();
    if (tenantId == null) {
      _isConnecting = false;
      return;
    }

    final token = await SecureStorage.getToken();
    final baseUrl = ApiClient().dio.options.baseUrl.replaceAll('/api/v1', '');

    try {
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token ?? ''})
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        AppLogger.debug('WebSocket conectado via WebSocketService');
        _isConnecting = false;
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
        _socket?.emit('join');
        onConnected?.call();
      });

      _socket?.on('tenant_suspended', (_) {
        AppLogger.debug('Recibido evento tenant_suspended via WebSocketService');
        onTenantSuspended?.call();
      });

      _socket?.onDisconnect((_) {
        AppLogger.debug('WebSocket desconectado');
        onDisconnected?.call();
        _scheduleReconnect();
      });

      _socket?.on('connect_error', (err) {
        AppLogger.debug('WebSocket error de conexion', err);
        _scheduleReconnect();
      });

      _socket?.on('connect_timeout', (_) {
        AppLogger.debug('WebSocket timeout de conexion');
        _scheduleReconnect();
      });
    } catch (e) {
      AppLogger.debug('Error en inicializacion WebSocket', e);
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    // Backoff exponencial: 2s, 4s, 8s, 16s, 30s max
    final delay = (1 << _reconnectAttempts).clamp(2, 30);
    _reconnectAttempts++;

    AppLogger.debug('WebSocket programando reconexion en $delay segundos (intento $_reconnectAttempts)');
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _isConnecting = false;
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.close();
    _socket = null;
    _isConnecting = false;
    _reconnectAttempts = 0;
  }
}
