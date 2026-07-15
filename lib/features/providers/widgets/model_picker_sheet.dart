import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';

/// Slot options for a model assignment: the main slot or one existing
/// auxiliary task slot.
class _SlotOption {
  const _SlotOption({required this.label, required this.scope, this.task});

  final String label;
  final String scope;
  final String? task;
}

/// Picks a provider/model for the main or an auxiliary slot from
/// `state.modelInventory.catalog`, assigning it with the current revision as an
/// `If-Match` precondition. A refresh action triggers the one gated outbound
/// catalog fetch.
class ModelPickerSheet extends StatefulWidget {
  const ModelPickerSheet({
    required this.channel,
    required this.inventory,
    super.key,
  });

  final HermesChannel channel;
  final HermesModelInventory inventory;

  @override
  State<ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<ModelPickerSheet> {
  late List<_SlotOption> _slots;
  _SlotOption? _slot;
  String? _provider;
  String? _model;
  String? _error;
  bool _busy = false;

  HermesModelCatalog get _catalog => widget.inventory.catalog;
  HermesModelAssignment get _assignment => widget.inventory.assignment;

  @override
  void initState() {
    super.initState();
    _rebuildSlots();
    _provider = _catalog.providers.isNotEmpty
        ? _catalog.providers.first.provider
        : null;
    _syncModel();
  }

  void _rebuildSlots() {
    _slots = [
      const _SlotOption(label: 'main', scope: 'main'),
      for (final aux in _assignment.auxiliary)
        _SlotOption(label: aux.task, scope: 'auxiliary', task: aux.task),
    ];
    _slot = _slots.first;
  }

  List<HermesCatalogModel> get _modelsForProvider {
    for (final block in _catalog.providers) {
      if (block.provider == _provider) return block.models;
    }
    return const [];
  }

  void _syncModel() {
    final models = _modelsForProvider;
    _model = models.isNotEmpty ? models.first.id : null;
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.channel.refreshModels();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(context).modelAssignmentFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assign() async {
    final slot = _slot;
    final provider = _provider;
    final model = _model;
    if (slot == null || provider == null || model == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.channel.assignModel(
        scope: slot.scope,
        task: slot.task,
        provider: provider,
        model: model,
        revision: _assignment.revision,
      );
      if (mounted) await Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      setState(() {
        _error = error.toString().contains('412')
            ? strings.modelRevisionConflict
            : strings.modelAssignmentFailed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final models = _modelsForProvider;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.modelPickerTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.refreshCatalogAction),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_catalog.providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  strings.modelCatalogEmpty,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              if (_slots.length > 1) ...[
                DropdownButtonFormField<_SlotOption>(
                  initialValue: _slot,
                  decoration: InputDecoration(
                    labelText: strings.modelSlotLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final slot in _slots)
                      DropdownMenuItem<_SlotOption>(
                        value: slot,
                        child: Text(
                          slot.scope == 'main'
                              ? strings.modelSlotMain
                              : slot.label,
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _slot = value),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                initialValue: _provider,
                decoration: InputDecoration(
                  labelText: strings.modelProviderLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final block in _catalog.providers)
                    DropdownMenuItem<String>(
                      value: block.provider,
                      child: Text(block.provider),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _provider = value;
                        _syncModel();
                      }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _model,
                decoration: InputDecoration(
                  labelText: strings.modelNameLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final model in models)
                    DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(model.id),
                    ),
                ],
                onChanged: _busy || models.isEmpty
                    ? null
                    : (value) => setState(() => _model = value),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(strings.cancelAction),
                ),
                FilledButton.icon(
                  onPressed: _busy || _model == null ? null : _assign,
                  icon: const Icon(Icons.check),
                  label: Text(strings.assignModelAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
