import 'package:flutter/material.dart';

import 'models/demo_product.dart';
import 'screens/discover_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

class ClientDemoApp extends StatefulWidget {
  const ClientDemoApp({super.key});

  @override
  State<ClientDemoApp> createState() => _ClientDemoAppState();
}

class _ClientDemoAppState extends State<ClientDemoApp> {
  final Set<String> _favoriteIds = <String>{};
  bool _signedIn = false;
  bool _notificationsEnabled = true;
  bool _expressCheckoutEnabled = false;
  bool _darkModeEnabled = false;
  int _selectedIndex = 0;
  int _cartCount = 0;
  double _monthlyBudget = 1200;
  String _username = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';

  ThemeData get _lightTheme {
    const surface = Color(0xFFF7F3EC);
    const primary = Color(0xFF1D4E5F);
    const secondary = Color(0xFFDB6C4F);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: const Color(0xFF163039),
        displayColor: const Color(0xFF163039),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }

  ThemeData get _darkTheme {
    const primary = Color(0xFF8FD6E1);
    const secondary = Color(0xFFF0A17F);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF091318),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xFFE8F4F4),
        displayColor: const Color(0xFFE8F4F4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF14232A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }

  List<DemoProduct> get _visibleProducts {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return demoProducts.where((DemoProduct product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.subtitle.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _signIn(String username, String password) {
    setState(() {
      _signedIn = true;
      _username = username.trim();
      _selectedIndex = 0;
      _searchQuery = '';
      _selectedCategory = 'All';
    });
  }

  void _toggleFavorite(String productId) {
    setState(() {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
    });
  }

  void _addToCart() {
    setState(() {
      _cartCount += 1;
    });
  }

  void _logout() {
    setState(() {
      _signedIn = false;
      _selectedIndex = 0;
      _cartCount = 0;
      _favoriteIds.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
      _notificationsEnabled = true;
      _expressCheckoutEnabled = false;
      _darkModeEnabled = false;
      _monthlyBudget = 1200;
      _username = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Client Demo',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: _signedIn
          ? _ClientShell(
              username: _username,
              selectedIndex: _selectedIndex,
              cartCount: _cartCount,
              favoriteCount: _favoriteIds.length,
              visibleProducts: _visibleProducts,
              selectedCategory: _selectedCategory,
              searchQuery: _searchQuery,
              notificationsEnabled: _notificationsEnabled,
              expressCheckoutEnabled: _expressCheckoutEnabled,
              darkModeEnabled: _darkModeEnabled,
              monthlyBudget: _monthlyBudget,
              favoriteIds: _favoriteIds,
              onIndexChanged: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              onSearchChanged: (String value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onCategoryChanged: (String value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              onToggleFavorite: _toggleFavorite,
              onAddToCart: _addToCart,
              onNotificationsChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              onExpressCheckoutChanged: (bool value) {
                setState(() {
                  _expressCheckoutEnabled = value;
                });
              },
              onDarkModeChanged: (bool value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              onBudgetChanged: (double value) {
                setState(() {
                  _monthlyBudget = value;
                });
              },
              onLogout: _logout,
            )
          : LoginScreen(onSignIn: _signIn),
    );
  }
}

class _ClientShell extends StatelessWidget {
  const _ClientShell({
    required this.username,
    required this.selectedIndex,
    required this.cartCount,
    required this.favoriteCount,
    required this.visibleProducts,
    required this.selectedCategory,
    required this.searchQuery,
    required this.notificationsEnabled,
    required this.expressCheckoutEnabled,
    required this.darkModeEnabled,
    required this.monthlyBudget,
    required this.favoriteIds,
    required this.onIndexChanged,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.onNotificationsChanged,
    required this.onExpressCheckoutChanged,
    required this.onDarkModeChanged,
    required this.onBudgetChanged,
    required this.onLogout,
  });

  final String username;
  final int selectedIndex;
  final int cartCount;
  final int favoriteCount;
  final List<DemoProduct> visibleProducts;
  final String selectedCategory;
  final String searchQuery;
  final bool notificationsEnabled;
  final bool expressCheckoutEnabled;
  final bool darkModeEnabled;
  final double monthlyBudget;
  final Set<String> favoriteIds;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onToggleFavorite;
  final VoidCallback onAddToCart;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onExpressCheckoutChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<double> onBudgetChanged;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DiscoverScreen(
        username: username,
        cartCount: cartCount,
        favoriteCount: favoriteCount,
        products: visibleProducts,
        selectedCategory: selectedCategory,
        searchQuery: searchQuery,
        favoriteIds: favoriteIds,
        onSearchChanged: onSearchChanged,
        onCategoryChanged: onCategoryChanged,
        onToggleFavorite: onToggleFavorite,
        onAddToCart: onAddToCart,
      ),
      ProfileScreen(
        username: username,
        favoriteCount: favoriteCount,
        cartCount: cartCount,
        notificationsEnabled: notificationsEnabled,
        expressCheckoutEnabled: expressCheckoutEnabled,
        darkModeEnabled: darkModeEnabled,
        monthlyBudget: monthlyBudget,
        onNotificationsChanged: onNotificationsChanged,
        onExpressCheckoutChanged: onExpressCheckoutChanged,
        onDarkModeChanged: onDarkModeChanged,
        onBudgetChanged: onBudgetChanged,
        onLogout: onLogout,
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onIndexChanged,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
