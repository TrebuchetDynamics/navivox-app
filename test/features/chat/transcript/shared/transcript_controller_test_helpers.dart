import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a Transcript text controller and registers disposal with the test.
TextEditingController transcriptTextController({String? text}) {
  final controller = TextEditingController(text: text);
  addTearDown(controller.dispose);
  return controller;
}

/// Creates a Transcript scroll controller and registers disposal with the test.
ScrollController transcriptScrollController() {
  final controller = ScrollController();
  addTearDown(controller.dispose);
  return controller;
}
