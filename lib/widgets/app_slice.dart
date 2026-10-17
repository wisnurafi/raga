import 'package:flutter/widgets.dart';

import '../state/app_state.dart';

/// Granular AppState subscription: rebuilds [builder] only when
/// [select] returns a value that compares != to the previous one.
///
/// Screens today call `AppState.of(context)`, which subscribes to EVERY
/// [ChangeNotifier.notifyListeners] — a Detak tap or a sync tick repaints
/// the history chart and every list on screen. Wrap the heavy section in
/// an AppSlice selecting exactly what it renders, and unrelated
/// notifications skip it entirely.
///
/// The lookup is non-subscribing
/// ([getElementForInheritedWidgetOfExactType]); the slice manages its own
/// listener, so the inherited-notifier never rebuilds it directly.
class AppSlice<T> extends StatefulWidget {
  /// Picks the slice of state this section renders. Compared with `==`
  /// (override via a view-model class when the raw value lacks value
  /// equality).
  final T Function(AppState state) select;

  /// Builds the section from the selected value. Must not call
  /// `AppState.of(context)` — that would re-subscribe the section to
  /// everything this widget just filtered out.
  final Widget Function(BuildContext context, T value) builder;

  const AppSlice({super.key, required this.select, required this.builder});

  @override
  State<AppSlice<T>> createState() => _AppSliceState<T>();
}

class _AppSliceState<T> extends State<AppSlice<T>> {
  AppState? _state;
  T? _value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .getElementForInheritedWidgetOfExactType<AppStateScope>()
        ?.widget as AppStateScope?;
    assert(scope != null, 'AppStateScope not found above AppSlice');
    final state = scope!.notifier!;
    if (!identical(_state, state)) {
      _state?.removeListener(_onNotify);
      _state = state;
      _value = widget.select(state);
      _state!.addListener(_onNotify);
    }
  }

  @override
  void didUpdateWidget(AppSlice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The select closure may capture new widget params; re-evaluate
    // inline — a build follows in this same frame.
    _value = widget.select(_state!);
  }

  void _onNotify() {
    final next = widget.select(_state!);
    if (next != _value) {
      setState(() => _value = next);
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onNotify);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value as T);
}
