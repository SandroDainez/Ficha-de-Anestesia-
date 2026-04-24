import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../utils/team_member_entry.dart';

const _dialogSurfaceColor = Color(0xFFF3F6FC);
const _dialogFieldBorderColor = Color(0xFFD5E4F7);
const _dialogEmptyTextColor = Color(0xFF7A8EA5);
const _dialogActionColor = Color(0xFF3C6C9C);
const _dialogTitleStyle = TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.w400,
  color: Color(0xFF1F2630),
);

InputDecoration _dialogInputDecoration({
  required String labelText,
  String? hintText,
  bool alignLabelWithHint = false,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: const BorderSide(color: _dialogFieldBorderColor),
  );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: _dialogActionColor, width: 1.2),
    ),
  );
}

ButtonStyle _dialogPrimaryButtonStyle({EdgeInsetsGeometry? padding}) {
  return FilledButton.styleFrom(
    backgroundColor: _dialogActionColor,
    foregroundColor: Colors.white,
    padding:
        padding ?? const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
  );
}

ButtonStyle _dialogSecondaryButtonStyle() {
  return TextButton.styleFrom(
    foregroundColor: _dialogActionColor,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}

InputDecoration _dialogSearchDecoration() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: const BorderSide(color: _dialogFieldBorderColor),
  );
  return InputDecoration(
    hintText: 'Buscar...',
    prefixIcon: const Icon(Icons.search, color: Color(0xFF6A7E94)),
    filled: true,
    fillColor: const Color(0xFFFBF8EF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: _dialogActionColor, width: 1.2),
    ),
  );
}

Widget _dialogEmptyState(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _dialogEmptyTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

Widget _dialogListTile({
  required String title,
  String? subtitle,
  required VoidCallback onDelete,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _dialogFieldBorderColor),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF26384A),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _dialogEmptyTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          color: _dialogActionColor,
        ),
      ],
    ),
  );
}

class _DialogOptionCard extends StatelessWidget {
  const _DialogOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.supportingText,
    this.color = _dialogActionColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? supportingText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final activeBorder = selected ? color : _dialogFieldBorderColor;
    final activeBackground = selected ? color.withAlpha(12) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: activeBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: activeBorder, width: selected ? 1.4 : 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A17324D),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, color: color, size: 22),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF26384A),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (supportingText != null &&
                        supportingText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        supportingText!,
                        style: const TextStyle(
                          color: _dialogEmptyTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionGridSection extends StatefulWidget {
  const SelectionGridSection({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onToggle,
    this.searchEnabled = true,
    this.emptySearchText = 'Nenhuma opção encontrada para a busca.',
    this.color = _dialogActionColor,
    this.optionDescriptionBuilder,
  });

  final List<String> options;
  final bool Function(String option) isSelected;
  final ValueChanged<String> onToggle;
  final bool searchEnabled;
  final String emptySearchText;
  final Color color;
  final String? Function(String option)? optionDescriptionBuilder;

  @override
  State<SelectionGridSection> createState() => _SelectionGridSectionState();
}

class _SelectionGridSectionState extends State<SelectionGridSection> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredOptions = widget.options.where((option) {
      final description = widget.optionDescriptionBuilder?.call(option) ?? '';
      final haystack = '$option $description'.toLowerCase();
      return normalizedQuery.isEmpty || haystack.contains(normalizedQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.searchEnabled) ...[
          TextField(
            controller: _searchController,
            decoration: _dialogSearchDecoration(),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 22),
        ],
        if (filteredOptions.isEmpty)
          _dialogEmptyState(widget.emptySearchText)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              final columnChildren = List.generate(columns, (_) => <Widget>[]);

              for (var i = 0; i < filteredOptions.length; i++) {
                final option = filteredOptions[i];
                columnChildren[i % columns].add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DialogOptionCard(
                      label: option,
                      supportingText: widget.optionDescriptionBuilder?.call(
                        option,
                      ),
                      selected: widget.isSelected(option),
                      onTap: () => widget.onToggle(option),
                      color: widget.color,
                    ),
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    Expanded(child: Column(children: columnChildren[i])),
                    if (i != columns - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class AnesthesiologistsDialog extends StatefulWidget {
  const AnesthesiologistsDialog({super.key, required this.initialItems})
    : title = 'Anestesiologistas',
      addButtonLabel = 'Adicionar anestesiologista',
      emptyStateText = 'Nenhum anestesiologista adicionado.';

  final List<String> initialItems;
  final String title;
  final String addButtonLabel;
  final String emptyStateText;

  @override
  State<AnesthesiologistsDialog> createState() =>
      _AnesthesiologistsDialogState();
}

class StructuredTeamMembersDialog extends AnesthesiologistsDialog {
  const StructuredTeamMembersDialog({
    super.key,
    required super.initialItems,
    required this.dialogTitle,
    required this.dialogAddButtonLabel,
    required this.dialogEmptyStateText,
  });

  final String dialogTitle;
  final String dialogAddButtonLabel;
  final String dialogEmptyStateText;

  @override
  String get title => dialogTitle;

  @override
  String get addButtonLabel => dialogAddButtonLabel;

  @override
  String get emptyStateText => dialogEmptyStateText;
}

class _AnesthesiologistsDialogState extends State<AnesthesiologistsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _crmController;
  late final TextEditingController _detailsController;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _crmController = TextEditingController();
    _detailsController = TextEditingController();
    _items = List<String>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _crmController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _buildDraftItem() {
    final name = _nameController.text.trim();
    final crm = _crmController.text.trim();
    final details = _detailsController.text.trim();
    if (name.isEmpty && crm.isEmpty && details.isEmpty) return null;
    if (name.isEmpty) return null;
    return TeamMemberEntry(name: name, crm: crm, details: details).encode();
  }

  void _addDraft() {
    final draft = _buildDraftItem();
    if (draft == null) return;
    setState(() {
      _items = [..._items, draft];
      _nameController.clear();
      _crmController.clear();
      _detailsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _dialogSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: Text(widget.title, style: _dialogTitleStyle),
      content: SizedBox(
        width: 1120,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('anesthesiologist-name-field'),
                controller: _nameController,
                decoration: _dialogInputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const Key('anesthesiologist-crm-field'),
                controller: _crmController,
                decoration: _dialogInputDecoration(labelText: 'CRM'),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const Key('anesthesiologist-details-field'),
                controller: _detailsController,
                maxLines: 3,
                decoration: _dialogInputDecoration(
                  labelText: 'Dados complementares',
                  hintText: 'Ex: UF, RQE, equipe, observações',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 26),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('anesthesiologist-add-button'),
                  onPressed: _addDraft,
                  style: _dialogPrimaryButtonStyle(),
                  icon: const Icon(Icons.add),
                  label: Text(widget.addButtonLabel),
                ),
              ),
              const SizedBox(height: 16),
              if (_items.isEmpty) _dialogEmptyState(widget.emptyStateText),
              ..._items.asMap().entries.map((entry) {
                final member = TeamMemberEntry.parse(entry.value);
                final title = member.name;
                final subtitle = member.subtitle;
                return _dialogListTile(
                  title: title,
                  subtitle: subtitle.isEmpty ? null : subtitle,
                  onDelete: () {
                    setState(() {
                      _items.removeAt(entry.key);
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: _dialogSecondaryButtonStyle(),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('anesthesiologist-save-button'),
          style: _dialogPrimaryButtonStyle(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ),
          onPressed: () {
            final draft = _buildDraftItem();
            Navigator.of(
              context,
            ).pop(draft == null ? _items : [..._items, draft]);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class NamedItemsDialog extends StatefulWidget {
  const NamedItemsDialog({
    super.key,
    required this.title,
    required this.label,
    required this.addButtonLabel,
    required this.emptyStateText,
    required this.initialItems,
    this.hintText,
  });

  final String title;
  final String label;
  final String addButtonLabel;
  final String emptyStateText;
  final String? hintText;
  final List<String> initialItems;

  @override
  State<NamedItemsDialog> createState() => _NamedItemsDialogState();
}

class _NamedItemsDialogState extends State<NamedItemsDialog> {
  late final TextEditingController _controller;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _items = List<String>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addDraft() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _items = [..._items, value];
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _dialogSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: Text(widget.title, style: _dialogTitleStyle),
      content: SizedBox(
        width: 1120,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: _dialogInputDecoration(
                  labelText: widget.label,
                  hintText: widget.hintText,
                ),
                onSubmitted: (_) => _addDraft(),
              ),
              const SizedBox(height: 26),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addDraft,
                  style: _dialogPrimaryButtonStyle(),
                  icon: const Icon(Icons.add),
                  label: Text(widget.addButtonLabel),
                ),
              ),
              const SizedBox(height: 16),
              if (_items.isEmpty) _dialogEmptyState(widget.emptyStateText),
              ..._items.asMap().entries.map((entry) {
                return _dialogListTile(
                  title: entry.value,
                  onDelete: () {
                    setState(() {
                      _items.removeAt(entry.key);
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: _dialogSecondaryButtonStyle(),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('named-items-save-button'),
          style: _dialogPrimaryButtonStyle(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ),
          onPressed: () {
            final draft = _controller.text.trim();
            Navigator.of(
              context,
            ).pop(draft.isEmpty ? _items : [..._items, draft]);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class SingleFieldDialog extends StatefulWidget {
  const SingleFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String title;
  final String label;
  final String initialValue;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<SingleFieldDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: widget.label,
            hintText: widget.hintText,
            alignLabelWithHint: widget.maxLines > 1,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ChoiceFieldDialog extends StatelessWidget {
  const ChoiceFieldDialog({
    super.key,
    required this.title,
    required this.options,
    required this.initialValue,
    this.optionLabelBuilder,
  });

  final String title;
  final List<String> options;
  final String initialValue;
  final String Function(String option)? optionLabelBuilder;

  @override
  Widget build(BuildContext context) {
    var selectedValue = initialValue;
    final searchController = TextEditingController();
    var query = '';

    return AlertDialog(
      backgroundColor: _dialogSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: Text(title, style: _dialogTitleStyle),
      content: SizedBox(
        width: 1120,
        child: StatefulBuilder(
          builder: (context, setState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filteredOptions = options.where((option) {
              final label = optionLabelBuilder?.call(option) ?? option;
              return normalizedQuery.isEmpty ||
                  label.toLowerCase().contains(normalizedQuery);
            }).toList();

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: _dialogSearchDecoration(),
                    onChanged: (value) => setState(() => query = value),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900 ? 2 : 1;
                      final columnChildren = List.generate(
                        columns,
                        (_) => <Widget>[],
                      );

                      for (var i = 0; i < filteredOptions.length; i++) {
                        final option = filteredOptions[i];
                        final label =
                            optionLabelBuilder?.call(option) ?? option;
                        columnChildren[i % columns].add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _DialogOptionCard(
                              label: label,
                              selected: selectedValue == option,
                              onTap: () {
                                setState(() {
                                  selectedValue = option;
                                });
                              },
                            ),
                          ),
                        );
                      }

                      if (filteredOptions.isEmpty) {
                        return _dialogEmptyState(
                          'Nenhuma opção encontrada para a busca.',
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < columns; i++) ...[
                            Expanded(
                              child: Column(children: columnChildren[i]),
                            ),
                            if (i != columns - 1) const SizedBox(width: 16),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          style: _dialogSecondaryButtonStyle(),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: _dialogSecondaryButtonStyle(),
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Limpar'),
        ),
        FilledButton(
          style: _dialogPrimaryButtonStyle(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ),
          onPressed: () => Navigator.of(context).pop(selectedValue),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ListFieldDialog extends StatefulWidget {
  const ListFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialItems,
    this.suggestions = const [],
    this.hintText,
    this.clearButtonLabel = 'Limpar',
    this.initialMarkedNone = false,
    this.supportsMarkedNone = false,
  });

  final String title;
  final String label;
  final List<String> initialItems;
  final List<String> suggestions;
  final String? hintText;
  final String clearButtonLabel;
  final bool initialMarkedNone;
  final bool supportsMarkedNone;

  @override
  State<ListFieldDialog> createState() => _ListFieldDialogState();
}

class _ListFieldDialogState extends State<ListFieldDialog> {
  late final TextEditingController _controller;
  late final TextEditingController _searchController;
  late Set<String> _selectedSuggestions;
  late List<String> _manualEntries;
  late bool _markedNone;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedSuggestions = widget.initialItems
        .where(widget.suggestions.contains)
        .toSet();
    _manualEntries = widget.initialItems
        .where((item) => !widget.suggestions.contains(item))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _markedNone =
        widget.supportsMarkedNone &&
        widget.initialMarkedNone &&
        widget.initialItems.isEmpty;
    _controller = TextEditingController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _draftItems() {
    return _controller.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _addManualItems() {
    final draftItems = _draftItems();
    if (draftItems.isEmpty) return;
    setState(() {
      _manualEntries = [..._manualEntries, ...draftItems];
      _markedNone = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _dialogSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: Text(widget.title, style: _dialogTitleStyle),
      content: SizedBox(
        width: 1120,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.suggestions.isNotEmpty) ...[
                TextField(
                  controller: _searchController,
                  decoration: _dialogSearchDecoration(),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 22),
                Builder(
                  builder: (context) {
                    final normalizedQuery = _query.trim().toLowerCase();
                    final filteredSuggestions = widget.suggestions
                        .where(
                          (item) =>
                              normalizedQuery.isEmpty ||
                              item.toLowerCase().contains(normalizedQuery),
                        )
                        .toList();

                    if (filteredSuggestions.isEmpty) {
                      return _dialogEmptyState(
                        'Nenhuma opção encontrada para a busca.',
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900 ? 2 : 1;
                        final columnChildren = List.generate(
                          columns,
                          (_) => <Widget>[],
                        );

                        for (var i = 0; i < filteredSuggestions.length; i++) {
                          final item = filteredSuggestions[i];
                          columnChildren[i % columns].add(
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _DialogOptionCard(
                                label: item,
                                selected: _selectedSuggestions.contains(item),
                                onTap: () {
                                  setState(() {
                                    if (_selectedSuggestions.contains(item)) {
                                      _selectedSuggestions.remove(item);
                                    } else {
                                      _selectedSuggestions.add(item);
                                      _markedNone = false;
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < columns; i++) ...[
                              Expanded(
                                child: Column(children: columnChildren[i]),
                              ),
                              if (i != columns - 1) const SizedBox(width: 16),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: _dialogInputDecoration(
                  labelText: widget.label,
                  hintText: widget.hintText ?? 'Um item por linha',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addManualItems,
                  style: _dialogPrimaryButtonStyle(),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                ),
              ),
              const SizedBox(height: 16),
              if (_manualEntries.isEmpty)
                _dialogEmptyState('Nenhum item manual adicionado.')
              else
                ..._manualEntries.asMap().entries.map(
                  (entry) => _dialogListTile(
                    title: entry.value,
                    onDelete: () {
                      setState(() {
                        _manualEntries.removeAt(entry.key);
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: _dialogSecondaryButtonStyle(),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: _dialogSecondaryButtonStyle(),
          onPressed: () {
            if (widget.supportsMarkedNone) {
              Navigator.of(context).pop(
                const ListFieldDialogResult(
                  items: <String>[],
                  markedNone: true,
                ),
              );
              return;
            }
            Navigator.of(context).pop(const <String>[]);
          },
          child: Text(widget.clearButtonLabel),
        ),
        FilledButton(
          style: _dialogPrimaryButtonStyle(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          ),
          onPressed: () {
            final items = [
              ..._selectedSuggestions,
              ..._manualEntries,
              ..._draftItems(),
            ];
            if (widget.supportsMarkedNone) {
              Navigator.of(context).pop(
                ListFieldDialogResult(
                  items: items,
                  markedNone: _markedNone && items.isEmpty,
                ),
              );
              return;
            }
            Navigator.of(context).pop(items);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ListFieldDialogResult {
  const ListFieldDialogResult({required this.items, required this.markedNone});

  final List<String> items;
  final bool markedNone;
}

class PatientIdentificationDialog extends StatefulWidget {
  const PatientIdentificationDialog({super.key, required this.initialPatient});

  final Patient initialPatient;

  @override
  State<PatientIdentificationDialog> createState() =>
      _PatientIdentificationDialogState();
}

class _PatientIdentificationDialogState
    extends State<PatientIdentificationDialog> {
  static const List<String> _asaOptions = ['I', 'II', 'III', 'IV', 'V'];
  static const List<String> _informedConsentOptions = [
    'Assinado',
    'Não assinado',
  ];
  static const List<String> _commonAllergies = [
    'Látex',
    'Dipirona',
    'Penicilina',
    'Iodo/contraste',
  ];
  static const List<String> _commonRestrictions = [
    'Não aceita transfusão',
    'Recusa opioide',
    'Recusa anestesia regional',
  ];
  static const List<String> _commonMedications = [
    'AAS',
    'Clopidogrel',
    'Insulina',
    'Metformina',
    'Beta-bloqueador',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _postnatalAgeController;
  late final TextEditingController _gestationalAgeController;
  late final TextEditingController _correctedGestationalAgeController;
  late final TextEditingController _birthWeightController;
  late String _selectedInformedConsentStatus;
  late final TextEditingController _allergiesController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _medicationsController;
  late Set<String> _selectedAllergies;
  late Set<String> _selectedRestrictions;
  late Set<String> _selectedMedications;
  late bool _allergiesMarkedNone;
  late bool _restrictionsMarkedNone;
  late bool _medicationsMarkedNone;
  late String _selectedAsa;
  late PatientPopulation _selectedPopulation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialPatient.name);
    _ageController = TextEditingController(
      text: widget.initialPatient.age > 0
          ? widget.initialPatient.age.toString()
          : '',
    );
    _weightController = TextEditingController(
      text: widget.initialPatient.weightKg > 0
          ? widget.initialPatient.weightKg.toStringAsFixed(0)
          : '',
    );
    _heightController = TextEditingController(
      text: widget.initialPatient.heightMeters > 0
          ? (widget.initialPatient.heightMeters * 100)
                .toStringAsFixed(0)
                .replaceAll('.', ',')
          : '',
    );
    _postnatalAgeController = TextEditingController(
      text: widget.initialPatient.postnatalAgeDays > 0
          ? widget.initialPatient.postnatalAgeDays.toString()
          : '',
    );
    _gestationalAgeController = TextEditingController(
      text: widget.initialPatient.gestationalAgeWeeks > 0
          ? widget.initialPatient.gestationalAgeWeeks.toString()
          : '',
    );
    _correctedGestationalAgeController = TextEditingController(
      text: widget.initialPatient.correctedGestationalAgeWeeks > 0
          ? widget.initialPatient.correctedGestationalAgeWeeks.toString()
          : '',
    );
    _birthWeightController = TextEditingController(
      text: widget.initialPatient.birthWeightKg > 0
          ? widget.initialPatient.birthWeightKg
                .toStringAsFixed(2)
                .replaceAll('.', ',')
          : '',
    );
    _allergiesController = TextEditingController(
      text: widget.initialPatient.allergies
          .where((item) => !_commonAllergies.contains(item))
          .join('\n'),
    );
    _restrictionsController = TextEditingController(
      text: widget.initialPatient.restrictions
          .where((item) => !_commonRestrictions.contains(item))
          .join('\n'),
    );
    _medicationsController = TextEditingController(
      text: widget.initialPatient.medications
          .where((item) => !_commonMedications.contains(item))
          .join('\n'),
    );
    _selectedAllergies = widget.initialPatient.allergies
        .where(_commonAllergies.contains)
        .toSet();
    _selectedRestrictions = widget.initialPatient.restrictions
        .where(_commonRestrictions.contains)
        .toSet();
    _selectedMedications = widget.initialPatient.medications
        .where(_commonMedications.contains)
        .toSet();
    _allergiesMarkedNone = widget.initialPatient.allergiesMarkedNone;
    _restrictionsMarkedNone = widget.initialPatient.restrictionsMarkedNone;
    _medicationsMarkedNone = widget.initialPatient.medicationsMarkedNone;
    _selectedAsa = _asaOptions.contains(widget.initialPatient.asa)
        ? widget.initialPatient.asa
        : '';
    _selectedInformedConsentStatus =
        _informedConsentOptions.contains(
          widget.initialPatient.informedConsentStatus,
        )
        ? widget.initialPatient.informedConsentStatus
        : '';
    _selectedPopulation = widget.initialPatient.population;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _postnatalAgeController.dispose();
    _gestationalAgeController.dispose();
    _correctedGestationalAgeController.dispose();
    _birthWeightController.dispose();
    _allergiesController.dispose();
    _restrictionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _combinedItems(
    Set<String> selectedItems,
    TextEditingController controller,
  ) => [...selectedItems, ..._lines(controller.text)];

  String _summaryForSelection(
    List<String> items, {
    required String emptyLabel,
  }) {
    if (items.isEmpty) return emptyLabel;
    if (items.length <= 2) return items.join(' • ');
    return '${items.take(2).join(' • ')} +${items.length - 2}';
  }

  String _statusSummaryForSelection(
    List<String> items, {
    required bool markedNone,
    required String noneLabel,
    required String unsetLabel,
  }) {
    if (items.isNotEmpty) {
      return _summaryForSelection(items, emptyLabel: unsetLabel);
    }
    return markedNone ? noneLabel : unsetLabel;
  }

  Future<void> _editPopulation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Perfil do paciente',
        options: PatientPopulation.values.map((item) => item.code).toList(),
        initialValue: _selectedPopulation.code,
        optionLabelBuilder: (option) =>
            PatientPopulationX.fromCode(option).label,
      ),
    );

    if (result == null) return;
    setState(() => _selectedPopulation = PatientPopulationX.fromCode(result));
  }

  Future<void> _editAsa() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Classificação ASA',
        options: _asaOptions,
        initialValue: _selectedAsa,
        optionLabelBuilder: (option) => 'ASA $option',
      ),
    );

    if (result == null) return;
    setState(() => _selectedAsa = result);
  }

  Future<void> _editInformedConsent() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Termo de consentimento',
        options: _informedConsentOptions,
        initialValue: _selectedInformedConsentStatus,
      ),
    );

    if (result == null) return;
    setState(() => _selectedInformedConsentStatus = result);
  }

  Future<void> _editListSelection({
    required String title,
    required String label,
    required List<String> suggestions,
    required Set<String> selectedItems,
    required TextEditingController controller,
    required bool markedNone,
    required ValueChanged<bool> onMarkedNoneChanged,
    String? hintText,
    String clearButtonLabel = 'Limpar',
  }) async {
    final result = await showDialog<ListFieldDialogResult>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: title,
        label: label,
        initialItems: _combinedItems(selectedItems, controller),
        suggestions: suggestions,
        hintText: hintText,
        clearButtonLabel: clearButtonLabel,
        initialMarkedNone: markedNone,
        supportsMarkedNone: true,
      ),
    );

    if (result == null) return;
    setState(() {
      selectedItems
        ..clear()
        ..addAll(result.items.where(suggestions.contains));
      controller.text = result.items
          .where((item) => !suggestions.contains(item))
          .join('\n');
      onMarkedNoneChanged(result.markedNone);
    });
  }

  Widget _selectionButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: const BorderSide(color: _dialogFieldBorderColor),
          backgroundColor: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? value : 'Selecionar',
                    style: TextStyle(
                      color: hasValue
                          ? const Color(0xFF17324D)
                          : const Color(0xFF7A8EA5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: _dialogActionColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Identificação do paciente'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _selectionButton(
                label: 'Perfil do paciente',
                value: _selectedPopulation.label,
                onTap: _editPopulation,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText:
                            _selectedPopulation == PatientPopulation.neonatal
                            ? 'Idade (anos, se aplicável)'
                            : 'Idade (anos)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Altura (cm)',
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedPopulation != PatientPopulation.adult) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postnatalAgeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Idade pós-natal (dias)',
                        ),
                      ),
                    ),
                    if (_selectedPopulation == PatientPopulation.neonatal) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _birthWeightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Peso ao nascer (kg)',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (_selectedPopulation == PatientPopulation.neonatal) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gestationalAgeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'IG ao nascer (semanas)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _correctedGestationalAgeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'IG corrigida (semanas)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _selectionButton(
                label: 'Classificação ASA',
                value: _selectedAsa.isEmpty ? '' : 'ASA $_selectedAsa',
                onTap: _editAsa,
              ),
              const SizedBox(height: 12),
              _selectionButton(
                label: 'Termo de consentimento',
                value: _selectedInformedConsentStatus,
                onTap: _editInformedConsent,
              ),
              const SizedBox(height: 12),
              _selectionButton(
                label: 'Alergias',
                value: _statusSummaryForSelection(
                  _combinedItems(_selectedAllergies, _allergiesController),
                  markedNone: _allergiesMarkedNone,
                  noneLabel: 'Nenhuma alergia registrada',
                  unsetLabel: 'Não informado',
                ),
                onTap: () => _editListSelection(
                  title: 'Alergias',
                  label: 'Alergias',
                  suggestions: _commonAllergies,
                  selectedItems: _selectedAllergies,
                  controller: _allergiesController,
                  markedNone: _allergiesMarkedNone,
                  onMarkedNoneChanged: (value) => _allergiesMarkedNone = value,
                  hintText: 'Uma alergia por linha',
                  clearButtonLabel: 'Sem alergias',
                ),
              ),
              const SizedBox(height: 12),
              _selectionButton(
                label: 'Restrições',
                value: _statusSummaryForSelection(
                  _combinedItems(
                    _selectedRestrictions,
                    _restrictionsController,
                  ),
                  markedNone: _restrictionsMarkedNone,
                  noneLabel: 'Nenhuma restrição registrada',
                  unsetLabel: 'Não informado',
                ),
                onTap: () => _editListSelection(
                  title: 'Restrições',
                  label: 'Restrições',
                  suggestions: _commonRestrictions,
                  selectedItems: _selectedRestrictions,
                  controller: _restrictionsController,
                  markedNone: _restrictionsMarkedNone,
                  onMarkedNoneChanged: (value) =>
                      _restrictionsMarkedNone = value,
                  hintText: 'Uma restrição por linha',
                  clearButtonLabel: 'Sem restrições',
                ),
              ),
              const SizedBox(height: 12),
              _selectionButton(
                label: 'Medicações em uso',
                value: _statusSummaryForSelection(
                  _combinedItems(_selectedMedications, _medicationsController),
                  markedNone: _medicationsMarkedNone,
                  noneLabel: 'Nenhuma medicação registrada',
                  unsetLabel: 'Não informado',
                ),
                onTap: () => _editListSelection(
                  title: 'Medicações em uso',
                  label: 'Medicações',
                  suggestions: _commonMedications,
                  selectedItems: _selectedMedications,
                  controller: _medicationsController,
                  markedNone: _medicationsMarkedNone,
                  onMarkedNoneChanged: (value) =>
                      _medicationsMarkedNone = value,
                  hintText: 'Uma medicação por linha',
                  clearButtonLabel: 'Sem medicações',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.initialPatient.copyWith(
              name: _nameController.text.trim(),
              age: int.tryParse(_ageController.text.trim()) ?? 0,
              weightKg:
                  double.tryParse(
                    _weightController.text.replaceAll(',', '.'),
                  ) ??
                  0,
              heightMeters:
                  (double.tryParse(
                        _heightController.text.replaceAll(',', '.'),
                      ) ??
                      0) /
                  100,
              population: _selectedPopulation,
              postnatalAgeDays:
                  int.tryParse(_postnatalAgeController.text.trim()) ?? 0,
              gestationalAgeWeeks:
                  int.tryParse(_gestationalAgeController.text.trim()) ?? 0,
              correctedGestationalAgeWeeks:
                  int.tryParse(
                    _correctedGestationalAgeController.text.trim(),
                  ) ??
                  0,
              birthWeightKg:
                  double.tryParse(
                    _birthWeightController.text.replaceAll(',', '.'),
                  ) ??
                  0,
              asa: _selectedAsa,
              allergies: [
                ..._selectedAllergies,
                ..._lines(_allergiesController.text),
              ],
              allergiesMarkedNone:
                  _allergiesMarkedNone &&
                  _combinedItems(
                    _selectedAllergies,
                    _allergiesController,
                  ).isEmpty,
              restrictions: [
                ..._selectedRestrictions,
                ..._lines(_restrictionsController.text),
              ],
              restrictionsMarkedNone:
                  _restrictionsMarkedNone &&
                  _combinedItems(
                    _selectedRestrictions,
                    _restrictionsController,
                  ).isEmpty,
              medications: [
                ..._selectedMedications,
                ..._lines(_medicationsController.text),
              ],
              medicationsMarkedNone:
                  _medicationsMarkedNone &&
                  _combinedItems(
                    _selectedMedications,
                    _medicationsController,
                  ).isEmpty,
              informedConsentStatus: _selectedInformedConsentStatus,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
