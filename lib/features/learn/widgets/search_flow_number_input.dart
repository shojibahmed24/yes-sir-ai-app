// Question-number input for the new search flow. Numeric
// keyboard; accepts Latin AND Bangla digits (normalised by
// normalizeQuestionNumber). There is deliberately NO page field
// anywhere in this flow (user order: page number removed).
import 'package:flutter/material.dart';

class SearchFlowNumberInput extends StatelessWidget {
  const SearchFlowNumberInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final void Function(String) onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}
