import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../../domain/entities/home_feed.dart';

class HomeBannerStrip extends StatelessWidget {
  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onTap;

  const HomeBannerStrip({
    super.key,
    required this.banners,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final cardWidth = banners.length == 1 ? width : width - 28;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < banners.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SizedBox(
                width: cardWidth,
                child: _BannerCard(
                  banner: banners[i],
                  onTap: () => onTap(banners[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final HomeBanner banner;
  final VoidCallback onTap;

  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.onAccent;
    final action = banner.actionLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 164),
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (banner.imageUrl case final url?)
              Positioned.fill(
                child: NetworkPhoto(url: url, placeholderColor: p.accent),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      p.accent,
                      p.accent.withValues(alpha: .8),
                      p.accent.withValues(alpha: .15),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStrings.w800(22, 1.15).c(ink),
                    ),
                  ),
                  if (banner.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        banner.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppStrings.w400(12, 1.6)
                            .c(ink.withValues(alpha: .9)),
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 7,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: ink.withValues(alpha: .55)),
                      ),
                      child: Text(action, style: AppStrings.w800(11, 1).c(ink)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
