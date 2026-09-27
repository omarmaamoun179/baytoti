import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_query.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import 'search_option_sheet.dart';

Future<void> pickCategory(BuildContext context, SearchState state) async {
  final cubit = context.read<SearchCubit>();
  final pick = await showSearchOptionSheet<String?>(
    context,
    title: 'search_filter_category'.tr(),
    selected: state.query.categoryId,
    options: [
      SearchOption(null, 'search_filter_all'.tr()),
      for (final facet in state.facets.categories)
        SearchOption(facet.value, facet.label, count: facet.count),
    ],
  );
  if (pick != null) cubit.selectCategory(pick.value);
}

Future<void> pickCity(BuildContext context, SearchState state) async {
  final cubit = context.read<SearchCubit>();
  final pick = await showSearchOptionSheet<String?>(
    context,
    title: 'search_filter_city'.tr(),
    selected: state.query.city,
    options: [
      SearchOption(null, 'search_filter_all'.tr()),
      for (final facet in state.facets.cities)
        SearchOption(facet.value, facet.label, count: facet.count),
    ],
  );
  if (pick != null) cubit.selectCity(pick.value);
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
