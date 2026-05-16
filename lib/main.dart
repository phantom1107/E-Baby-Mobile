import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';
import 'routes/app_routes.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/seller_dashboard_screen.dart';
import 'screens/rider_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EBabyApp());
}

class EBabyApp extends StatelessWidget {
  const EBabyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => WishlistService()),
      ],
      child: const _AppInitializer(),
    );
  }
}

/// Restores Firestore-only login from SharedPreferences on startup.
class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkLoginStatus();
      
      if (mounted) {
        setState(() => _isChecking = false);
      }
    } catch (e) {
      print('Error checking login: $e');
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Baby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF7C3AED),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFF8B5CF6),
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: _isChecking
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7C3AED),
                ),
              ),
            )
          : Consumer<AuthService>(
              builder: (context, authService, child) {
                // If logged in, route based on user type
                if (authService.isLoggedIn) {
                  final userType = authService.currentUser?.userType ?? 'Buyer';
                  
                  switch (userType) {
                    case 'Admin':
                      return const AdminDashboardScreen();
                    case 'Seller':
                      return const SellerDashboardScreen();
                    case 'Rider':
                      return const RiderDashboardScreen();
                    default: // Buyer
                      return const MainNavigationScreen();
                  }
                }
                // Otherwise show welcome screen
                return const WelcomeScreen();
              },
            ),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
