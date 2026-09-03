import 'package:flutter/material.dart';

void main() {
  runApp(const CarPoolApp());
}

class CarPoolApp extends StatelessWidget {
  const CarPoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarPool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
      ),
      home: const CarPoolDashboard(),
    );
  }
}

/// Central color palette pulled from the design.
class AppColors {
  static const primaryGreen = Color(0xFF3C8C3C);
  static const darkGreen = Color(0xFF2E7031);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6B7280);

  static const findRideBg = Color(0xFFE3F2E3);
  static const createRideBg = Color(0xFFDCEBFB);
  static const cabSharingBg = Color(0xFFEEE3FA);

  static const findRideIcon = Color(0xFF3C8C3C);
  static const createRideIcon = Color(0xFF1E88E5);
  static const cabSharingIcon = Color(0xFF8E44AD);

  static const acceptedBg = Color(0xFFDFF3DF);
  static const acceptedText = Color(0xFF2E7031);
  static const completedBg = Color(0xFFE1EBFC);
  static const completedText = Color(0xFF1E5FBF);
}

class CarPoolDashboard extends StatefulWidget {
  const CarPoolDashboard({super.key});

  @override
  State<CarPoolDashboard> createState() => _CarPoolDashboardState();
}

class _CarPoolDashboardState extends State<CarPoolDashboard> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 24),
              _buildGreeting(),
              const SizedBox(height: 16),
              _buildIllustrationBanner(),
              const SizedBox(height: 24),
              _buildActionCardsRow(),
              const SizedBox(height: 20),
              _buildOngoingRideCard(),
              const SizedBox(height: 20),
              _buildQuickActionsCard(),
              const SizedBox(height: 20),
              _buildRecentActivityCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ---------------- Top bar (logo + notification + avatar) ----------------

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_car_filled,
                  color: AppColors.primaryGreen, size: 26),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(text: 'Car', style: TextStyle(color: AppColors.textDark)),
                  TextSpan(text: 'Pool', style: TextStyle(color: AppColors.primaryGreen)),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            _NotificationBell(count: 3),
            const SizedBox(width: 14),
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFE0E0E0),
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?img=13',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Greeting text ----------------

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good morning,',
          style: TextStyle(fontSize: 20, color: AppColors.textDark),
        ),
        Row(
          children: const [
            Text(
              'Vivek!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(width: 8),
            Text('👋', style: TextStyle(fontSize: 24)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Where are you going today?',
          style: TextStyle(fontSize: 15, color: AppColors.textGrey),
        ),
      ],
    );
  }

  // ---------------- Illustration banner ----------------
  // Placeholder for the city + carpool illustration from the design.
  // Swap `child` for an Image.asset(...) once you have the artwork exported.

  Widget _buildIllustrationBanner() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(Icons.directions_car_filled,
            size: 70, color: AppColors.primaryGreen),
        // Replace with:
        // Image.asset('assets/images/carpool_illustration.png', fit: BoxFit.cover),
      ),
    );
  }

  // ---------------- Find / Create / Cab Sharing cards ----------------

  Widget _buildActionCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.search,
            iconColor: AppColors.findRideIcon,
            iconBg: Colors.white,
            cardColor: AppColors.findRideBg,
            title: 'Find a Ride',
            subtitle: 'Search rides\nin your route',
            arrowColor: AppColors.findRideIcon,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.directions_car_outlined,
            iconColor: AppColors.createRideIcon,
            iconBg: Colors.white,
            cardColor: AppColors.createRideBg,
            title: 'Create a Ride',
            subtitle: 'Share your ride\nwith others',
            arrowColor: AppColors.createRideIcon,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.people_outline,
            iconColor: AppColors.cabSharingIcon,
            iconBg: Colors.white,
            cardColor: AppColors.cabSharingBg,
            title: 'Cab Sharing',
            subtitle: 'Book a cab\nwith others',
            arrowColor: AppColors.cabSharingIcon,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // ---------------- Ongoing ride card ----------------

  Widget _buildOngoingRideCard() {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Ongoing Ride',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.circle, size: 10, color: AppColors.primaryGreen),
                        SizedBox(width: 6),
                        Text(
                          'Pickup at 8:30 AM',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PICT → Hinjawadi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Today, 8:30 AM',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.acceptedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Driver: Rahul S.',
                      style: TextStyle(
                        color: AppColors.acceptedText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.person_outline, size: 16, color: AppColors.textGrey),
                      SizedBox(width: 4),
                      Text('2 / 4 seats', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(Icons.currency_rupee, size: 16, color: AppColors.textGrey),
                      SizedBox(width: 2),
                      Text('60 per seat', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textDark),
                  label: const Text('Chat with Driver',
                      style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on_outlined, size: 18, color: Colors.white),
                  label: const Text('Live Location',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Quick actions grid ----------------

  Widget _buildQuickActionsCard() {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(
                icon: Icons.access_time,
                bgColor: const Color(0xFFE3F2E3),
                iconColor: AppColors.primaryGreen,
                label: 'Ride Requests',
                badgeCount: 2,
              ),
              _QuickAction(
                icon: Icons.chat_bubble_outline,
                bgColor: const Color(0xFFFCEBDD),
                iconColor: const Color(0xFFE07B2A),
                label: 'Messages',
                badgeCount: 5,
              ),
              _QuickAction(
                icon: Icons.map_outlined,
                bgColor: const Color(0xFFDCEBFB),
                iconColor: const Color(0xFF1E88E5),
                label: 'Ride History',
              ),
              _QuickAction(
                icon: Icons.star_border,
                bgColor: const Color(0xFFFBE3EC),
                iconColor: const Color(0xFFD6336C),
                label: 'Reviews',
              ),
              _QuickAction(
                icon: Icons.flag_outlined,
                bgColor: const Color(0xFFEEE3FA),
                iconColor: const Color(0xFF8E44AD),
                label: 'Report',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Recent activity list ----------------

  Widget _buildRecentActivityCard() {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All',
                    style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const _ActivityItem(
            icon: Icons.directions_car_filled,
            iconBg: Color(0xFFE3F2E3),
            iconColor: AppColors.primaryGreen,
            title: 'Ride request accepted',
            route: 'PICT → Wakad',
            time: 'Today, 7:45 AM',
            statusLabel: 'Accepted',
            statusBg: AppColors.acceptedBg,
            statusColor: AppColors.acceptedText,
          ),
          const Divider(height: 28),
          const _ActivityItem(
            icon: Icons.access_time,
            iconBg: Color(0xFFDCEBFB),
            iconColor: Color(0xFF1E88E5),
            title: 'Ride created',
            route: 'PICT → Hinjawadi',
            time: 'Yesterday, 6:20 PM',
            statusLabel: 'Completed',
            statusBg: AppColors.completedBg,
            statusColor: AppColors.completedText,
          ),
        ],
      ),
    );
  }

  // ---------------- Bottom navigation ----------------

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) => setState(() => _currentNavIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.textGrey,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Find Ride'),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          label: 'Create Ride',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), label: 'Cab Sharing'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

// ============================================================
// Reusable pieces
// ============================================================

class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
          ),
          child: const Icon(Icons.notifications_none, color: AppColors.textDark),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color cardColor;
  final String title;
  final String subtitle;
  final Color arrowColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.cardColor,
    required this.title,
    required this.subtitle,
    required this.arrowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
            ),
            const SizedBox(height: 10),
            Icon(Icons.arrow_forward, size: 18, color: arrowColor),
          ],
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String label;
  final int? badgeCount;

  const _QuickAction({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.label,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (badgeCount != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String route;
  final String time;
  final String statusLabel;
  final Color statusBg;
  final Color statusColor;

  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.route,
    required this.time,
    required this.statusLabel,
    required this.statusBg,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(route, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
        ],
      ),
    );
  }
}