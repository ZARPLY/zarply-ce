import 'dart:async';
import 'dart:math' as math;


/// Rate limiter matching Solana's public RPC limits at 80% headroom:
///
/// Public limits:
/// - 100 requests / 10s per IP (global)
/// - 40 requests  / 10s per IP per RPC method
/// - 40 concurrent connections per IP
///
/// Targets (80%):
/// - 80 requests / 10s global
/// - 32 requests / 10s per method
/// - 32 concurrent connections
///
/// Switch to a dedicated RPC (Helius, QuickNode) for production —
/// update the constants below to match their limits.

class RpcRateLimiter {
  RpcRateLimiter._();

  static final RpcRateLimiter instance = RpcRateLimiter._();

  static const int _globalMaxPerWindow = 80;
  static const int _methodMaxPerWindow = 32;
  static const int _maxConcurrent = 32;
  static const Duration _window = Duration(seconds: 10);
  static const int _maxRetries = 3;

  final List<DateTime> _globalTimestamps = <DateTime>[];
  final Map<String, List<DateTime>> _methodTimestamps = <String, List<DateTime>>{};
  int _concurrentCount = 0;
  final List<Completer<void>> _waiting = <Completer<void>>[];
  final math.Random _jitter = math.Random();

  /// Run [fn] through the rate limiter.
  /// Pass the RPC [method] name to enforce per-method limits accurately.
  Future<T> run<T>(Future<T> Function() fn, {String method = 'unknown'}) async {
    int attempt = 0;
    while (true) {
      await _acquireSlot(method);
      try {
        final T result = await fn();
        _releaseSlot();
        return result;
      } catch (e) {
        _releaseSlot();
        if (_isRateLimitError(e) && attempt < _maxRetries) {
          await Future<void>.delayed(_backoff(attempt));
          attempt++;
          continue;
        }
        rethrow;
      }
    }
  }

  Future<void> _acquireSlot(String method) async {
    while (true) {
      while (_concurrentCount >= _maxConcurrent) {
        final Completer<void> slot = Completer<void>();
        _waiting.add(slot);
        await slot.future;
      }

      final DateTime now = DateTime.now();
      final DateTime cutoff = now.subtract(_window);

      _globalTimestamps.removeWhere((DateTime t) => t.isBefore(cutoff));

      _methodTimestamps[method] ??= <DateTime>[];
      _methodTimestamps[method]!.removeWhere((DateTime t) => t.isBefore(cutoff));

      final Duration? globalWait = _waitDuration(_globalTimestamps, _globalMaxPerWindow);
      if (globalWait != null) {
        await Future<void>.delayed(globalWait);
        continue;
      }

      final Duration? methodWait = _waitDuration(_methodTimestamps[method]!, _methodMaxPerWindow);
      if (methodWait != null) {
        await Future<void>.delayed(methodWait);
        continue;
      }

      _concurrentCount++;
      _globalTimestamps.add(now);
      _methodTimestamps[method]!.add(now);
      return;
    }
  }

  /// Returns how long to wait if [timestamps] has hit [max], else null.
  Duration? _waitDuration(List<DateTime> timestamps, int max) {
    if (timestamps.length < max) return null;
    final Duration wait = timestamps.first.add(_window).difference(DateTime.now());
    return wait > Duration.zero ? wait : null;
  }

  void _releaseSlot() {
    _concurrentCount = math.max(0, _concurrentCount - 1);
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    }
  }

  /// Uses typed exceptions only — no string parsing.
  /// Throw [RpcRateLimitException] at the call site when you detect
  /// a 429 or 403 HTTP status on the raw response.
  bool _isRateLimitError(Object e) => e is RpcRateLimitException;

  /// Exponential backoff: 2s → 4s → 8s with ±jitter to avoid lockstep retries.
  Duration _backoff(int attempt) {
    final int baseMs = (2000 * (1 << attempt)).clamp(2000, 16000);
    final int jitterMs = _jitter.nextInt(500);
    return Duration(milliseconds: baseMs + jitterMs);
  }
}

/// Throw this from your RPC call site when you detect a 429 or 403
/// HTTP status code on the raw response, so the limiter can handle
/// retries without any string parsing.
///
/// Example usage in WalletSolanaService._wrapRpcCall:
/// ```dart
/// final response = await http.post(rpcUrl, body: payload);
/// if (response.statusCode == 429 || response.statusCode == 403) {
///   throw RpcRateLimitException(response.statusCode);
/// }
/// ```
class RpcRateLimitException implements Exception {
  const RpcRateLimitException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'RpcRateLimitException: HTTP $statusCode';
}
