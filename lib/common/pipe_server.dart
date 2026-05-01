// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// --- Dynamic libraries ---

final _kernel32 = DynamicLibrary.open('kernel32.dll');
final _advapi32 = DynamicLibrary.open('advapi32.dll');

// --- Win32 typedefs (native) ---

typedef _CreateNamedPipeW_Native =
    IntPtr Function(
      Pointer<Utf16> lpName,
      Uint32 dwOpenMode,
      Uint32 dwPipeMode,
      Uint32 nMaxInstances,
      Uint32 nOutBufferSize,
      Uint32 nInBufferSize,
      Uint32 nDefaultTimeOut,
      Pointer<Void> lpSecurityAttributes,
    );
typedef _ConnectNamedPipe_Native =
    Int32 Function(IntPtr hNamedPipe, Pointer<Void> lpOverlapped);
typedef _ReadFile_Native =
    Int32 Function(
      IntPtr hFile,
      Pointer<Uint8> lpBuffer,
      Uint32 nNumberOfBytesToRead,
      Pointer<Uint32> lpNumberOfBytesRead,
      Pointer<Void> lpOverlapped,
    );
typedef _WriteFile_Native =
    Int32 Function(
      IntPtr hFile,
      Pointer<Uint8> lpBuffer,
      Uint32 nNumberOfBytesToWrite,
      Pointer<Uint32> lpNumberOfBytesWritten,
      Pointer<Void> lpOverlapped,
    );
typedef _CloseHandle_Native = Int32 Function(IntPtr hObject);
typedef _DisconnectNamedPipe_Native = Int32 Function(IntPtr hNamedPipe);
typedef _ConvertStringSD_Native =
    Int32 Function(
      Pointer<Utf16> StringSecurityDescriptor,
      Uint32 StringSDRevision,
      Pointer<Pointer<Void>> SecurityDescriptor,
      Pointer<Uint32> SecurityDescriptorSize,
    );
typedef _LocalFree_Native = IntPtr Function(IntPtr hMem);
typedef _CreateEventW_Native =
    IntPtr Function(
      Pointer<Void> lpEventAttributes,
      Int32 bManualReset,
      Int32 bInitialState,
      Pointer<Utf16> lpName,
    );
typedef _WaitForSingleObject_Native =
    Uint32 Function(IntPtr hHandle, Uint32 dwMilliseconds);
typedef _GetOverlappedResult_Native =
    Int32 Function(
      IntPtr hFile,
      Pointer<Overlapped> lpOverlapped,
      Pointer<Uint32> lpNumberOfBytesTransferred,
      Int32 bWait,
    );
typedef _GetLastError_Native = Uint32 Function();

// --- Win32 typedefs (Dart) ---

typedef _CreateNamedPipeW_Dart =
    int Function(
      Pointer<Utf16> lpName,
      int dwOpenMode,
      int dwPipeMode,
      int nMaxInstances,
      int nOutBufferSize,
      int nInBufferSize,
      int nDefaultTimeOut,
      Pointer<Void> lpSecurityAttributes,
    );
typedef _ConnectNamedPipe_Dart =
    int Function(int hNamedPipe, Pointer<Void> lpOverlapped);
typedef _ReadFile_Dart =
    int Function(
      int hFile,
      Pointer<Uint8> lpBuffer,
      int nNumberOfBytesToRead,
      Pointer<Uint32> lpNumberOfBytesRead,
      Pointer<Void> lpOverlapped,
    );
typedef _WriteFile_Dart =
    int Function(
      int hFile,
      Pointer<Uint8> lpBuffer,
      int nNumberOfBytesToWrite,
      Pointer<Uint32> lpNumberOfBytesWritten,
      Pointer<Void> lpOverlapped,
    );
typedef _CloseHandle_Dart = int Function(int hObject);
typedef _DisconnectNamedPipe_Dart = int Function(int hNamedPipe);
typedef _ConvertStringSD_Dart =
    int Function(
      Pointer<Utf16> StringSecurityDescriptor,
      int StringSDRevision,
      Pointer<Pointer<Void>> SecurityDescriptor,
      Pointer<Uint32> SecurityDescriptorSize,
    );
typedef _LocalFree_Dart = int Function(int hMem);
typedef _CreateEventW_Dart =
    int Function(
      Pointer<Void> lpEventAttributes,
      int bManualReset,
      int bInitialState,
      Pointer<Utf16> lpName,
    );
typedef _WaitForSingleObject_Dart =
    int Function(int hHandle, int dwMilliseconds);
typedef _GetOverlappedResult_Dart =
    int Function(
      int hFile,
      Pointer<Overlapped> lpOverlapped,
      Pointer<Uint32> lpNumberOfBytesTransferred,
      int bWait,
    );
typedef _GetLastError_Dart = int Function();

// --- Looked-up functions ---

final _createNamedPipe = _kernel32
    .lookupFunction<_CreateNamedPipeW_Native, _CreateNamedPipeW_Dart>(
      'CreateNamedPipeW',
    );
final _connectNamedPipe = _kernel32
    .lookupFunction<_ConnectNamedPipe_Native, _ConnectNamedPipe_Dart>(
      'ConnectNamedPipe',
    );
final _readFile = _kernel32.lookupFunction<_ReadFile_Native, _ReadFile_Dart>(
  'ReadFile',
);
final _writeFile = _kernel32.lookupFunction<_WriteFile_Native, _WriteFile_Dart>(
  'WriteFile',
);
final _closeHandle = _kernel32
    .lookupFunction<_CloseHandle_Native, _CloseHandle_Dart>('CloseHandle');
final _disconnectNamedPipe = _kernel32
    .lookupFunction<_DisconnectNamedPipe_Native, _DisconnectNamedPipe_Dart>(
      'DisconnectNamedPipe',
    );
final _convertStringSD = _advapi32
    .lookupFunction<_ConvertStringSD_Native, _ConvertStringSD_Dart>(
      'ConvertStringSecurityDescriptorToSecurityDescriptorW',
    );
final _localFree = _kernel32.lookupFunction<_LocalFree_Native, _LocalFree_Dart>(
  'LocalFree',
);
final _createEvent = _kernel32
    .lookupFunction<_CreateEventW_Native, _CreateEventW_Dart>('CreateEventW');
final _waitForSingleObject = _kernel32
    .lookupFunction<_WaitForSingleObject_Native, _WaitForSingleObject_Dart>(
      'WaitForSingleObject',
    );
final _getOverlappedResult = _kernel32
    .lookupFunction<_GetOverlappedResult_Native, _GetOverlappedResult_Dart>(
      'GetOverlappedResult',
    );
final _getLastError = _kernel32
    .lookupFunction<_GetLastError_Native, _GetLastError_Dart>('GetLastError');

// --- Win32 constants ---

const _PIPE_ACCESS_DUPLEX = 0x00000003;
const _FILE_FLAG_OVERLAPPED = 0x40000000;
const _PIPE_TYPE_BYTE = 0x00000000;
const _PIPE_READMODE_BYTE = 0x00000000;
const _PIPE_WAIT = 0x00000000;
const _SDDL_REVISION_1 = 1;
const _INVALID_HANDLE_VALUE = -1;
const _ERROR_PIPE_CONNECTED = 535;
const _WAIT_OBJECT_0 = 0;
const _WAIT_TIMEOUT = 258;
const _ERROR_IO_PENDING = 997;

const _windowsPipeSDDL = 'D:PAI(A;OICI;GWGR;;;BU)(A;OICI;GWGR;;;SY)';
const _pipeBufferSize = 256 * 1024;

// --- Overlapped struct ---

final class Overlapped extends Struct {
  @UintPtr()
  external int internal;
  @UintPtr()
  external int internalHigh;
  @UintPtr()
  external int offset;
  @UintPtr()
  external int offsetHigh;
  @IntPtr()
  external int hEvent;
}

// --- Security descriptor helpers ---

Pointer<Void> _createSD() {
  final sddl = _windowsPipeSDDL.toNativeUtf16();
  final sd = calloc<Pointer<Void>>();
  final size = calloc<Uint32>();
  final ok = _convertStringSD(sddl, _SDDL_REVISION_1, sd, size);
  calloc.free(sddl);
  calloc.free(size);
  if (ok == 0) {
    calloc.free(sd);
    return nullptr;
  }
  final result = sd.value;
  calloc.free(sd);
  return result;
}

void _freeSD(Pointer<Void> sd) {
  if (sd != nullptr) _localFree(sd.address);
}

// --- Isolate message types ---

// Messages from isolate to main: Uint8List (data), String ("connected"/"closed"/"error")
// Messages from main to isolate: _PipeCmd

class _PipeCmd {
  final int type; // 0 = write, 1 = close
  final Uint8List? data;

  const _PipeCmd(this.type, this.data);
}

// --- Isolate entry point ---

void _pipeIsolate(List<Object> args) {
  final pipeName = args[0] as String;
  final dataPort = args[1] as SendPort;

  final namePtr = pipeName.toNativeUtf16();
  final sd = _createSD();

  final handle = _createNamedPipe(
    namePtr,
    _PIPE_ACCESS_DUPLEX | _FILE_FLAG_OVERLAPPED,
    _PIPE_TYPE_BYTE | _PIPE_READMODE_BYTE | _PIPE_WAIT,
    1,
    _pipeBufferSize,
    _pipeBufferSize,
    0,
    sd,
  );

  calloc.free(namePtr);
  _freeSD(sd);

  if (handle == _INVALID_HANDLE_VALUE) {
    dataPort.send('error');
    return;
  }

  // Send write port so main can send write commands
  final writeRx = ReceivePort();
  dataPort.send(writeRx.sendPort);

  // Set up shared read resources (reused across connections)
  final readBuf = calloc<Uint8>(_pipeBufferSize);
  final bytesRead = calloc<Uint32>();
  final overlapped = calloc<Overlapped>();
  final readEvent = _createEvent(nullptr, 1, 0, nullptr);
  overlapped.ref.hEvent = readEvent;

  var running = true;

  // Write handler runs in parallel; closing writeRx signals shutdown
  writeRx.listen((msg) {
    if (msg is _PipeCmd) {
      if (msg.type == 0 && msg.data != null) {
        _pipeWrite(handle, msg.data!);
      } else if (msg.type == 1) {
        running = false;
        writeRx.close();
        // Wake up ConnectNamedPipe / ReadFile by... we can't easily cancel
        // DisconnectNamedPipe will unblock a pending ReadFile
        _disconnectNamedPipe(handle);
      }
    }
  });

  // Accept loop
  while (running) {
    final cr = _connectNamedPipe(handle, nullptr);
    if (cr == 0 && _getLastError() != _ERROR_PIPE_CONNECTED) {
      dataPort.send('error');
      break;
    }
    if (!running) break;

    dataPort.send('connected');

    // Read loop
    var readPending = false;
    while (running) {
      if (!readPending) {
        bytesRead.value = 0;
        final readResult = _readFile(
          handle,
          readBuf,
          _pipeBufferSize,
          bytesRead,
          overlapped.cast(),
        );
        if (readResult != 0) {
          if (bytesRead.value > 0) {
            dataPort.send(
              Uint8List.fromList(readBuf.asTypedList(bytesRead.value)),
            );
          }
          readPending = false;
        } else {
          if (_getLastError() == _ERROR_IO_PENDING) {
            readPending = true;
          } else {
            break;
          }
        }
      }

      if (readPending) {
        final wr = _waitForSingleObject(readEvent, 100);
        if (wr == _WAIT_OBJECT_0) {
          final got = _getOverlappedResult(handle, overlapped, bytesRead, 0);
          if (got != 0 && bytesRead.value > 0) {
            dataPort.send(
              Uint8List.fromList(readBuf.asTypedList(bytesRead.value)),
            );
            readPending = false;
          } else {
            break;
          }
        } else if (wr != _WAIT_TIMEOUT) {
          break;
        }
      }
    }

    if (running) {
      _disconnectNamedPipe(handle);
      dataPort.send('closed');
    }
  }

  // Cleanup
  _closeHandle(readEvent);
  calloc.free(overlapped);
  calloc.free(bytesRead);
  calloc.free(readBuf);
  _closeHandle(handle);
}

void _pipeWrite(int handle, Uint8List data) {
  final buf = calloc<Uint8>(data.length + 1);
  final written = calloc<Uint32>();
  buf.asTypedList(data.length).setAll(0, data);
  buf[data.length] = 0x0A; // append newline
  _writeFile(handle, buf, data.length + 1, written, nullptr);
  calloc.free(written);
  calloc.free(buf);
}

// --- Public API ---

class NamedPipeServer {
  final String pipeName;
  Isolate? _isolate;
  SendPort? _writePort;
  final _dataController = StreamController<Uint8List>();
  Completer<void> _connected = Completer<void>();

  /// Called when the client connects ('connected') or disconnects ('closed').
  void Function(String status)? onStatusChange;

  NamedPipeServer(this.pipeName);

  Stream<Uint8List> get dataStream => _dataController.stream;

  Future<void> get connected => _connected.future;

  Future<void> start() async {
    final responsePort = ReceivePort();
    final ready = Completer<void>();

    responsePort.listen((message) {
      if (_writePort == null && message is SendPort) {
        _writePort = message;
        ready.complete();
      } else if (message == 'connected') {
        if (_connected.isCompleted) {
          _connected = Completer<void>();
        }
        _connected.complete();
        onStatusChange?.call('connected');
      } else if (message is Uint8List) {
        _dataController.add(message);
      } else if (message == 'closed') {
        if (!_connected.isCompleted) {
          _connected = Completer<void>();
        }
        onStatusChange?.call('closed');
      } else if (message == 'error') {
        if (!ready.isCompleted) {
          ready.completeError(StateError('Named pipe creation failed'));
        }
      }
    });

    _isolate = await Isolate.spawn(_pipeIsolate, [
      pipeName,
      responsePort.sendPort,
    ]);

    await ready.future;
  }

  void write(List<int> data) {
    _writePort?.send(_PipeCmd(0, Uint8List.fromList(data)));
  }

  Future<void> close() async {
    _writePort?.send(const _PipeCmd(1, null));
    // Allow time for the pipe isolate to clean up (disconnect, close handles, free memory)
    await Future.delayed(const Duration(milliseconds: 50));
    _isolate?.kill();
    _isolate = null;
    _writePort = null;
    if (!_connected.isCompleted) {
      _connected.complete();
    }
  }
}
