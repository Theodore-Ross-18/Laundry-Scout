import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FilterModal extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterModal({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Map<String, dynamic> _filters;
  List<Map<String, dynamic>> _ratings = [];
  bool _isLoadingRatings = true;
  
  List<String> _availableServices = [];
  bool _isLoadingServices = true;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    
    // Initialize default filter values if not present
    _filters['selectedServices'] ??= <String>[];
    _filters['minimumRating'] ??= 0;
    
    // Load actual rating data
    _loadRatingData();
    _loadServicesOffered();
  }

  Future<void> _loadServicesOffered() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('services_offered')
          .not('services_offered', 'is', null);

      Set<String> uniqueServices = {};
      for (var shop in response) {
        if (shop['services_offered'] != null) {
          uniqueServices.addAll(List<String>.from(shop['services_offered']));
        }
      }

      setState(() {
        _availableServices = uniqueServices.toList();
        _isLoadingServices = false;
      });
    } catch (e) {
      print('Error loading services offered: $e');
      setState(() {
        _isLoadingServices = false;
      });
    }
  }

  Future<void> _loadRatingData() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get all feedback to calculate rating distribution
      final response = await supabase
          .from('feedback')
          .select('rating')
          .eq('feedback_type', 'user')
          .not('business_id', 'is', null);

      final feedback = List<Map<String, dynamic>>.from(response);
      
      // Calculate rating distribution
      final ratingCounts = [0, 0, 0, 0, 0]; // Index 0 = 1-star, Index 4 = 5-star
      
      for (var review in feedback) {
        final rating = (review['rating'] ?? 0).toInt();
        if (rating >= 1 && rating <= 5) {
          ratingCounts[rating - 1]++;
        }
      }

      setState(() {
        _ratings = [
          {'stars': 5, 'count': ratingCounts[4]},
          {'stars': 4, 'count': ratingCounts[3]},
          {'stars': 3, 'count': ratingCounts[2]},
          {'stars': 2, 'count': ratingCounts[1]},
          {'stars': 1, 'count': ratingCounts[0]},
        ];
        _isLoadingRatings = false;
      });
    } catch (e) {
      print('Error loading rating data: $e');
      setState(() {
        // Fallback to zeros if there's an error
        _ratings = [
          {'stars': 5, 'count': 0},
          {'stars': 4, 'count': 0},
          {'stars': 3, 'count': 0},
          {'stars': 2, 'count': 0},
          {'stars': 1, 'count': 0},
        ];
        _isLoadingRatings = false;
      });
    }
  }

  void _toggleService(String service) {
    setState(() {
      List<String> selectedServices = List<String>.from(_filters['selectedServices']);
      if (selectedServices.contains(service)) {
        selectedServices.remove(service);
      } else {
        selectedServices.add(service);
      }
      _filters['selectedServices'] = selectedServices;
    });
  }



  Widget _buildServiceChip(String service) {
    final isSelected = (_filters['selectedServices'] as List<String>).contains(service);
    
    return GestureDetector(
      onTap: () => _toggleService(service),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.remove : Icons.add,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              service,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption(Map<String, dynamic> rating) {
    final stars = rating['stars'] as int;
    final count = rating['count'] as int;
    final isSelected = _filters['minimumRating'] == stars;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _filters['minimumRating'] = isSelected ? 0 : stars;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF5A35E3) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: index < stars ? Colors.orange : Colors.grey[400],
                  size: 20,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              '($count)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF5A35E3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Services Section
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingServices
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Wrap(
                            children: _availableServices.map((service) => _buildServiceChip(service)).toList(),
                          ),
                    const SizedBox(height: 24),    
                    
                    // Minimum Rating Section
                    const Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _isLoadingRatings
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _ratings.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'No ratings available',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column(
                                children: _ratings.map((rating) => _buildRatingOption(rating)).toList(),
                              ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5A35E3), Color(0xFF7A53E3)], 
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApplyFilters(_filters);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}