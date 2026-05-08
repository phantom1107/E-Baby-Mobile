import '../models/cart_order.dart';
import 'api_service.dart';

class OrderService {
  static Future<List<Order>> getOrders() async {
    final response = await ApiService.get('/orders');
    if (response['orders'] != null) {
      return (response['orders'] as List)
          .map((item) => Order.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<Order?> getOrderDetails(int orderId) async {
    final response = await ApiService.get('/api/order/$orderId');
    if (response['success'] == true && response['data'] != null) {
      return Order.fromJson(response['data']);
    }
    return null;
  }

  static Future<Map<String, dynamic>> markAsReceived(int orderId) async {
    return await ApiService.post('/mark_as_received/$orderId', {});
  }

  static Future<Map<String, dynamic>> cancelOrder(
    int orderId,
    String reason,
  ) async {
    return await ApiService.post('/delete_order/$orderId', {'reason': reason});
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    return await ApiService.post('/update_order_status/$orderId', {
      'status': status,
    });
  }

  static Future<List<Order>> getSellerOrders() async {
    final response = await ApiService.get('/seller_order_list');
    if (response['orders'] != null) {
      return (response['orders'] as List)
          .map((item) => Order.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<List<Order>> getRiderOrders() async {
    final response = await ApiService.get('/rider_dashboard');
    if (response['orders'] != null) {
      return (response['orders'] as List)
          .map((item) => Order.fromJson(item))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> assignRider(
    int orderId,
    String riderEmail,
  ) async {
    return await ApiService.post('/assign_rider/$orderId', {
      'rider_email': riderEmail,
    });
  }
}
