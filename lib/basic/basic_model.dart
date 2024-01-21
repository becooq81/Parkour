import '/flutter_flow/flutter_flow_util.dart';
import 'basic_widget.dart' show BasicWidget;
import 'package:flutter/material.dart';

class BasicModel extends FlutterFlowModel<BasicWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();

  /// Initialization and disposal methods.

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }

  /// Action blocks are added here.

  /// Additional helper methods are added here.
}
