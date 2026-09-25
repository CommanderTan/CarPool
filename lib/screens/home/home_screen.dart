import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:car_pool/providers/auth_provider.dart';
import 'package:car_pool/providers/ride_provider.dart';
import 'package:car_pool/screens/rides/find_ride_screen.dart';
import 'package:car_pool/screens/rides/create_ride_screen.dart';
import 'package:car_pool/screens/cab_sharing/cab_sharing_screen.dart';
import 'package:car_pool/screens/history/ride_history_screen.dart';
import 'package:car_pool/screens/chat/chat_screen.dart';
import 'package:car_pool/models/user_model.dart';
import 'package:car_pool/models/ride_model.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  bool _locationLoading = true;
  String? _locationError;
  LatLng? _targetLatLng;
  bool _isGettingAddress = false;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    }
    if (hour < 17) {
      return 'Good Afternoon,';
    }
    return 'Good Evening,';
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<RideProvider>().fetchMyRides(user.id);
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled';
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
            _locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission permanently denied';
          _locationLoading = false;
        });
        return;
      }

      // Try last known position first for a quick result
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && mounted) {
        setState(() {
          _currentLatLng = LatLng(
            lastPosition.latitude,
            lastPosition.longitude,
          );
          _locationLoading = false;
        });
      }

      // Now try to get the current position with a timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
          _locationLoading = false;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLatLng!));
      }
    } catch (e) {
      if (mounted) {
        // If we already have a position from lastKnown, keep it
        if (_currentLatLng != null) {
          setState(() => _locationLoading = false);
        } else {
          // Fall back to a default location so the map still loads
          setState(() {
            _currentLatLng = const LatLng(20.5937, 78.9629);
            _locationError = null;
            _locationLoading = false;
          });
        }
      }
    }
  }

  Future<void> _onSetDropLocation() async {
    if (_targetLatLng == null) return;

    setState(() {
      _isGettingAddress = true;
    });

    String address = 'Selected on Map';
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        _targetLatLng!.latitude,
        _targetLatLng!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        address = '${place.name}, ${place.subLocality}, ${place.locality}'
            .replaceAll(RegExp(r'^,\s*|,\s*,\s*|,\s*$'), '');
        if (address.isEmpty || address == ', ') {
          address = place.street ?? 'Selected on Map';
        }
      }
    } catch (e) {
      // Ignore geocoding errors, just use default
    }

    setState(() {
      _isGettingAddress = false;
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindRideScreen(initialDropLocation: address),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final rideRequests = context.watch<RideProvider>().rideRequests;
    final myRides = context.watch<RideProvider>().myRides;
    final notificationCount = rideRequests.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(user, notificationCount),
              const SizedBox(height: 24),
              _buildGreeting(user?.name ?? 'User'),
              const SizedBox(height: 16),
              _buildIllustrationBanner(),
              const SizedBox(height: 24),
              _buildActionCardsRow(context),
              const SizedBox(height: 20),
              _buildOngoingRideCard(myRides),
              const SizedBox(height: 20),
              _buildQuickActionsCard(context, notificationCount),
              const SizedBox(height: 20),
              _buildRecentActivityCard(myRides),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(UserModel? user, int notificationCount) {
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
              child: const Icon(
                Icons.directions_car_filled,
                color: AppColors.primaryGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'Car',
                    style: TextStyle(color: AppColors.textDark),
                  ),
                  TextSpan(
                    text: 'Pool',
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            _NotificationBell(count: notificationCount),
            const SizedBox(width: 14),
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFE0E0E0),
              backgroundImage: (user != null && user.profilePictureUrl != null)
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: (user == null || user.profilePictureUrl == null)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(String name) {
    final firstName = name.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: const TextStyle(fontSize: 20, color: AppColors.textDark),
        ),
        Row(
          children: [
            Text(
              '$firstName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            const Text('👋', style: TextStyle(fontSize: 24)),
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

  Widget _buildIllustrationBanner() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7EF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _locationLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Getting your location...',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            )
          : _locationError != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 40,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationError!,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _locationLoading = true;
                        _locationError = null;
                      });
                      _getCurrentLocation();
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMove: (position) {
                    _targetLatLng = position.target;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: _currentLatLng!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                      infoWindow: const InfoWindow(title: 'You are here'),
                    ),
                  },
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.location_on, color: Colors.red, size: 44),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      _getCurrentLocation();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x29000000), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 50,
                  child: ElevatedButton(
                    onPressed: _isGettingAddress ? null : _onSetDropLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isGettingAddress
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Set Drop Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionCardsRow(BuildContext context) {
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindRideScreen()),
              );
            },
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRideScreen(),
                ),
              );
            },
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CabSharingScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOngoingRideCard(List<RideModel> myRides) {
    if (myRides.isEmpty) {
      return const SizedBox.shrink();
    }
    final ride = myRides.first;
    final timeStr =
        "${ride.rideDate.hour}:${ride.rideDate.minute.toString().padLeft(2, '0')}";

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
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pickup at $timeStr',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ride.pickupLocation} → ${ride.dropLocation}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ride.rideDate.day}/${ride.rideDate.month}/${ride.rideDate.year}, $timeStr',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.acceptedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Driver: ${ride.driverName}',
                      style: const TextStyle(
                        color: AppColors.acceptedText,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.availableSeats} / ${ride.totalSeats} seats',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        size: 16,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${ride.farePerSeat} per seat',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          rideId: ride.id,
                          otherUserId: ride.driverId,
                          otherUserName: ride.driverName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: AppColors.textDark,
                  ),
                  label: const Text(
                    'Chat',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Live Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

  Widget _buildQuickActionsCard(BuildContext context, int notificationCount) {
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
                badgeCount: notificationCount > 0 ? notificationCount : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RideHistoryScreen(),
                    ),
                  );
                },
              ),
              _QuickAction(
                icon: Icons.chat_bubble_outline,
                bgColor: const Color(0xFFFCEBDD),
                iconColor: const Color(0xFFE07B2A),
                label: 'Messages',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(
                        rideId: 'general',
                        otherUserId: 'general',
                        otherUserName: 'Messages',
                      ),
                    ),
                  );
                },
              ),
              _QuickAction(
                icon: Icons.map_outlined,
                bgColor: const Color(0xFFDCEBFB),
                iconColor: const Color(0xFF1E88E5),
                label: 'Ride History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RideHistoryScreen(),
                    ),
                  );
                },
              ),
              _QuickAction(
                icon: Icons.star_border,
                bgColor: const Color(0xFFFBE3EC),
                iconColor: const Color(0xFFD6336C),
                label: 'Reviews',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RideHistoryScreen(),
                    ),
                  );
                },
              ),
              _QuickAction(
                icon: Icons.flag_outlined,
                bgColor: const Color(0xFFEEE3FA),
                iconColor: const Color(0xFF8E44AD),
                label: 'Report',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RideHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<RideModel> myRides) {
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
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (myRides.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                "No recent activities yet.",
                style: TextStyle(color: AppColors.textGrey),
              ),
            )
          else
            ...myRides.take(3).map((ride) {
              final isCompleted = ride.status.toString().contains('completed');
              final timeStr =
                  "${ride.rideDate.day}/${ride.rideDate.month} ${ride.rideDate.hour}:${ride.rideDate.minute.toString().padLeft(2, '0')}";
              return Column(
                children: [
                  _ActivityItem(
                    icon: isCompleted
                        ? Icons.check_circle_outline
                        : Icons.directions_car_filled,
                    iconBg: isCompleted
                        ? const Color(0xFFDCEBFB)
                        : const Color(0xFFE3F2E3),
                    iconColor: isCompleted
                        ? const Color(0xFF1E88E5)
                        : AppColors.primaryGreen,
                    title: 'Ride ${ride.status.toString().split('.').last}',
                    route: '${ride.pickupLocation} → ${ride.dropLocation}',
                    time: timeStr,
                    statusLabel: ride.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    statusBg: isCompleted
                        ? AppColors.completedBg
                        : AppColors.acceptedBg,
                    statusColor: isCompleted
                        ? AppColors.completedText
                        : AppColors.acceptedText,
                  ),
                  if (ride != myRides.take(3).last) const Divider(height: 28),
                ],
              );
            }),
        ],
      ),
    );
  }
}

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
          child: const Icon(
            Icons.notifications_none,
            color: AppColors.textDark,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                height: 1.3,
              ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.label,
    this.badgeCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  route,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textGrey, size: 20),
        ],
      ),
    );
  }
}
