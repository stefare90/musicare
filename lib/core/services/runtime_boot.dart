import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:music_are/core/services/preferences_service.dart';
import 'package:musicare_runtime_host/musicare_runtime_host.dart';

class RuntimePorts {
  RuntimePorts(Map<Subsystem, int> ports) : _ports = Map.unmodifiable(ports);

  final Map<Subsystem, int> _ports;

  int portOf(Subsystem subsystem) {
    final port = _ports[subsystem];
    if (port == null) {
      throw RuntimeNotStartedException('${subsystem.name} is not running.');
    }
    return port;
  }
}

class RuntimeBoot {
  RuntimeBoot({
    required this.host,
    required this.preferences,
    Future<bool> Function(int port)? ping,
    int? Function()? processId,
  }) : _ping = ping ?? _pingOverHttp,
       _processId = processId ?? (() => pid);

  final RuntimeHost host;
  final PreferencesService preferences;

  final Future<bool> Function(int port) _ping;
  final int? Function() _processId;

  static const String _pidField = 'pid';
  static const String _portsField = 'ports';
  static const Duration _probeTimeout = Duration(seconds: 2);

  Future<RuntimePorts> start() async {
    final saved = _readSession();
    if (saved != null && await _isServing(saved)) {
      return RuntimePorts(saved.ports);
    }

    await host.start();
    final ports = <Subsystem, int>{
      for (final subsystem in host.subsystems)
        subsystem: host.portOf(subsystem),
    };
    await preferences.setRuntimeSession(
      jsonEncode({
        _pidField: _processId(),
        _portsField: {
          for (final entry in ports.entries) entry.key.name: entry.value,
        },
      }),
    );
    return RuntimePorts(ports);
  }

  Future<bool> _isServing(_RuntimeSession session) async {
    final current = _processId();
    if (current == null || current != session.pid) return false;
    final answers = await Future.wait(session.ports.values.map(_ping));
    return answers.every((serving) => serving);
  }

  _RuntimeSession? _readSession() {
    final raw = preferences.getRuntimeSession();
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final pid = decoded[_pidField];
      final stored = decoded[_portsField];
      if (pid is! int || stored is! Map<String, dynamic>) return null;

      final ports = <Subsystem, int>{};
      for (final subsystem in host.subsystems) {
        final port = stored[subsystem.name];
        if (port is int) ports[subsystem] = port;
      }
      if (ports.length != host.subsystems.length) return null;
      return _RuntimeSession(pid: pid, ports: ports);
    } on FormatException catch (error) {
      debugPrint('runtime: ignoring an unreadable session ($error)');
      return null;
    }
  }

  static Future<bool> _pingOverHttp(int port) async {
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:$port/ping'))
          .timeout(_probeTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class _RuntimeSession {
  const _RuntimeSession({required this.pid, required this.ports});

  final int pid;
  final Map<Subsystem, int> ports;
}
