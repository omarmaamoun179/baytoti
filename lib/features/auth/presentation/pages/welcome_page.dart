import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_assets.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/network_photo.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final insets = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: p.text,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const NetworkPhoto(url: AppAssets.welcomeHero),
            DecoratedBox(decoration: BoxDecoration(gradient: _scrim(p))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrand(context, insets.top),
                const Spacer(),
                _buildActions(context, insets.bottom),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _scrim(AppPalette p) {
    final clear = p.text.withValues(alpha: 0);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        p.text.withValues(alpha: .78),
        p.text.withValues(alpha: .6),
        clear,
        clear,
        p.text.withValues(alpha: .6),
        p.text.withValues(alpha: .92),
      ],
      stops: const [0, .2, .42, .58, .72, 1],
    );
  }

  Widget _buildBrand(BuildContext context, double top) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, top + 48, 24, 0),
      child: Column(
        children: [
          Text('بيتوتي', style: AppStrings.w800(40, 1).c(p.surface)),
          const SizedBox(height: 12),
          Text(
            'welcome_tagline'.tr(),
            textAlign: TextAlign.center,
            style: AppStrings.w800(13.5, 1).c(p.surface),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              'welcome_sub'.tr(),
              textAlign: TextAlign.center,
              style: AppStrings.w400(
                12.5,
                1.8,
              ).c(p.surface.withValues(alpha: .85)),
            ),
          ),
          const SizedBox(height: 8),
          AppIcon(
            AppIcons.heart,
            size: 13,
            color: p.amber,
            strokeWidth: 0,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, double bottom) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 30 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AppButton(
          //   label: 'welcome_browse'.tr(),
          //   style: AppButtonStyle.light,
          //   pill: true,
          //   height: 54,
          //   fontSize: 14.5,
          //   onPressed: () => context.go(AppRoutes.home),
          // ),
          // const SizedBox(height: 11),
          AppButton(
            label: 'welcome_login'.tr(),
            style: AppButtonStyle.ghost,
            pill: true,
            height: 54,
            fontSize: 14.5,
            onPressed: () => context.push(AppRoutes.authFor()),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 34,
            child: AppTextButton(
              label: 'welcome_signup'.tr(),
              style: AppStrings.w600(
                12.5,
                1,
              ).c(p.surface.withValues(alpha: .85)),
              onPressed: () => context.push(AppRoutes.authFor(signup: true)),
            ),
          ),
        ],
      ),
    );
  }
}
