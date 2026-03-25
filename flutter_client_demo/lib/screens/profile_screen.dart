import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.username,
    required this.favoriteCount,
    required this.cartCount,
    required this.notificationsEnabled,
    required this.expressCheckoutEnabled,
    required this.darkModeEnabled,
    required this.monthlyBudget,
    required this.onNotificationsChanged,
    required this.onExpressCheckoutChanged,
    required this.onDarkModeChanged,
    required this.onBudgetChanged,
    required this.onLogout,
  });

  final String username;
  final int favoriteCount;
  final int cartCount;
  final bool notificationsEnabled;
  final bool expressCheckoutEnabled;
  final bool darkModeEnabled;
  final double monthlyBudget;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onExpressCheckoutChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<double> onBudgetChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Account',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    username,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$favoriteCount favorites • $cartCount bag items',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: notificationsEnabled,
                  title: const Text('Release notifications'),
                  subtitle: const Text('Notify me when new drops go live'),
                  onChanged: onNotificationsChanged,
                ),
                SwitchListTile(
                  value: expressCheckoutEnabled,
                  title: const Text('Express checkout'),
                  subtitle: const Text(
                    'Save payment preference for faster orders',
                  ),
                  onChanged: onExpressCheckoutChanged,
                ),
                SwitchListTile(
                  value: darkModeEnabled,
                  title: const Text('Night preview'),
                  subtitle: const Text(
                    'Preview this client in a darker palette',
                  ),
                  onChanged: onDarkModeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Monthly accessory budget',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${monthlyBudget.round()}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    value: monthlyBudget,
                    min: 500,
                    max: 3000,
                    divisions: 10,
                    label: monthlyBudget.round().toString(),
                    onChanged: onBudgetChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: onLogout,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
