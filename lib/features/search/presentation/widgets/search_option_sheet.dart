import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/sheet_handle.dart';

class SearchOption<T> {
  final T value;
  final String label;
  final int? count;

  const SearchOption(this.value, this.label, {this.count});
}

class OptionPick<T> {
  final T value;

  const OptionPick(this.value);
}

Future<OptionPick<T>?> showSearchOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SearchOption<T>> options,
  required T selected,
}) =>
    showModalBottomSheet<OptionPick<T>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => SearchOptionSheet<T>(
        title: title,
        options: options,
        selected: selected,
      ),
    );

class SearchOptionSheet<T> extends StatelessWidget {
  final String title;
  final List<SearchOption<T>> options;
  final T selected;

  const SearchOptionSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle()),
              Text(title, style: AppStrings.w800(20, 1.2).c(p.text)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in options) _buildRow(context, p, option),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppPalette p, SearchOption<T> option) {
    final isSelected = option.value == selected;
    final count = option.count;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(OptionPick<T>(option.value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(border: Border(bottom: p.hairline)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: AppStrings.w600(13, 1.3)
                      .c(isSelected ? p.accent700 : p.text),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 10),
                Text(
                  '$count',
                  style: AppStrings.w400(11, 1).c(p.neutral600),
                ),
              ],
              if (isSelected) ...[
                const SizedBox(width: 10),
                AppIcon(
                  AppIcons.check,
                  size: 14,
                  color: p.accent700,
                  strokeWidth: 2.4,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
