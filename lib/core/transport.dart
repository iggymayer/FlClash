import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';

abstract class CoreTransport {
  String get address;

  Completer get connectionCompleter;

  Stream<Uint8List> get dataStream;

  void Function()? onDisconnect;

  Future<void> init();

  void send(String message);

  Future<void> close();
}

class SocketTransport extends CoreTransport {
  ServerSocket? _server;
  Socket? _currentSocket;
  Completer _completer = Completer();
  final _dataController = StreamController<Uint8List>();

  @override
  String get address => unixSocketPath;

  @override
  Completer get connectionCompleter => _completer;

  @override
  Stream<Uint8List> get dataStream => _dataController.stream;

  @override
  Future<void> init() async {
    await _deleteSocketFile();
    final server = await retry(
      task: () async {
        try {
          final address = InternetAddress(
            unixSocketPath,
            type: InternetAddressType.unix,
          );
          final server = await ServerSocket.bind(address, 0, shared: true);
          server.listen(_onConnection);
          return server;
        } catch (_) {
          return null;
        }
      },
      retryIf: (server) => server == null,
    );
    if (server == null) {
      commonPrint.log(
        'Failed to bind server socket after retries',
        logLevel: LogLevel.error,
      );
      throw StateError(
        'Failed to initialize core service: unable to bind server socket',
      );
    }
    _server = server;
  }

  void _onConnection(Socket socket) {
    _currentSocket?.destroy();

    if (_completer.isCompleted) {
      _completer = Completer();
    }

    _currentSocket = socket;
    _completer.complete();

    socket.listen(
      _dataController.add,
      onDone: () {
        if (!_completer.isCompleted) {
          _completer.complete();
        }
        _completer = Completer();
        onDisconnect?.call();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  void send(String message) {
    _currentSocket?.writeln(message);
  }

  @override
  Future<void> close() async {
    _currentSocket?.destroy();
    _currentSocket = null;
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    _completer = Completer();
    await _server?.close();
    _server = null;
    await _deleteSocketFile();
    await _dataController.close();
  }
}

Future<void> _deleteSocketFile() async {
  if (!system.isWindows) {
    final file = File(unixSocketPath);
    await file.safeDelete();
  }
}

class PipeTransport extends CoreTransport {
  NamedPipeServer? _pipeServer;
  Completer _completer = Completer();
  StreamController<Uint8List>? _dataController;

  @override
  String get address => windowsPipeName;

  @override
  Completer get connectionCompleter => _completer;

  @override
  Stream<Uint8List> get dataStream => _dataController!.stream;

  @override
  Future<void> init() async {
    _dataController = StreamController<Uint8List>();
    _pipeServer = NamedPipeServer(windowsPipeName);
    await _pipeServer!.start();

    _pipeServer!.onStatusChange = (status) {
      if (status == 'connected') {
        if (_completer.isCompleted) {
          _completer = Completer();
        }
        _completer.complete();
      } else if (status == 'closed') {
        if (!_completer.isCompleted) {
          _completer.complete();
        }
        _completer = Completer();
        onDisconnect?.call();
      }
    };

    _pipeServer!.dataStream.listen(
      _dataController!.add,
      onDone: () {},
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  void send(String message) {
    _pipeServer?.write(message.codeUnits);
  }

  @override
  Future<void> close() async {
    await _pipeServer?.close();
    _pipeServer = null;
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    _completer = Completer();
    await _dataController?.close();
    _dataController = null;
  }
}
