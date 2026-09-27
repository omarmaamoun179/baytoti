import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cart_actions.dart';
import '../../domain/entities/product_detail.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../widgets/product_add_bar.dart';
import '../widgets/product_family_row.dart';
import '../widgets/product_gallery.dart';
import '../widgets/product_intro.dart';
import '../widgets/product_meta_rows.dart';
import '../widgets/product_reviews.dart';

class ProductPage extends StatelessWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<ProductCubit>()..load(productId),
      child: const _ProductView(),
    );
  }
}

class _ProductView extends StatelessWidget {
  const _ProductView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocListener<ProductCubit, ProductState>(
      listenWhen: (_, current) =>
          current.status == ProductStatus.loaded &&
          current.errorMessage != null,
      listener: (context, state) =>
          showAppToast(context, state.errorMessage!, isError: true),
      child: Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            AppHeader(
              kicker: 'kicker_product'.tr(),
              title: 'title_product'.tr(),
              onBack: () => context.pop(),
            ),
            Expanded(
              child: BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  final product = state.product;
                  if (product != null) {
                    return _buildLoaded(context, state, product);
                  }
                  if (state.status == ProductStatus.error) {
                    return ErrorView(
                      message: state.errorMessage,
                      onRetry: context.read<ProductCubit>().retry,
                    );
                  }
                  return const LoadingView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    ProductState state,
    ProductDetail product,
  ) {
    final cubit = context.read<ProductCubit>();
    final isAdding = context.select<CartCubit, bool>(
      (cart) => cart.state.isAdding,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ProductGallery(images: product.images, badge: product.badge),
              ProductIntro(
                product: product,
                onFavourite: () {
                  if (requireSignIn(context)) cubit.toggleFavourite();
                },
              ),
              ProductFamilyRow(
                family: product.family,
                onTap: () => context.openFamily(product.family.slug),
              ),
              ProductMetaRows(product: product),
              if (product.description.isNotEmpty)
                _buildDescription(context, product.description)
              else
                const SizedBox(height: 16),
              if (state.reviews.isNotEmpty)
                ProductReviews(reviews: state.reviews),
              const SizedBox(height: 12),
            ],
          ),
        ),
        ProductAddBar(
          priceFils: product.price.fils,
          quantity: state.quantity,
          enabled: state.canOrder,
          isAdding: isAdding,
          onDecrement: state.canDecrement ? cubit.decrement : null,
          onIncrement: state.canIncrement ? cubit.increment : null,
          onAdd: () => addToCart(
            context,
            product.id,
            quantity: state.quantity,
            openCart: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, String description) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('product_description'.tr()),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppStrings.w400(13, 1.75).c(p.neutral800),
          ),
        ],
      ),
    );
  }
}
