import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ReportScreen extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;
  final String rideId;

  const ReportScreen({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.rideId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'unsafe_driving',
      'label': 'Unsafe Driving',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFE53935),
    },
    {
      'value': 'harassment',
      'label': 'Harassment',
      'icon': Icons.report_problem,
      'color': Color(0xFFE53935),
    },
    {
      'value': 'inappropriate_behavior',
      'label': 'Inappropriate Behavior',
      'icon': Icons.block,
      'color': Color(0xFFFFA500),
    },
    {
      'value': 'payment_issue',
      'label': 'Payment Issue',
      'icon': Icons.payment,
      'color': Color(0xFF1E88E5),
    },
    {
      'value': 'late_arrival',
      'label': 'Late Arrival',
      'icon': Icons.access_time,
      'color': Color(0xFFFFA500),
    },
    {
      'value': 'vehicle_condition',
      'label': 'Vehicle Condition',
      'icon': Icons.directions_car,
      'color': Color(0xFF6B7280),
    },
    {
      'value': 'route_deviation',
      'label': 'Route Deviation',
      'icon': Icons.wrong_location,
      'color': Color(0xFFFFA500),
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz,
      'color': Color(0xFF6B7280),
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Submit Report?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This report will be reviewed by our team. False reports may result in account suspension.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final reportData = {
        'reporterId': currentUser.id,
        'reporterName': currentUser.name,
        'reportedUserId': widget.reportedUserId,
        'reportedUserName': widget.reportedUserName,
        'rideId': widget.rideId,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final apiService = ApiService();
      await apiService.reportUser(reportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. Our team will review it.'),
            backgroundColor: Color(0xFF3C8C3C),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Report User',
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.report_problem,
                      color: Color(0xFFE53935),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reporting ${widget.reportedUserName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Help us maintain a safe community',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'What went wrong?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category['value'];

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category['value']);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 20,
                                  color: isSelected
                                      ? const Color(0xFFE53935)
                                      : category['color'],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category['label'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF1A1A1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Describe the issue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hintText: 'Please provide details about the incident...',
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe the issue';
                        }
                        if (value.trim().length < 20) {
                          return 'Please provide at least 20 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFFF8F00),
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your report will be kept confidential. False reports may result in account action.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Submit Report',
                      onPressed: _submitReport,
                      isLoading: _isLoading,
                      backgroundColor: const Color(0xFFE53935),
                      height: 56,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
