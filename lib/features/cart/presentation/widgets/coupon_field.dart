import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

class CouponField extends StatefulWidget {
  final String? appliedCode;
  final bool isApplying;
  final ValueChanged<String> onApply;

  const CouponField({
    super.key,
    required this.appliedCode,
    required this.isApplying,
    required this.onApply,
  });

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.appliedCode ?? '');

  @override
  void didUpdateWidget(CouponField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final applied = widget.appliedCode;
    if (applied != null && applied != oldWidget.appliedCode) {
      _controller.text = applied;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty || widget.isApplying) return;
    FocusScope.of(context).unfocus();
    widget.onApply(code);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(10);
    final border = BoxDecoration(
      border: Border.all(color: p.divider),
      borderRadius: radius,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: AlignmentDirectional.centerStart,
              decoration: border,
              child: TextField(
                controller: _controller,
                enabled: !widget.isApplying,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _submit(),
                style: AppStrings.w600(12, 1.2).c(p.text),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'cart_coupon_hint'.tr(),
                  hintStyle: AppStrings.w400(12, 1).c(p.neutral600),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: widget.isApplying ? null : _submit,
              borderRadius: radius,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: border,
                child: widget.isApplying
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: p.accent,
                        ),
                      )
                    : Text(
                        'cart_apply'.tr(),
                        style: AppStrings.w800(11, 1).c(p.text),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
