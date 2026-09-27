import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_query.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import 'search_option_sheet.dart';

Future<void> pickCategory(BuildContext context) async {
  final cubit = context.read<SearchCubit>();
  if (cubit.state.categories.isEmpty) await cubit.loadCategories();

  final categories = cubit.state.categories;
  if (categories.isEmpty || !context.mounted) return;

  final pick = await showSearchOptionSheet<String?>(
    context,
    title: 'search_filter_category'.tr(),
    selected: cubit.state.query.categorySlug,
    options: [
      SearchOption(null, 'search_filter_all'.tr()),
      for (final category in categories)
        SearchOption(category.slug, category.name),
    ],
  );
  if (pick != null) cubit.selectCategory(pick.value);
}

Future<void> pickPriceOrder(BuildContext context, SearchState state) async {
  final cubit = context.read<SearchCubit>();
  final sort = state.query.sort;
  final pick = await showSearchOptionSheet<SearchSort?>(
    context,
    title: 'search_filter_price'.tr(),
    selected: sort.isByPrice ? sort : null,
    options: [
      SearchOption(null, 'search_filter_all'.tr()),
      for (final option in SearchSort.byPrice)
        SearchOption(option, option.optionKey.tr()),
    ],
  );
  if (pick != null) cubit.selectPriceSort(pick.value);
}

Future<void> pickSort(BuildContext context, SearchState state) async {
  final cubit = context.read<SearchCubit>();
  final pick = await showSearchOptionSheet<SearchSort>(
    context,
    title: 'search_sort_title'.tr(),
    selected: state.query.sort,
    options: [
      for (final option in SearchSort.values)
        SearchOption(option, option.optionKey.tr()),
    ],
  );
  if (pick != null) cubit.setSort(pick.value);
}
