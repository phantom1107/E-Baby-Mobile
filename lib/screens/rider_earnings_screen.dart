import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final riderEmail = authService.currentUser?.email;

    if (riderEmail == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rider_earnings')
          .where('rider_email', isEqualTo: riderEmail)
          .where('status', isEqualTo: 'Completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final earnings = snapshot.data?.docs ?? [];

        // Sort manually by date (descending)
        earnings.sort((a, b) {
          final aDate = (a.data() as Map<String, dynamic>)['date'] as Timestamp?;
          final bDate = (b.data() as Map<String, dynamic>)['date'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        // Calculate totals
        double totalEarnings = 0;
        double todayEarnings = 0;
        double weekEarnings = 0;
        double monthEarnings = 0;

        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        // For chart - last 7 days
        Map<int, double> last7Days = {};
        for (int i = 6; i >= 0; i--) {
          final day = todayStart.subtract(Duration(days: i));
          last7Days[i] = 0;
        }

        for (var doc in earnings) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['total_earned'] ?? 0).toDouble();
          final date = (data['date'] as Timestamp?)?.toDate();

          totalEarnings += amount;

          if (date != null) {
            if (date.isAfter(todayStart)) {
              todayEarnings += amount;
            }
            if (date.isAfter(weekStart)) {
              weekEarnings += amount;
            }
            if (date.isAfter(monthStart)) {
              monthEarnings += amount;
            }

            // Chart data - last 7 days
            final daysDiff = todayStart.difference(DateTime(date.year, date.month, date.day)).inDays;
            if (daysDiff >= 0 && daysDiff < 7) {
              last7Days[6 - daysDiff] = (last7Days[6 - daysDiff] ?? 0) + amount;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              const Text(
                'Earnings Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildEarningCard(
                    'Today',
                    '₱${todayEarnings.toStringAsFixed(2)}',
                    Icons.today,
                    const Color(0xFF10B981),
                  ),
                  _buildEarningCard(
                    'This Week',
                    '₱${weekEarnings.toStringAsFixed(2)}',
                    Icons.calendar_today,
                    const Color(0xFF3B82F6),
                  ),
                  _buildEarningCard(
                    'This Month',
                    '₱${monthEarnings.toStringAsFixed(2)}',
                    Icons.calendar_month,
                    const Color(0xFFF59E0B),
                  ),
                  _buildEarningCard(
                    'Total',
                    '₱${totalEarnings.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bar Chart - Last 7 Days
              const Text(
                'Last 7 Days Earnings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (last7Days.values.isEmpty ? 100 : last7Days.values.reduce((a, b) => a > b ? a : b)) * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '₱${rod.toY.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final date = todayStart.subtract(Duration(days: 6 - value.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('E').format(date).substring(0, 1),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₱${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 50,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: last7Days.entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: const Color(0xFF7C3AED),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Earnings History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Earnings History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${earnings.length} transactions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (earnings.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: earnings.length,
                  itemBuilder: (context, index) {
                    final doc = earnings[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildEarningItem(data);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningItem(Map<String, dynamic> data) {
    final totalEarned = (data['total_earned'] ?? 0).toDouble();
    final commission = (data['commission'] ?? 0).toDouble();
    final shippingFee = (data['shipping_fee'] ?? 0).toDouble();
    final orderId = data['order_id'] ?? 'N/A';
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy hh:mm a').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 24,
          ),
        ),
        title: Text(
          '₱${totalEarned.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Completed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commission',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₱${commission.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Shipping Fee',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₱${shippingFee.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Earned',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${totalEarned.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.money_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Earnings Yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete deliveries to start earning',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
