import 'package:flutter/material.dart';

import '../../domain/entities/home_feed.dart';
import 'trusted_store_card.dart';

class TrustedStoreRail extends StatelessWidget {
  final List<TrustedStore> stores;
  final ValueChanged<TrustedStore> onTap;

  const TrustedStoreRail({
    super.key,
    required this.stores,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stores.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            TrustedStoreCard(
              store: stores[i],
              width: TrustedStoreCard.railWidth,
              onTap: () => onTap(stores[i]),
            ),
          ],
        ],
      ),
    );
  }
}
