import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

abstract class Pluggable {
  String get name;
  String get displayName;
  void onTrigger();
  Widget? buildWidget(BuildContext? context);
  ImageProvider get iconImageProvider;
}

typedef StreamFilter = bool Function(dynamic);

abstract class PluggableWithStream extends Pluggable {
  Stream get stream;
  StreamFilter get streamFilter;
}

/// A tool that draws its own close button (calling
/// `DebugPanel.closeActivatedPlugin`), so the floating button hides while it
/// is open.
abstract class PluggableWithCloseButton extends Pluggable {}

abstract class PluggableWithNestedWidget extends Pluggable {
  Widget buildNestedWidget(Widget child);
}

abstract class PluggableWithAnywhereDoor extends Pluggable {
  NavigatorState? get navigator;

  Tuple2<String, Object?>? get routeNameAndArgs;
  Route? get route;

  void popResultReceive(dynamic result);
}
