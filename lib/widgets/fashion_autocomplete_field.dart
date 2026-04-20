import 'package:flutter/material.dart';

class FashionAutocompleteField extends StatelessWidget {
  final String label;
  final List<String> options;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;

  const FashionAutocompleteField({
    super.key,
    required this.label,
    required this.options,
    required this.controller,
    required this.enabled,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      displayStringForOption: (String option) => option,

      optionsBuilder: (TextEditingValue textEditingValue) {
        if (!enabled) return const Iterable<String>.empty();
        if (textEditingValue.text.isEmpty || options.contains(textEditingValue.text)) {
          return options;
        }
        return options.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },

      onSelected: (String selection) {
        controller.text = selection;
        FocusScope.of(context).unfocus();
      },

      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        // Đồng bộ dữ liệu ban đầu
        if (fieldController.text != controller.text) {
          fieldController.text = controller.text;
        }

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          enabled: enabled,
          style: const TextStyle(color: Colors.black, fontSize: 14),
          onChanged: (value) => controller.text = value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 12),
            prefixIcon: Icon(icon, size: 18, color: Colors.pinkAccent.withOpacity(0.5)),
            suffixIcon: enabled ? const Icon(Icons.arrow_drop_down, color: Colors.white24) : null,
            isDense: true,
            filled: true,
            fillColor: enabled ? Colors.pinkAccent.withOpacity(0.02) : Colors.black.withOpacity(0.03),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
            ),

            // VIỀN KHI CHO PHÉP EDIT NHƯNG CHƯA TRỎ VÀO
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.3)),
            ),

            // VIỀN KHI ĐANG NHẬP (HỒNG ĐẬM)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
            ),
          ),
        );
      },

      // PHẦN QUAN TRỌNG: Sửa lại vị trí hiển thị
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 72,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.black12, height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    visualDensity: VisualDensity.compact,
                    title: Text(option, style: const TextStyle(color: Colors.black, fontSize: 13)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}