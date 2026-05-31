import 'package:flutter/widgets.dart';

import '../../../../../shared/app/test_material_app.dart';

/// Wraps transcript widget fixtures in the shared feature-test Material shell.
Widget transcriptTestScaffold(Widget body) {
  return TestMaterialScaffold(body: body);
}
