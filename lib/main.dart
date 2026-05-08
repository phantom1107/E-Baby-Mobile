import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/wishlist_service.dart';
import 'routes/app_routes.dart';

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
  @override
  void initState() {
    super.initState();
    // Check login status after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.checkLoginStatus();
        
        // Navigate to home if logged in
        if (mounted && authService.isLoggedIn) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } catch (e) {
        print('Error checking login: $e');
      }
    });
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
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
