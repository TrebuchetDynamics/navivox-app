import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/needle_test_transcripts.dart';
import '../models/needle_scorecard.dart';
import '../providers/needle_spike_providers.dart';
import '../services/needle_result.dart';

/// Hidden evaluation screen for the Needle spike. Reached only via the
/// NEEDLE_SPIKE-gated route. Transcripts shown here are never logged or
/// persisted; the scorecard keeps counts only.
class NeedleSpikeScreen extends ConsumerStatefulWidget {
  const NeedleSpikeScreen({super.key});

  @override
  ConsumerState<NeedleSpikeScreen> createState() => _NeedleSpikeScreenState();
}

class _NeedleSpikeScreenState extends ConsumerState<NeedleSpikeScreen> {
  final _transcriptController = TextEditingController();
  final _scorecard = NeedleScorecard();

  String? _modelDir;
  bool _preparing = false;
  bool _running = false;
  bool _capturing = false;
  int _downloadedBytes = 0;
  String? _error;
  NeedleResult? _result;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _checkInstalled() async {
    try {
      final install = await ref.read(needleInstallServiceProvider.future);
      final dir = await install.installedModelDir();
      if (!mounted) return;
      setState(() => _modelDir = dir);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _prepareModel() async {
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      final install = await ref.read(needleInstallServiceProvider.future);
      final dir = await install.ensureModel(
        onProgress: (bytes) {
          if (mounted) setState(() => _downloadedBytes = bytes);
        },
      );
      final engine = ref.read(needleEngineProvider);
      await engine.load(dir);
      if (!mounted) return;
      setState(() => _modelDir = dir);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _run(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty || _running) return;
    setState(() {
      _running = true;
      _error = null;
      _result = null;
    });
    try {
      final engine = ref.read(needleEngineProvider);
      if (!engine.isLoaded) {
        final dir = _modelDir;
        if (dir == null) {
          throw StateError('Download the model first.');
        }
        await engine.load(dir);
      }
      final service = ref.read(needleSpikeServiceProvider);
      final result = await service.parseTranscript(trimmed);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _captureFromMic() async {
    final factory = ref.read(needleVoiceCaptureFactoryProvider);
    final capture = factory();
    if (capture == null) {
      setState(() => _error = 'Speech capture unavailable on this platform.');
      return;
    }
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final result = await capture.capture(
        timeout: const Duration(seconds: 15),
      );
      if (!mounted) return;
      _transcriptController.text = result.transcript;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _recordVerdict(NeedleVerdict verdict) {
    setState(() => _scorecard.record(verdict));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Needle spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_modelDir == null) _buildInstallCard() else ..._buildEvalUi(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Needle model is not installed (~16 MB download).'),
            const SizedBox(height: 12),
            if (_preparing)
              Text('Downloading… $_downloadedBytes bytes')
            else
              FilledButton(
                key: const Key('needle-download-button'),
                onPressed: _prepareModel,
                child: const Text('Download and load model'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEvalUi() {
    final result = _result;
    return [
      TextField(
        key: const Key('needle-transcript-field'),
        controller: _transcriptController,
        decoration: InputDecoration(
          labelText: 'Transcript',
          suffixIcon: IconButton(
            key: const Key('needle-mic-button'),
            icon: Icon(_capturing ? Icons.mic : Icons.mic_none),
            onPressed: _capturing ? null : _captureFromMic,
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        key: const Key('needle-run-button'),
        onPressed: _running ? null : () => _run(_transcriptController.text),
        child: Text(_running ? 'Running…' : 'Run Needle'),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in needleTestTranscripts)
            ActionChip(
              label: Text(t.text, overflow: TextOverflow.ellipsis),
              onPressed: _running
                  ? null
                  : () {
                      _transcriptController.text = t.text;
                      _run(t.text);
                    },
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (result != null) _buildResultCard(result),
      const SizedBox(height: 16),
      _buildScorecard(),
    ];
  }

  Widget _buildResultCard(NeedleResult result) {
    final call = result.functionCalls.isEmpty
        ? null
        : result.functionCalls.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              call == null
                  ? 'No tool call. Raw response: ${result.response}'
                  : 'Tool: ${call.name}\nArgs: ${call.arguments}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'wall ${result.wallLatencyMs} ms · '
              'engine ${result.totalTimeMs?.toStringAsFixed(1) ?? '—'} ms · '
              'ttft ${result.timeToFirstTokenMs?.toStringAsFixed(1) ?? '—'} ms · '
              'confidence ${result.confidence?.toStringAsFixed(3) ?? '—'}',
            ),
            if (!result.success)
              Text('Engine error: ${result.error ?? 'unknown'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_scorecard.summaryLine),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('needle-verdict-correct'),
                  onPressed: () => _recordVerdict(NeedleVerdict.correct),
                  child: const Text('Correct'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-wrong-tool'),
                  onPressed: () => _recordVerdict(NeedleVerdict.wrongTool),
                  child: const Text('Wrong tool'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-wrong-args'),
                  onPressed: () => _recordVerdict(NeedleVerdict.wrongArgs),
                  child: const Text('Wrong args'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-no-call'),
                  onPressed: () => _recordVerdict(NeedleVerdict.noCall),
                  child: const Text('No call'),
                ),
                TextButton(
                  onPressed: () => setState(_scorecard.reset),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
