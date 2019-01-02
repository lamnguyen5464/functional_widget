import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/context/builder.dart';
// ignore: implementation_imports
import 'package:analyzer/src/context/context_root.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/// Analyzer plugin for built_value.
///
/// Surfaces the same errors as the generator at compile time, with fixes
/// where possible.
class FunctionWidgetAnalyzerPlugin extends ServerPlugin {
  FunctionWidgetAnalyzerPlugin(ResourceProvider provider) : super(provider);

  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    final root = ContextRoot(contextRoot.root, contextRoot.exclude,
        pathContext: resourceProvider.pathContext)
      ..optionsFilePath = contextRoot.optionsFile;
    final contextBuilder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = performanceLog
      ..fileContentOverlay = fileContentOverlay;
    final result = contextBuilder.buildDriver(root);
    result.results.listen(_processResult);
    return result;
  }

  @override
  List<String> get fileGlobsToAnalyze => const ['*.dart'];

  @override
  String get name => 'Functional Widget';

  // This is the protocol version, not the plugin version. It must match the
  // version of the `analyzer_plugin` package.
  @override
  String get version => '0.0.1-alpha.5';

  @override
  String get contactInfo =>
      'https://github.com/rrousselGit/functional_widget/issues';

  /// Computes errors based on an analysis result and notifies the analyzer.
  void _processResult(AnalysisResult analysisResult) {
    try {
      // If there is no relevant analysis result, notify the analyzer of no errors.
      if (analysisResult.unit == null ||
          analysisResult.libraryElement == null) {
        channel.sendNotification(
            plugin.AnalysisErrorsParams(analysisResult.path, [])
                .toNotification());
      } else {
        channel.sendNotification(
            plugin.AnalysisErrorsParams(analysisResult.path, [])
                .toNotification());

        // If there is something to analyze, do so and notify the analyzer.
        // Note that notifying with an empty set of errors is important as
        // this clears errors if they were fixed.
        // final checkResult = checker.check(analysisResult.libraryElement);
        // channel.sendNotification(plugin.AnalysisErrorsParams(
        //         analysisResult.path, checkResult.keys.toList())
        //     .toNotification());
      }
    } catch (e, stackTrace) {
      // Notify the analyzer that an exception happened.
      channel.sendNotification(
          plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
              .toNotification());
    }
  }

  @override
  void contentChanged(String path) {
    super.driverForPath(path).addFile(path);
  }

  @override
  Future<plugin.EditGetFixesResult> handleEditGetFixes(
      plugin.EditGetFixesParams parameters) async {
    try {
      // final analysisResult =
      //     await (driverForPath(parameters.file) as AnalysisDriver)
      //         .getResult(parameters.file);

      // // Get errors and fixes for the file.
      // final checkResult = checker.check(analysisResult.libraryElement);

      // // Return any fixes that are for the expected file.
      // final fixes = <plugin.AnalysisErrorFixes>[];
      // for (final error in checkResult.keys) {
      //   if (error.location.file == parameters.file &&
      //       checkResult[error].change.edits.single.edits.isNotEmpty) {
      //     fixes.add(
      //         plugin.AnalysisErrorFixes(error, fixes: [checkResult[error]]));
      //   }
      // }

      return plugin.EditGetFixesResult([
        plugin.AnalysisErrorFixes(plugin.AnalysisError(
            plugin.AnalysisErrorSeverity.ERROR,
            plugin.AnalysisErrorType.COMPILE_TIME_ERROR,
            plugin.Location(parameters.file, 0, 10, 0, 0),
            'Message',
            'some_code')),
      ]);
    } catch (e, stackTrace) {
      // Notify the analyzer that an exception happened.
      channel.sendNotification(
          plugin.PluginErrorParams(false, e.toString(), stackTrace.toString())
              .toNotification());
      return plugin.EditGetFixesResult([]);
    }
  }
}
