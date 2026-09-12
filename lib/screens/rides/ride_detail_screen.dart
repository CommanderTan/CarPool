import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ride_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/custom_button.dart';

class RideDetailScreen extends StatelessWidget {
  final RideModel ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isMyRide = ride.driverId == authProvider.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ride Details',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFE0E0E0),
                        backgroundImage: ride.driverPhotoUrl != null
                            ? NetworkImage(ride.driverPhotoUrl!)
                            : null,
                        child: ride.driverPhotoUrl == null
                            ? const Icon(Icons.person, color: Colors.white, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driverName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Color(0xFFFFA500)),
                                const SizedBox(width: 4),
                                const Text('4.8', style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Text(
                                  '(120 reviews)',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (ride.vehicleModel != null || ride.vehicleNumber != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Color(0xFF3C8C3C)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ride.vehicleModel != null)
                                  Text(
                                    ride.vehicleModel!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                if (ride.vehicleNumber != null)
                                  Text(
                                    ride.vehicleNumber!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RoutePoint(
                    icon: Icons.circle,
                    iconColor: const Color(0xFF3C8C3C),
                    label: 'Pickup',
                    location: ride.pickupLocation,
                    time: _formatDateTime(ride.rideDate),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    height: 30,
                    width: 2,
                    color: const Color(0xFFE5E7EB),
                  ),
                  _RoutePoint(
                    icon: Icons.location_on,
                    iconColor: const Color(0xFFE53935),
                    label: 'Drop',
                    location: ride.dropLocation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.event_seat,
                    label: 'Available Seats',
                    value: '${ride.availableSeats} / ${ride.totalSeats}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.currency_rupee,
                    label: 'Fare per Seat',
                    value: '₹${ride.farePerSeat.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Ride Time',
                    value: _formatTime(ride.rideDate),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Status',
                    value: _getStatusText(ride.status),
                    valueColor: _getStatusColor(ride.status),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMyRide
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'Request Ride',
                  onPressed: () => _requestRide(context),
                ),
              ),
            ),
    );
  }

  Future<void> _requestRide(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to request a ride')),
      );
      return;
    }

    final seats = await showDialog<int>(
      context: context,
      builder: (context) => _SeatSelectionDialog(maxSeats: ride.availableSeats),
    );

    if (seats != null && seats > 0) {
      final success = await rideProvider.requestRide(
        ride.id,
        authProvider.currentUser!.id,
        seats,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request sent successfully!'),
            backgroundColor: Color(0xFF3C8C3C),
          ),
        );
        Navigator.pop(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rideProvider.errorMessage ?? 'Failed to request ride'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${months[date.month - 1]} ${date.day}, $hour12:$minute $period';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.accepted:
        return 'Accepted';
      case RideStatus.ongoing:
        return 'Ongoing';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return const Color(0xFFFFA500);
      case RideStatus.accepted:
        return const Color(0xFF3C8C3C);
      case RideStatus.ongoing:
        return const Color(0xFF1E88E5);
      case RideStatus.completed:
        return const Color(0xFF6B7280);
      case RideStatus.cancelled:
        return const Color(0xFFE53935);
    }
  }
}

class _RoutePoint extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String location;
  final String? time;

  const _RoutePoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.location,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 2),
                Text(
                  time!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _SeatSelectionDialog extends StatefulWidget {
  final int maxSeats;

  const _SeatSelectionDialog({required this.maxSeats});

  @override
  State<_SeatSelectionDialog> createState() => _SeatSelectionDialogState();
}

class _SeatSelectionDialogState extends State<_SeatSelectionDialog> {
  int _selectedSeats = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Select Seats',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many seats do you need?'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _selectedSeats > 1
                    ? () => setState(() => _selectedSeats--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
                color: const Color(0xFF3C8C3C),
              ),
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_selectedSeats',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3C8C3C),
                  ),
                ),
              ),
              IconButton(
                onPressed: _selectedSeats < widget.maxSeats
                    ? () => setState(() => _selectedSeats++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
                color: const Color(0xFF3C8C3C),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedSeats),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3C8C3C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
