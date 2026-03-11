import 'package:flutter/foundation.dart';

enum UnifiedState { idle, loading, success, error, empty }

class EnterpriseState<T> {
  final T? data;
  final UnifiedState status;
  final String? errorMessage;
  final bool isOptimistic;

  EnterpriseState({
    this.data,
    this.status = UnifiedState.idle,
    this.errorMessage,
    this.isOptimistic = false,
  });

  EnterpriseState<T> copyWith({
    T? data,
    UnifiedState? status,
    String? errorMessage,
    bool? isOptimistic,
  }) {
    return EnterpriseState<T>(
      data: data ?? this.data,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  factory EnterpriseState.idle() => EnterpriseState(status: UnifiedState.idle);
  factory EnterpriseState.loading() =>
      EnterpriseState(status: UnifiedState.loading);
  factory EnterpriseState.success(T data, {bool isOptimistic = false}) =>
      EnterpriseState(
          data: data, status: UnifiedState.success, isOptimistic: isOptimistic);
  factory EnterpriseState.error(String message) =>
      EnterpriseState(status: UnifiedState.error, errorMessage: message);
  factory EnterpriseState.empty() =>
      EnterpriseState(status: UnifiedState.empty);
}

/// A mixin to provide standardized state reconciliation logic for ChangeNotifiers or BloCs.
mixin EnterpriseLogicMixin<T> {
  late EnterpriseState<T> _state = EnterpriseState.idle();
  EnterpriseState<T> get state => _state;

  @protected
  void emit(EnterpriseState<T> newState) {
    _state = newState;
  }

  /// Handles optimistic updates with automatic rollback on failure.
  Future<void> reconcile({
    required T optimisticData,
    required Future<T> Function() action,
    required void Function() notify,
    String Function(dynamic)? errorParser,
  }) async {
    // 1. Optimistic Update
    emit(EnterpriseState.success(optimisticData, isOptimistic: true));
    notify();

    try {
      // 2. Server Sync
      final result = await action();

      // 3. Confirm Success
      emit(EnterpriseState.success(result, isOptimistic: false));
      notify();
    } catch (e) {
      // 4. Rollback and Error
      final message = errorParser?.call(e) ?? e.toString();
      emit(EnterpriseState.error(message));
      notify();

      // Rethrow to allow UI callers to handle the error (e.g., prevent navigation)
      rethrow;
    }
  }
}



