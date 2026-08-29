import 'package:material_ui/material_ui.dart';

import '../screens/device/updates_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void openUpdatesScreen() {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => openUpdatesScreen());
    return;
  }

  navigator.push(MaterialPageRoute(builder: (_) => const UpdatesScreen()));
}
