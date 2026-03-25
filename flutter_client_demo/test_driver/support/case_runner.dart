import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

class CaseRunner {
  CaseRunner({
    required this.driver,
    required this.runId,
    required this.reportsRoot,
    required this.testName,
  });

  final FlutterDriver driver;
  final String runId;
  final Directory reportsRoot;
  final String testName;

  final List<Map<String, Object?>> _stepEvents = <Map<String, Object?>>[];
  final List<Map<String, Object?>> _actionEvents = <Map<String, Object?>>[];

  String? _failureStepId;
  String? _debugDescriptionRelPath;

  Future<void> run(Future<void> Function() body) async {
    final int startedAt = DateTime.now().millisecondsSinceEpoch;
    Object? failure;
    StackTrace? failureStackTrace;

    try {
      await body();
    } catch (error, stackTrace) {
      failure = error;
      failureStackTrace = stackTrace;
      _failureStepId ??= 'runner';
      _debugDescriptionRelPath = await _writeDebugDescription();
    } finally {
      final int endedAt = DateTime.now().millisecondsSinceEpoch;
      await _writeJsonLines(_stepFile, _stepEvents);
      await _writeJsonLines(_actionFile, _actionEvents);
      await _resultFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'test_name': testName,
          'run_id': runId,
          'status': failure == null ? 'passed' : 'failed',
          'started_at_ms': startedAt,
          'ended_at_ms': endedAt,
          'duration_ms': endedAt - startedAt,
          'failure_step_id': _failureStepId,
          'debug_description_relpath': _debugDescriptionRelPath,
          'error': failure?.toString(),
        }),
      );
    }

    if (failure != null) {
      Error.throwWithStackTrace(failure, failureStackTrace!);
    }
  }

  Future<void> step({
    required String stepId,
    required String stepName,
    required Future<void> Function() body,
  }) async {
    final int startedAt = DateTime.now().millisecondsSinceEpoch;
    String? screenshotRelPath;

    try {
      await body();
      await settle();
      screenshotRelPath = await _takeStepScreenshot(stepId, 'success');
      final int endedAt = DateTime.now().millisecondsSinceEpoch;
      _stepEvents.add(<String, Object?>{
        'run_id': runId,
        'test_name': testName,
        'step_id': stepId,
        'step_name': stepName,
        'status': 'passed',
        'started_at_ms': startedAt,
        'ended_at_ms': endedAt,
        'duration_ms': endedAt - startedAt,
        'screenshot_relpath': screenshotRelPath,
      });
    } catch (error) {
      _failureStepId ??= stepId;
      await settle();
      screenshotRelPath = await _takeStepScreenshot(stepId, 'failed');
      final int endedAt = DateTime.now().millisecondsSinceEpoch;
      _stepEvents.add(<String, Object?>{
        'run_id': runId,
        'test_name': testName,
        'step_id': stepId,
        'step_name': stepName,
        'status': 'failed',
        'started_at_ms': startedAt,
        'ended_at_ms': endedAt,
        'duration_ms': endedAt - startedAt,
        'screenshot_relpath': screenshotRelPath,
        'error': error.toString(),
      });
      rethrow;
    }
  }

  Future<void> tapFinder({
    required String stepId,
    required String stepName,
    required String target,
    required SerializableFinder finder,
  }) async {
    final int startedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      await driver.waitFor(finder, timeout: const Duration(seconds: 8));
      await driver.tap(finder);
      _actionEvents.add(<String, Object?>{
        'run_id': runId,
        'test_name': testName,
        'step_id': stepId,
        'step_name': stepName,
        'action': 'tap',
        'target': target,
        'detail': 'Tap target',
        'status': 'passed',
        'ts_ms': startedAt,
      });
      await settle();
    } catch (error) {
      _actionEvents.add(<String, Object?>{
        'run_id': runId,
        'test_name': testName,
        'step_id': stepId,
        'step_name': stepName,
        'action': 'tap',
        'target': target,
        'detail': 'Tap target',
        'status': 'failed',
        'ts_ms': startedAt,
        'error': error.toString(),
      });
      rethrow;
    }
  }

  Future<void> enterTextViaTap({
    required String stepId,
    required String stepName,
    required String target,
    required SerializableFinder finder,
    required String value,
    bool redact = false,
  }) async {
    final int startedAt = DateTime.now().millisecondsSinceEpoch;
    try {
      await driver.waitFor(finder, timeout: const Duration(seconds: 8));
      await driver.tap(finder);
      await driver.enterText(value);
      _actionEvents.add(<String, Object?>{
        'run_id': runId,
        'test_name': testName,
        'step_id': stepId,
        'step_name': stepName,
        'action': 'input',
        'target': target,
        'detail': redact ? '已输入保密内容' : '输入值: $value',
        'status': 'passed',
        'ts_ms': startedAt,
      });
      await settle();
    } catch (error) {
      _actionEvents.add(<String, Object?>{
        'run_id': runId,
        'test_name': testName,
        'step_id': stepId,
        'step_name': stepName,
        'action': 'input',
        'target': target,
        'detail': redact ? '已输入保密内容' : '输入值: $value',
        'status': 'failed',
        'ts_ms': startedAt,
        'error': error.toString(),
      });
      rethrow;
    }
  }

  Future<void> waitForText(String text) async {
    await driver.waitFor(find.text(text), timeout: const Duration(seconds: 8));
  }

  Future<void> waitForAbsentText(String text) async {
    await driver.waitForAbsent(
      find.text(text),
      timeout: const Duration(seconds: 8),
    );
  }

  Future<void> settle() async {
    try {
      await driver.waitUntilNoTransientCallbacks(
        timeout: const Duration(seconds: 5),
      );
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<String?> _takeStepScreenshot(String stepId, String suffix) async {
    try {
      final List<int> screenshotBytes = await driver.screenshot();
      final String relPath = 'screens/$testName/${stepId}_$suffix.png';
      final File outputFile = File('${reportsRoot.path}/$relPath');
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(screenshotBytes);
      return relPath;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _writeDebugDescription() async {
    try {
      final String? renderTree = (await driver.getRenderTree()).tree;
      final String stepId = _failureStepId ?? 'failure';
      final String relPath =
          'logs/${_safeName}_${stepId}_debug_description.txt';
      final File outputFile = File('${reportsRoot.path}/$relPath');
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(renderTree ?? 'No render tree available.');
      return relPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeJsonLines(
    File file,
    List<Map<String, Object?>> rows,
  ) async {
    await file.parent.create(recursive: true);
    final String content = rows.isEmpty
        ? ''
        : '${rows.map(jsonEncode).join('\n')}\n';
    await file.writeAsString(content);
  }

  String get _safeName {
    final String sanitized = testName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '_',
    );
    return sanitized.isEmpty ? 'test' : sanitized;
  }

  Directory get _logsDir => Directory('${reportsRoot.path}/logs');

  File get _stepFile => File('${_logsDir.path}/${_safeName}_step_events.jsonl');

  File get _actionFile =>
      File('${_logsDir.path}/${_safeName}_action_events.jsonl');

  File get _resultFile =>
      File('${_logsDir.path}/${_safeName}_test_result.json');
}
