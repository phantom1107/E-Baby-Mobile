import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/search_results_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/seller_products_screen.dart';
import '../screens/seller_order_list_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/placeholder_screens.dart'
    hide
        CartScreen,
        ProductDetailsScreen,
        CheckoutScreen,
        ChangePasswordScreen,
        ForgotPasswordScreen,
        SearchResultsScreen,
        AddProductScreenPlaceholder,
        SellerProductsScreen,
        SellerOrderListScreen,
        OrdersScreen,
        AdminDashboardScreen,
        SellerDashboardScreen,
        RiderDashboardScreen;
import '../screens/admin_dashboard_screen.dart';
import '../screens/seller_dashboard_screen.dart';
import '../screens/rider_dashboard_screen.dart';
import '../models/product.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String auth = '/auth';
  static const String registration = '/registration';
  static const String otpVerification = '/otp_verification';
  static const String forgotPassword = '/forgot_password';
  static const String profile = '/profile';
  static const String changePassword = '/change_password';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String productDetails = '/product_details';
  static const String searchResults = '/search_results';
  static const String sellerDashboard = '/seller_dashboard';
  static const String sellerProducts = '/seller_products';
  static const String addProduct = '/add_product';
  static const String updateProduct = '/update_product';
  static const String sellerOrderList = '/seller_order_list';
  static const String adminDashboard = '/admin_dashboard';
  static const String adminUserManagement = '/admin_user_management';
  static const String registerRequest = '/register_request';
  static const String riderDashboard = '/rider_dashboard';
  static const String bannedAccount = '/banned_account';
  static const String viewSeller = '/view_seller';
  static const String viewRider = '/view_rider';

  static Map<String, WidgetBuilder> get routes => {
        welcome: (context) => const WelcomeScreen(),
        home: (context) => const MainNavigationScreen(), // Use new navigation
        auth: (context) => const AuthScreen(),
        registration: (context) => const RegistrationScreen(),
        cart: (context) => const CartScreen(),
        otpVerification: (context) => const OtpVerificationScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        profile: (context) => const ProfileScreen(),
        changePassword: (context) => const ChangePasswordScreen(),
        wishlist: (context) => const WishlistScreen(),
        checkout: (context) => const CheckoutScreen(),
        orders: (context) => const OrdersScreen(),
        searchResults: (context) => const SearchResultsScreen(),
        sellerDashboard: (context) => const SellerDashboardScreen(),
        sellerProducts: (context) => const SellerProductsScreen(),
        addProduct: (context) => const AddProductScreen(),
        updateProduct: (context) => const UpdateProductScreen(),
        sellerOrderList: (context) => const SellerOrderListScreen(),
        adminDashboard: (context) => const AdminDashboardScreen(),
        adminUserManagement: (context) => const AdminUserManagementScreen(),
        registerRequest: (context) => const RegisterRequestScreen(),
        riderDashboard: (context) => const RiderDashboardScreen(),
        bannedAccount: (context) => const BannedAccountScreen(),
        viewSeller: (context) => const ViewSellerScreen(),
        viewRider: (context) => const ViewRiderScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle product details with arguments
    if (settings.name == productDetails) {
      final product = settings.arguments as Product?;
      if (product != null) {
        return MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(productId: product.productId),
        );
      }
      // If no product provided, return to home
      return MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      );
    }

    // Handle search results with arguments
    if (settings.name == searchResults) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          initialQuery: args?['query'] as String?,
          category: args?['category'] as String?,
        ),
      );
    }

    return null;
  }
}
