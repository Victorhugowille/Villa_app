import 'package:flutter/material.dart';
import 'package:villabistromobile/models/print_style_settings.dart';

Widget buildTextAndStyleEditor(
  String title,
  String initialValue,
  ValueChanged<String> onTextChanged,
  PrintStyle style,
  ValueChanged<PrintStyle> onStyleChanged,
) {
  final controller = TextEditingController(text: initialValue);

  controller.addListener(() {
    onTextChanged(controller.text);
  });

  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        buildStyleControls(style, onStyleChanged),
        const SizedBox(height: 8),
        const Divider(),
      ],
    ),
  );
}

Widget buildStyleEditor(
    String title, PrintStyle style, ValueChanged<PrintStyle> onUpdate) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          buildStyleControls(style, onUpdate),
        ],
      ),
    ),
  );
}

Widget buildStyleControls(
    PrintStyle style, ValueChanged<PrintStyle> onUpdate) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tamanho da Fonte'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => onUpdate(style.copyWith(
                    fontSize: (style.fontSize - 1).clamp(6.0, 30.0))),
              ),
              Text(style.fontSize.toStringAsFixed(0)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => onUpdate(style.copyWith(
                    fontSize: (style.fontSize + 1).clamp(6.0, 30.0))),
              ),
            ],
          ),
        ],
      ),
      SwitchListTile(
        title: const Text('Negrito'),
        value: style.isBold,
        onChanged: (isBold) => onUpdate(style.copyWith(isBold: isBold)),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
      const SizedBox(height: 8),
      const Text('Alinhamento'),
      const SizedBox(height: 8),
      SegmentedButton<CrossAxisAlignment>(
        segments: const [
          ButtonSegment(
              value: CrossAxisAlignment.start,
              icon: Icon(Icons.format_align_left)),
          ButtonSegment(
              value: CrossAxisAlignment.center,
              icon: Icon(Icons.format_align_center)),
          ButtonSegment(
              value: CrossAxisAlignment.end,
              icon: Icon(Icons.format_align_right)),
        ],
        selected: {style.alignment},
        onSelectionChanged: (newSelection) =>
            onUpdate(style.copyWith(alignment: newSelection.first)),
      ),
    ],
  );
}