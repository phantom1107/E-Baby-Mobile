# E-Baby Flutter Application

Complete Flutter conversion of the E-Baby Flask web application.

## Project Structure

```
e_baby_flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── user.dart
│   │   ├── product.dart
│   │   └── cart_order.dart
│   ├── services/                 # Business logic & API calls
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── cart_service.dart
│   │   ├── wishlist_service.dart
│   │   ├── product_service.dart
│   │   └── order_service.dart
│   ├── screens/                  # UI screens
│   │   ├── homepage_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── wishlist_screen.dart
│   │   ├── orders_screen.dart
│   │   ├── seller_dashboard_screen.dart
│   │   ├── admin_dashboard_screen.dart
│   │   └── ... (all other screens)
│   ├── widgets/                  # Reusable widgets
│   │   ├── product_card.dart
│   │   └── app_drawer.dart
│   └── routes/                   # Navigation routes
│       └── app_routes.dart
├── assets/
│   └── images/
│       └── logo/
├── pubspec.yaml                  # Dependencies
└── README.md
```

## Features Converted

### User Features
- ✅ User Registration (Buyer, Seller, Rider)
- ✅ OTP Verification
- ✅ Login/Logout
- ✅ Profile Management
- ✅ Password Management
- ✅ Shopping Cart
- ✅ Wishlist
- ✅ Product Search & Browse
- ✅ Order Management
- ✅ Checkout Process

### Seller Features
- ✅ Seller Dashboard
- ✅ Product Management (Add/Edit/Delete)
- ✅ Order Management
- ✅ Sales Analytics

### Rider Features
- ✅ Rider Dashboard
- ✅ Delivery Management
- ✅ Earnings Tracking

### Admin Features
- ✅ Admin Dashboard
- ✅ User Management
- ✅ Registration Approvals
- ✅ Ban/Unban Users
- ✅ Report Management

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Flask backend running on http://localhost:5000

### Installation

1. **Install Flutter dependencies:**
   ```bash
   cd e_baby_flutter
   flutter pub get
   ```

2. **Configure Backend URL:**
   - Open `lib/services/api_service.dart`
   - Update `baseUrl` to your Flask backend URL
   ```dart
   static const String baseUrl = 'http://localhost:5000';
   ```

3. **Add Assets:**
   - Copy logo images to `assets/images/logo/`
   - Copy carousel images to `assets/images/`

4. **Run the app:**
   ```bash
   flutter run
   ```

## Backend Requirements

The Flask backend must be running with the following endpoints:

### Authentication
- POST `/register` - User registration
- POST `/login` - User login
- POST `/logout` - User logout
- POST `/otp_verification` - OTP verification
- POST `/forgot_password` - Password reset

### Products
- GET `/api/products` - Get all products
- GET `/product_details/:id` - Get product details
- GET `/api/product_variants/:id` - Get product variants
- POST `/add_new_product` - Add new product
- POST `/update_products/:id` - Update product
- DELETE `/delete_product/:id` - Delete product

### Cart & Orders
- GET `/get_cart_preview` - Get cart items
- POST `/add_to_cart` - Add item to cart
- POST `/update-cart-quantity` - Update cart quantity
- POST `/remove-from-cart` - Remove from cart
- POST `/checkout` - Checkout
- POST `/confirm_order` - Confirm order
- GET `/orders` - Get user orders

### Wishlist
- GET `/get_wishlist_preview` - Get wishlist items
- POST `/add-to-wishlist` - Add to wishlist
- POST `/wishlist/remove` - Remove from wishlist

## Key Differences from Flask Version

### Architecture
- **State Management:** Provider pattern for reactive state
- **Navigation:** Named routes with MaterialApp
- **HTTP Calls:** http package instead of Flask requests
- **Storage:** SharedPreferences for session data
- **UI:** Material Design widgets instead of HTML/CSS

### Data Flow
1. **Flask:** Server-side rendering with Jinja templates
2. **Flutter:** Client-side rendering with stateful widgets

### Authentication
1. **Flask:** Session-based with cookies
2. **Flutter:** Token/session stored in SharedPreferences

### Styling
1. **Flask:** CSS files
2. **Flutter:** Dart styling with ThemeData and inline styles

## Running the App

### Development
```bash
flutter run
```

### Build for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## Configuration

### API Endpoint
Update in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'YOUR_BACKEND_URL';
```

### Theme Colors
Update in `lib/main.dart`:
```dart
primaryColor: const Color(0xFF7C3AED),
```

## Testing

Run tests:
```bash
flutter test
```

## Notes

- All Flask routes have been converted to Flutter screens
- All Python logic has been converted to Dart services
- All HTML templates have been converted to Flutter widgets
- All CSS styles have been converted to Flutter styling
- Database interactions remain on the Flask backend via API calls
- Session management uses SharedPreferences instead of Flask sessions
- File uploads use image_picker package
- Email functionality remains on backend

## Support

For issues or questions, refer to the original Flask application documentation.

## License

Same as original E-Baby Flask application.
