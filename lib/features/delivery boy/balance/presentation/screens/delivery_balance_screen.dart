import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graduation_project11/core/themes/app__theme.dart';
import 'package:graduation_project11/core/widgets/custom_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:graduation_project11/core/utils/shared_keys.dart';
import 'package:graduation_project11/features/delivery%20boy/balance/data/services/delivery_balance_service.dart';
import 'package:intl/intl.dart';

class DeliveryBalanceScreen extends StatefulWidget {
  final String email;
  const DeliveryBalanceScreen({Key? key, required this.email})
      : super(key: key);

  @override
  State<DeliveryBalanceScreen> createState() => _DeliveryBalanceScreenState();
}

class _DeliveryBalanceScreenState extends State<DeliveryBalanceScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final DeliveryBalanceService _balanceService = DeliveryBalanceService();
  int points = 0;
  double rewardBalance = 0;
  double nextRewardAmount = 0; // Added for next reward amount
  List<Map<String, dynamic>> activities = [];
  String firstName = '';
  String lastName = '';
  bool isLoading = true;
  String? error;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('DeliveryBalanceScreen initialized with email: ${widget.email}');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    WidgetsBinding.instance.addObserver(this);
    loadBalanceData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload data when the app comes back to the foreground
      // and this screen is active.
      if (mounted) {
        print("DeliveryBalanceScreen resumed, reloading data.");
        loadBalanceData();
      }
    }
  }

  Future<void> loadBalanceData() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('Loading balance data for email: ${widget.email}');
      final data = await _balanceService.getBalanceData(widget.email);
      print('Received balance data: $data');

      if (!mounted) return;

      setState(() {
        points = data['points'] as int;
        rewardBalance = data['rewards'] as double;
        nextRewardAmount = data['next_reward_amount']
            as double; // Added for next reward amount
        activities = data['activities'] as List<Map<String, dynamic>>;
        firstName = data['first_name'] as String;
        lastName = data['last_name'] as String;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading balance data: $e');
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppTheme.light.colorScheme.secondary,
      appBar: CustomAppBar(title: 'Balance'),
      body: isLoading
          ? const Center(
              child: RepaintBoundary(child: CircularProgressIndicator()),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadBalanceData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadBalanceData,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    cacheExtent: 1000,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildDeliveryBoyInfo(),
                            const SizedBox(height: 16),
                            _buildBalanceCard(),
                            const SizedBox(height: 24),
                            if (activities.isNotEmpty) ...[
                              Text(
                                'Last Activity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.light.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ]),
                        ),
                      ),
                      if (activities.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No activities yet',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildActivityItem(activities[index]),
                              childCount: activities.length,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDeliveryBoyInfo() {
    String capitalize(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    final displayName = '${capitalize(firstName)} ${capitalize(lastName)}';
    print('Building delivery boy info with name: $displayName'); // Debug print

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$displayName's \nBalance",
              style: TextStyle(
                color: AppTheme.light.colorScheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final date = DateTime.parse(activity['date']);
    final formattedDate = DateFormat('MMM d, yyyy').format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getActivityIcon(activity['type']),
          color: AppTheme.light.colorScheme.primary,
        ),
        title: Text(activity['description']),
        subtitle: Text(formattedDate),
        trailing: Text(
          '${activity['points_earned']} pts',
          style: TextStyle(
            color: AppTheme.light.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return RepaintBoundary(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Points',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        points.toString() + " Points",
                        style: TextStyle(
                          color: AppTheme.light.colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Total Rewards',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${rewardBalance.toStringAsFixed(2)} EGP',
                style: TextStyle(
                  color: AppTheme.light.colorScheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  //مفروض ي

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'delivery':
        return Icons.local_shipping;
      case 'bonus':
        return Icons.star;
      case 'reward':
        return Icons.card_giftcard;
      default:
        return Icons.history;
    }
  }
}
