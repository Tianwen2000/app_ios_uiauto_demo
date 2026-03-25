import 'package:flutter/material.dart';

import '../models/demo_product.dart';
import '../widgets/demo_product_card.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({
    super.key,
    required this.username,
    required this.cartCount,
    required this.favoriteCount,
    required this.products,
    required this.selectedCategory,
    required this.searchQuery,
    required this.favoriteIds,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggleFavorite,
    required this.onAddToCart,
  });

  final String username;
  final int cartCount;
  final int favoriteCount;
  final List<DemoProduct> products;
  final String selectedCategory;
  final String searchQuery;
  final Set<String> favoriteIds;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onToggleFavorite;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          pinned: true,
          expandedHeight: 200,
          title: const Text('Studio Cart'),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Badge.count(
                count: cartCount,
                isLabelVisible: cartCount > 0,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    theme.colorScheme.primary.withValues(alpha: 0.94),
                    theme.colorScheme.secondary.withValues(alpha: 0.88),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Good to see you, $username',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$favoriteCount favorites saved • $cartCount items queued',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: <Widget>[
                TextField(
                  onChanged: onSearchChanged,
                  controller: TextEditingController.fromValue(
                    TextEditingValue(
                      text: searchQuery,
                      selection: TextSelection.collapsed(
                        offset: searchQuery.length,
                      ),
                    ),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search items or moods',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: demoCategories.map((String category) {
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => onCategoryChanged(category),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Try another keyword or switch categories.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList.separated(
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) {
                final product = products[index];
                return DemoProductCard(
                  product: product,
                  isFavorite: favoriteIds.contains(product.id),
                  onFavoritePressed: () => onToggleFavorite(product.id),
                  onAddPressed: () {
                    onAddToCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to your bag'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 14),
            ),
          ),
      ],
    );
  }
}
