import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _fareController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _totalSeats = 3;
  bool _isCalculatingFare = false;
  double? _recommendedFare;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _vehicleModelController.dispose();
    _vehicleNumberController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3C8C3C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF3C8C3C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _calculateSmartFare() async {
    if (_pickupController.text.isEmpty || _dropController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup and drop locations first')),
      );
      return;
    }

    setState(() => _isCalculatingFare = true);

    try {
      final apiService = ApiService();
      final fare = await apiService.getSmartFare(
        _pickupController.text.trim(),
        _dropController.text.trim(),
      );

      setState(() {
        _recommendedFare = fare;
        _fareController.text = fare.toStringAsFixed(0);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Smart fare calculated successfully!'),
            backgroundColor: Color(0xFF3C8C3C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to calculate fare: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCalculatingFare = false);
    }
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select ride date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select ride time')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create a ride')),
      );
      return;
    }

    final rideDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final rideData = {
      'driverId': authProvider.currentUser!.id,
      'driverName': authProvider.currentUser!.name,
      'driverPhotoUrl': authProvider.currentUser!.profilePictureUrl,
      'pickupLocation': _pickupController.text.trim(),
      'dropLocation': _dropController.text.trim(),
      'pickupLat': 0.0,
      'pickupLng': 0.0,
      'dropLat': 0.0,
      'dropLng': 0.0,
      'rideDate': rideDateTime.toIso8601String(),
      'totalSeats': _totalSeats,
      'availableSeats': _totalSeats,
      'farePerSeat': double.parse(_fareController.text),
      'status': 'pending',
      'passengerIds': [],
      'vehicleModel': _vehicleModelController.text.trim(),
      'vehicleNumber': _vehicleNumberController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final success = await rideProvider.createRide(rideData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride created successfully!'),
          backgroundColor: Color(0xFF3C8C3C),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.errorMessage ?? 'Failed to create ride'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context);

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
          'Create a Ride',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2E3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF2E7031)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Share your ride and help reduce carbon footprint while saving on travel costs!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2E7031),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Route Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _pickupController,
                label: 'Pickup Location',
                hintText: 'Enter pickup location',
                prefixIcon: Icons.my_location,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _dropController,
                label: 'Drop Location',
                hintText: 'Enter drop location',
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter drop location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Date & Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: TextEditingController(
                            text: _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : '',
                          ),
                          label: 'Date',
                          hintText: 'Select date',
                          prefixIcon: Icons.calendar_today,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectTime,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: TextEditingController(
                            text: _selectedTime != null
                                ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                : '',
                          ),
                          label: 'Time',
                          hintText: 'Select time',
                          prefixIcon: Icons.access_time,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Seats & Fare',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Number of Seats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _totalSeats > 1
                          ? () => setState(() => _totalSeats--)
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
                        '$_totalSeats',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3C8C3C),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _totalSeats < 6
                          ? () => setState(() => _totalSeats++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: const Color(0xFF3C8C3C),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _fareController,
                      label: 'Fare per Seat (₹)',
                      hintText: 'Enter fare',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter fare';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton.icon(
                      onPressed: _isCalculatingFare ? null : _calculateSmartFare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isCalculatingFare
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.calculate, size: 20),
                      label: const Text('Smart Fare'),
                    ),
                  ),
                ],
              ),
              if (_recommendedFare != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Recommended: ₹${_recommendedFare!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E88E5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Vehicle Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _vehicleModelController,
                label: 'Vehicle Model',
                hintText: 'e.g., Honda City, Maruti Swift',
                prefixIcon: Icons.directions_car,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _vehicleNumberController,
                label: 'Vehicle Number',
                hintText: 'e.g., MH12AB1234',
                prefixIcon: Icons.pin,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Create Ride',
                onPressed: _createRide,
                isLoading: rideProvider.isLoading,
                height: 56,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
