import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/login_screen.dart';
import '../../../widgets/optimized_image.dart';
import '../../../widgets/message_badge.dart';
import '../../../widgets/filter_modal.dart';
import 'profile_screen.dart'; 
import 'location_screen.dart'; 
import 'laundry_screen.dart'; 
import 'message_screen.dart'; 
import 'notification_screen.dart';
import 'business_detail_screen.dart';
import 'promo_preview.dart';
import 'all_promos_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User'; 
  String? _profileImageUrl;
  bool _isLoading = true;
  List<Map<String, dynamic>> _laundryShops = []; 
  List<Map<String, dynamic>> _promos = []; 
  List<Map<String, dynamic>> _filteredLaundryShops = []; 
  Map<String, dynamic> _currentFilters = {};
  int _activeOrdersCount = 0; 

  final TextEditingController _searchController = TextEditingController(); 
  final ScrollController _scrollController = ScrollController(); 
  bool _isSearching = false; 
  int _selectedIndex = 0; 

  final GlobalKey<NotificationScreenState> _notificationScreenKey = GlobalKey<NotificationScreenState>();

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadLaundryShops(); 
    _loadPromos(); 

    _widgetOptions = <Widget>[
      HomeScreenBody(
        userName: _userName,
        profileImageUrl: _profileImageUrl, 
        isLoading: _isLoading,
        searchController: _searchController,
        scrollController: _scrollController,
        filterLaundryShops: _filterLaundryShops,
        showFilterModal: _showFilterModal,
        isSearching: _isSearching,
        promos: _promos,
        filteredLaundryShops: _filteredLaundryShops,
        loadUserProfile: _loadUserProfile,
        loadLaundryShops: _loadLaundryShops,
        loadPromos: _loadPromos,
        activeOrdersCount: _activeOrdersCount,
        onNavigateToNotifications: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const LocationScreen(),
      const LaundryScreen(),
      const MessageScreen(),
      NotificationScreen(key: _notificationScreenKey),
    ];
    
    _loadActiveOrdersCount(); 
  }


  void _updateHomeScreenBodyState() {
    if (!mounted) return;
    setState(() {
      _widgetOptions[0] = HomeScreenBody(
        userName: _userName,
        profileImageUrl: _profileImageUrl,
        isLoading: _isLoading,
        searchController: _searchController,
        scrollController: _scrollController,
        filterLaundryShops: _filterLaundryShops,
        showFilterModal: _showFilterModal,
        isSearching: _isSearching,
        promos: _promos,
        filteredLaundryShops: _filteredLaundryShops,
        loadUserProfile: _loadUserProfile,
        loadLaundryShops: _loadLaundryShops,
        loadPromos: _loadPromos,
        activeOrdersCount: _activeOrdersCount,
        onNavigateToNotifications: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); 
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('username, profile_image_url') 
          .eq('id', user.id)
          .single();

      if (mounted) {
        _userName = response['username'] ?? 'User';
        _profileImageUrl = response['profile_image_url']; 
        _isLoading = false;
        _updateHomeScreenBodyState(); 
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        _isLoading = false;
        _updateHomeScreenBodyState(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: $e')),
        );
      }
    }
  }

  Future<void> _loadLaundryShops() async {
     setState(() {
      
    });
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('''
            id, 
            business_name, 
            business_address, 
            cover_photo_url, 
            does_delivery, 
            availability_status,
            feedback(rating)
          ''')
          .eq('status', 'approved')
          .eq('feedback.feedback_type', 'user'); 

      if (mounted) {
       
        final processedShops = response.map((shop) {
          final feedbackList = shop['feedback'] as List<dynamic>? ?? [];
          double averageRating = 0.0;
          int totalReviews = 0;
          
          if (feedbackList.isNotEmpty) {
            double totalRating = 0.0;
            for (var feedback in feedbackList) {
              if (feedback['rating'] != null) {
                totalRating += (feedback['rating'] as num).toDouble();
                totalReviews++;
              }
            }
            if (totalReviews > 0) {
              averageRating = totalRating / totalReviews;
            }
          }
          
          return {
            ...shop,
            'average_rating': averageRating,
            'total_reviews': totalReviews,
            'feedback': null, 
          };
        }).toList();

        _laundryShops = List<Map<String, dynamic>>.from(processedShops);
        _filteredLaundryShops = _laundryShops;
        
        _updateHomeScreenBodyState(); 
      }
    } catch (e) {
      print('Error loading laundry shops: $e');
      if (mounted) {
       
         _updateHomeScreenBodyState(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading laundry shops: $e')),
        );
      }
    }
  }

  void _filterLaundryShops(String query) {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _applyFilters();
        _updateHomeScreenBodyState(); 
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
        _applyFilters(searchQuery: query);
        _updateHomeScreenBodyState(); 
      });
    }
  }

  void _applyFilters({String? searchQuery}) {
    List<Map<String, dynamic>> filtered = List.from(_laundryShops);
    
   
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowerCaseQuery = searchQuery.toLowerCase();
      filtered = filtered.where((shop) {
        final businessName = shop['business_name']?.toLowerCase() ?? '';
        final location = shop['exact_location']?.toLowerCase() ?? '';
        return businessName.contains(lowerCaseQuery) || location.contains(lowerCaseQuery);
      }).toList();
    }
    
    
    if (_currentFilters['selectedServices'] != null && 
        (_currentFilters['selectedServices'] as List).isNotEmpty) {
      filtered = filtered.where((shop) {
        List<String> selectedServices = List<String>.from(_currentFilters['selectedServices']);
        
        
        List<String> shopServices = [];
        if (shop['services_offered'] != null) {
          shopServices = List<String>.from(shop['services_offered']);
        }
        
       
        bool hasService = false;
        
        for (String service in selectedServices) {
          switch (service) {
            case 'Delivery':
              if (shop['does_delivery'] == true) hasService = true;
              break;
            case 'Drop Off':
            case 'Pick Up':
            case 'Wash & Fold':
            case 'Self Service':
            case 'Dry Clean':
            case 'Ironing':
              if (shopServices.contains(service)) hasService = true;
              break;
          }
          if (hasService) break;
        }
        
        return hasService;
      }).toList();
    }
    
   
    if (_currentFilters['minimumRating'] != null && 
        _currentFilters['minimumRating'] > 0) {
      filtered = filtered.where((shop) {
        double shopRating = (shop['average_rating'] as num?)?.toDouble() ?? 0.0;
        return shopRating >= _currentFilters['minimumRating'];
      }).toList();
    }
    
    _filteredLaundryShops = filtered;
  }

  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FilterModal(
          currentFilters: _currentFilters,
          onApplyFilters: (Map<String, dynamic> filters) {
            setState(() {
              _currentFilters = filters;
              _applyFilters(searchQuery: _searchController.text);
              _updateHomeScreenBodyState();
            });
          },
        );
      },
    );
  }

  Future<void> _loadPromos() async {
    setState(() {
      
    });
    try {
      final response = await Supabase.instance.client
          .from('promos')
          .select('*, business_profiles(business_name)');

      if (mounted) {
        final now = DateTime.now();
        _promos = List<Map<String, dynamic>>.from(response).where((promo) {
          final expirationDateString = promo['expiration_date'] as String?;
          if (expirationDateString == null) {
            return true; // Promo without expiration date is always valid
          }
          final expirationDate = DateTime.parse(expirationDateString);
          return expirationDate.isAfter(now);
        }).toList();
        _updateHomeScreenBodyState(); 
      }
    } catch (e) {
      print('Error loading promos: $e');
      if (mounted) {
       
        _updateHomeScreenBodyState(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading promos: $e')),
        );
      }
    }
  }
  
  Future<void> _loadActiveOrdersCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _activeOrdersCount = 0;
        });
        return;
      }

      final countResponse = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('user_id', user.id)
          .inFilter('status', ['pending', 'confirmed', 'in_progress', 'ready'])
          .count();

      if (mounted) {
        setState(() {
          _activeOrdersCount = countResponse.count;
          _updateHomeScreenBodyState();
        });
      }
    } catch (e) {
      print('Error loading active orders count: $e');
      if (mounted) {
        setState(() {
          _activeOrdersCount = 0;
          _updateHomeScreenBodyState();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading active orders count: $e')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;

    if (index == 0 && _selectedIndex == 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      _refreshDataInBackground();
      return;
    } else if (index == 4 && _selectedIndex != 4) { // Notification tab tapped
      _notificationScreenKey.currentState?.refreshData();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshDataInBackground() async {
    try {
      await Future.wait([
        _loadUserProfileBackground(),
        _loadLaundryShopsBackground(),
        _loadPromosBackground(),
        _loadActiveOrdersCountBackground(),
      ]);
      _notificationScreenKey.currentState?.refreshData();
    } catch (e) {
      print('Background refresh error: $e');
    }
  }

  Future<void> _loadUserProfileBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('username, profile_image_url')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userName = response['username'] ?? 'User';
          _profileImageUrl = response['profile_image_url'];
        });
      }
    } catch (e) {
      print('Background user profile load error: $e');
    }
  }

  Future<void> _loadLaundryShopsBackground() async {
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('''
            id, 
            business_name, 
            exact_location, 
            cover_photo_url, 
            does_delivery, 
            availability_status,
            feedback(rating)
          ''')
          .eq('status', 'approved')
          .eq('feedback.feedback_type', 'user');

      if (mounted) {
       
        final processedShops = response.map((shop) {
          final feedbackList = shop['feedback'] as List<dynamic>? ?? [];
          double averageRating = 0.0;
          int totalReviews = 0;
          
          if (feedbackList.isNotEmpty) {
            double totalRating = 0.0;
            for (var feedback in feedbackList) {
              if (feedback['rating'] != null) {
                totalRating += (feedback['rating'] as num).toDouble();
                totalReviews++;
              }
            }
            if (totalReviews > 0) {
              averageRating = totalRating / totalReviews;
            }
          }
          
          return {
            ...shop,
            'average_rating': averageRating,
            'total_reviews': totalReviews,
            'feedback': null,
          };
        }).toList();

        setState(() {
          _laundryShops = List<Map<String, dynamic>>.from(processedShops);
          _applyFilters(searchQuery: _searchController.text);
        });
      }
    } catch (e) {
      print('Background laundry shops load error: $e');
    }
  }

  Future<void> _loadPromosBackground() async {
    try {
      final response = await Supabase.instance.client
          .from('promos')
          .select('*, business_profiles(business_name)');

      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _promos = List<Map<String, dynamic>>.from(response).where((promo) {
            final expirationDateString = promo['expiration_date'] as String?;
            if (expirationDateString == null) {
              return true; // Promo without expiration date is always valid
            }
            final expirationDate = DateTime.parse(expirationDateString);
            return expirationDate.isAfter(now);
          }).toList();
          _updateHomeScreenBodyState();
        });
      }
    } catch (e) {
      print('Background promos load error: $e');
    }
  }

  Future<void> _loadActiveOrdersCountBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _activeOrdersCount = 0;
        });
        return;
      }

      final countResponse = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('user_id', user.id)
          .inFilter('status', ['pending', 'confirmed', 'in_progress', 'ready'])
          .count();

      if (mounted) {
        setState(() {
          _activeOrdersCount = countResponse.count;
        });
      }
    } catch (e) {
      print('Background active orders count load error: $e');
      if (mounted) {
        setState(() {
          _activeOrdersCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    _widgetOptions[0] = HomeScreenBody(
        userName: _userName,
        profileImageUrl: _profileImageUrl,
        isLoading: _isLoading,
        searchController: _searchController,
        scrollController: _scrollController,
        filterLaundryShops: _filterLaundryShops,
        showFilterModal: _showFilterModal,
        isSearching: _isSearching,
        promos: _promos,
        filteredLaundryShops: _filteredLaundryShops,
        loadUserProfile: _loadUserProfile,
        loadLaundryShops: _loadLaundryShops,
        loadPromos: _loadPromos,
        activeOrdersCount: _activeOrdersCount,
        onNavigateToNotifications: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      );

    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('lib/assets/navbars/home.png', width: 24, height: 24, color: Colors.black),
            activeIcon: Image.asset('lib/assets/navbars/home.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('lib/assets/navbars/location.png', width: 24, height: 24, color: Colors.black),
            activeIcon: Image.asset('lib/assets/navbars/location.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('lib/assets/navbars/laundry.png', width: 24, height: 24, color: Colors.black),
            activeIcon: Image.asset('lib/assets/navbars/laundry.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Laundry',
          ),
          BottomNavigationBarItem(
            icon: user != null 
                ? MessageBadge(
                    userId: user.id,
                    child: Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Colors.black),
                  )
                : Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Colors.black),
            activeIcon: user != null 
                ? MessageBadge(
                    userId: user.id,
                    child: Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
                  )
                : Image.asset('lib/assets/navbars/message.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('lib/assets/navbars/notification.png', width: 24, height: 24, color: Colors.black),
            activeIcon: Image.asset('lib/assets/navbars/notification.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
            label: 'Notification',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5A35E3),
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
      ),
    );
  }
}

class _AnimatedServiceIcon extends StatefulWidget {
  final Widget icon;
  final String label;
  final String animationType;
  final Color color;
  final int? count;
  final VoidCallback? onTap;

  const _AnimatedServiceIcon({
    required this.icon,
    required this.label,
    required this.animationType,
    required this.color,
    this.count,
    this.onTap,
  });

  @override
  State<_AnimatedServiceIcon> createState() => _AnimatedServiceIconState();
}

class _AnimatedServiceIconState extends State<_AnimatedServiceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    if (widget.animationType.isNotEmpty) {
      switch (widget.animationType) {
        case 'bounce':
          _animation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 25),
            TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 25),
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 50),
          ]).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          );
          break;
        case 'pulse':
          _animation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 25),
            TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 25),
            TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
          ]).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          );
          break;
        case 'slide':
          _animation = TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 25),
            TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 50),
            TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 25),
          ]).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          );
          break;
      }
      
      if ((widget.count ?? 0) > 0) {
        _controller.repeat();
      }
    } else {
      _animation = AlwaysStoppedAnimation(0.0);
    }
  }

  @override
  void didUpdateWidget(_AnimatedServiceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.animationType.isNotEmpty) {
      if ((widget.count ?? 0) > 0 && (oldWidget.count ?? 0) == 0) {
        _controller.repeat();
      } else if ((widget.count ?? 0) == 0 && (oldWidget.count ?? 0) > 0) {
        _controller.stop();
        _controller.reset();
      }
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              if (widget.animationType == 'bounce') {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        child: widget.icon,
                      ),
                      if (widget.count != null && widget.count! > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else if (widget.animationType == 'pulse') {
                return Transform.scale(
                  scale: _animation.value,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        child: widget.icon,
                      ),
                      if (widget.count != null && widget.count! > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              } else if (widget.animationType == 'slide') {
                return Transform.translate(
                  offset: Offset(_animation.value, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        child: widget.icon,
                      ),
                      if (widget.count != null && widget.count! > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    child: widget.icon,
                  ),
                  if (widget.count != null && widget.count! > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          widget.count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreenBody extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final bool isLoading;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final Function(String) filterLaundryShops;
  final VoidCallback showFilterModal;
  final bool isSearching;
  final List<Map<String, dynamic>> promos;
  final List<Map<String, dynamic>> filteredLaundryShops;
  final Future<void> Function() loadUserProfile;
  final Future<void> Function() loadLaundryShops;
  final Future<void> Function() loadPromos;
  final int activeOrdersCount;
  final Function(int) onNavigateToNotifications; 

  const HomeScreenBody({
    super.key,
    required this.userName,
    this.profileImageUrl,
    required this.isLoading,
    required this.searchController,
    required this.scrollController,
    required this.filterLaundryShops,
    required this.showFilterModal,
    required this.isSearching,
    required this.promos,
    required this.filteredLaundryShops,
    required this.loadUserProfile,
    required this.loadLaundryShops,
    required this.loadPromos,
    required this.activeOrdersCount,
    required this.onNavigateToNotifications, 
  });

  Widget _buildAvailabilityStatus(String? availabilityStatus) {
    String status = availabilityStatus ?? 'Unavailable';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Open Slots':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Filling Up':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'Full':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Unavailable':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        status = 'Unavailable';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 8,
            color: statusColor,
          ),
          const SizedBox(width: 1),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: RefreshIndicator( 
        onRefresh: () async {
      
          await loadUserProfile();
          await loadLaundryShops();
          await loadPromos();
        },
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF5A35E3), 
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20.0), // Add space above Welcome
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              userName, // Use passed userName
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            child: profileImageUrl != null 
                                ? ClipOval(
                                    child: OptimizedImage(
                                      imageUrl: profileImageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorWidget: const Icon(Icons.person, color: Color(0xFF5A35E3)),
                                    ),
                                  )
                                : const Icon(Icons.person, color: Color(0xFF5A35E3)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: searchController, 
                              onSubmitted: filterLaundryShops, 
                              onChanged: filterLaundryShops, 
                              style: const TextStyle(color: Colors.black), 
                              decoration: const InputDecoration(
                                hintText: 'Search Here',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: showFilterModal,
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Image.asset('lib/assets/icons/filter.png', width: 24, height: 24, color: Color(0xFF5A35E3)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Pick Up Animation
                    _AnimatedServiceIcon(
                      icon: Image.asset('lib/assets/orders/pickup.png', width: 50, height: 50),
                      label: '',
                      animationType: 'bounce',
                      color: const Color(0xFF5A35E3),
                      onTap: () {
                        // Handle tap
                      },
                    ),
                    // Active Orders Animation
                    _AnimatedServiceIcon(
                      icon: Image.asset('lib/assets/orders/orders.png', width: 44, height: 44),
                      label: '$activeOrdersCount Active Orders',
                      animationType: '',
                      color: Colors.black,
                      count: activeOrdersCount,
                      onTap: () {
                        onNavigateToNotifications(4);
                      },
                    ),
                    
                    _AnimatedServiceIcon(
                      icon: Image.asset('lib/assets/orders/delivery.png', width: 60, height: 60),
                      label: '',
                      animationType: 'slide',
                      color: Colors.black,
                      onTap: () {
                        // Handle tap
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Promos Section
              if (!isSearching) // Use passed isSearching
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Promos',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = MediaQuery.of(context).size.width < 600;
                          if (isMobile) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5A35E3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AllPromosScreen()),
                                  );
                                },
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AllPromosScreen()),
                                );
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(color: Color(0xFF5A35E3)),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              if (!isSearching)
                const SizedBox(height: 10),
              if (!isSearching)
                SizedBox(
                  height: 150,
                  child: promos.isEmpty // Use passed promos
                      ? const Center(child: Text('No promos available.', style: TextStyle(color: Colors.black)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: promos.length,
                          itemBuilder: (context, index) {
                            final promo = promos[index];
                            return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PromoPreviewScreen(promoData: promo),
                                ),
                              );
                            },
                            child: Container(
                              width: 300,
                              margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == promos.length - 1 ? 16.0 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(promo['image_url'] ?? 'https://via.placeholder.com/150'), // Provide a fallback image URL
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 0.0, bottom: 3.0, left: 150.0),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (promo['expiration_date'] != null)
                                            Text(
                                              'Expires: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(promo['expiration_date']))}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          },
                        ),
                      ),
              const SizedBox(height: 20),
              
              if (!isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Nearest Laundry Shop's",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 11,
                              ),
                        ),
                      ),
                      
                      LayoutBuilder(
                        builder: (context, constraints) {
                          
                          bool isMobile = MediaQuery.of(context).size.width < 600;
                          
                          if (isMobile) {
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5A35E3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () {
                                
                                final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                                if (homeScreenState != null && homeScreenState.mounted) {
                                  homeScreenState._onItemTapped(2);
                                }
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              ),
                            );
                          } else {
                           
                            return TextButton(
                              onPressed: () {
                               
                                final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                                if (homeScreenState != null && homeScreenState.mounted) {
                                  homeScreenState._onItemTapped(2);
                                }
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(color: Color(0xFF5A35E3)),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              if (!isSearching)
                const SizedBox(height: 10),
              
              SizedBox(
                height: 200,
                child: filteredLaundryShops.isEmpty 
                    ? Center(
                        child: Text(
                          isSearching ? 'No laundry shops found for this search.' : 'No laundry shops available.',
                          style: const TextStyle(color: Colors.black), 
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredLaundryShops.length,
                        itemBuilder: (context, index) {
                          final shop = filteredLaundryShops[index];
                          return GestureDetector( 
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessDetailScreen(businessData: shop),
                                ),
                              );
                            },
                            child: Container(
                              width: 180,
                              margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == filteredLaundryShops.length - 1 ? 16.0 : 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LaundryShopImageCard(
                                    imageUrl: shop['cover_photo_url'],
                                    height: 90,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop['business_name'] ?? 'Laundry Shop',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                shop['business_address'] ?? 'Location not available',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 12, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              shop['average_rating']?.toStringAsFixed(1) ?? '0.0', 
                                              style: const TextStyle(fontSize: 11, color: Colors.grey)
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.delivery_dining, size: 12, color: Colors.grey),
                                            const SizedBox(width: 2),
                                            Text(shop['does_delivery'] == true ? 'Delivery' : 'No', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        _buildAvailabilityStatus(shop['availability_status']),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20), 
            ],
          ),
        ),
      ),
    );
  }
}