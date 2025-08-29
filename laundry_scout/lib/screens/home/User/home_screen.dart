import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/login_screen.dart';
import 'profile_screen.dart'; 
import 'location_screen.dart'; 
import 'laundry_screen.dart'; 
import 'message_screen.dart'; 
import 'notification_screen.dart';
import 'viewall.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User'; 
  bool _isLoading = true;
  List<Map<String, dynamic>> _laundryShops = []; 
  List<Map<String, dynamic>> _promos = []; 
  List<Map<String, dynamic>> _filteredLaundryShops = []; 

  final TextEditingController _searchController = TextEditingController(); 
  final ScrollController _scrollController = ScrollController(); // Add this line
  bool _isSearching = false; 
  int _selectedIndex = 0; 

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
        isLoading: _isLoading,
        searchController: _searchController,
        scrollController: _scrollController, // Add this line
        filterLaundryShops: _filterLaundryShops,
        isSearching: _isSearching,
        promos: _promos,
        filteredLaundryShops: _filteredLaundryShops,
        loadUserProfile: _loadUserProfile,
        loadLaundryShops: _loadLaundryShops,
        loadPromos: _loadPromos,
      ),
      const LocationScreen(),
      const LaundryScreen(),
      const MessageScreen(),
      const NotificationScreen(),
    ];
     // Add listener to update HomeScreenBody when _userName changes, for example
    // This is a simplified way; for more complex state updates, consider a state management solution
    // or ensure data is passed reactively.
  }

  // Method to update HomeScreenBody when data changes
  void _updateHomeScreenBodyState() {
    if (!mounted) return;
    setState(() {
      _widgetOptions[0] = HomeScreenBody(
        userName: _userName,
        isLoading: _isLoading,
        searchController: _searchController,
        scrollController: _scrollController, // Add this missing line
        filterLaundryShops: _filterLaundryShops,
        isSearching: _isSearching,
        promos: _promos,
        filteredLaundryShops: _filteredLaundryShops,
        loadUserProfile: _loadUserProfile,
        loadLaundryShops: _loadLaundryShops,
        loadPromos: _loadPromos,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // Add this line
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
          .select('username')
          .eq('id', user.id)
          .single();

      if (mounted) {
        _userName = response['username'] ?? 'User';
        _isLoading = false;
        _updateHomeScreenBodyState(); // Update HomeScreenBody
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        _isLoading = false;
        _updateHomeScreenBodyState(); // Update HomeScreenBody even on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user profile: $e')),
        );
      }
    }
  }

  Future<void> _loadLaundryShops() async {
     setState(() {
      // Potentially set a loading state for shops if you have one
    });
    try {
      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('id, business_name, exact_location, cover_photo_url, does_delivery');

      if (mounted) {
        _laundryShops = List<Map<String, dynamic>>.from(response);
        _filteredLaundryShops = _laundryShops;
        _updateHomeScreenBodyState(); // Update HomeScreenBody
      }
    } catch (e) {
      print('Error loading laundry shops: $e');
      if (mounted) {
        // Potentially update loading state for shops
         _updateHomeScreenBodyState(); // Update HomeScreenBody
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
        _filteredLaundryShops = _laundryShops;
        _updateHomeScreenBodyState(); // Update HomeScreenBody
      });
    } else {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
        final lowerCaseQuery = query.toLowerCase();
        _filteredLaundryShops = _laundryShops.where((shop) {
          final businessName = shop['business_name']?.toLowerCase() ?? '';
          final location = shop['exact_location']?.toLowerCase() ?? '';
          return businessName.contains(lowerCaseQuery) || location.contains(lowerCaseQuery);
        }).toList();
        _updateHomeScreenBodyState(); // Update HomeScreenBody
      });
    }
  }

  Future<void> _loadPromos() async {
    setState(() {
      // Potentially set a loading state for promos if you have one
    });
    try {
      final response = await Supabase.instance.client
          .from('promos')
          .select('*, business_profiles(business_name)');

      if (mounted) {
        _promos = List<Map<String, dynamic>>.from(response);
        _updateHomeScreenBodyState(); // Update HomeScreenBody
      }
    } catch (e) {
      print('Error loading promos: $e');
      if (mounted) {
        // Potentially update loading state for promos
        _updateHomeScreenBodyState(); // Update HomeScreenBody
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading promos: $e')),
        );
      }
    }
  }
  

  void _onItemTapped(int index) {
    if (!mounted) return;
    
    // If Home button (index 0) is pressed and we're already on Home screen
    if (index == 0 && _selectedIndex == 0) {
      // Scroll to top
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild _widgetOptions if _isLoading has changed to pass the latest state to HomeScreenBody
    // This ensures HomeScreenBody gets the most up-to-date isLoading status.
    // Note: This is a common pattern when not using a more advanced state management solution.
    // For a more complex app, consider Riverpod, Provider, or BLoC.
    _widgetOptions[0] = HomeScreenBody(
        userName: _userName,
        isLoading: _isLoading, // Pass current loading state
        searchController: _searchController,
        scrollController: _scrollController, // Add this line
        filterLaundryShops: _filterLaundryShops,
        isSearching: _isSearching,
        promos: _promos,
        filteredLaundryShops: _filteredLaundryShops,
        loadUserProfile: _loadUserProfile,
        loadLaundryShops: _loadLaundryShops,
        loadPromos: _loadPromos,
      );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_laundry_service_outlined),
            activeIcon: Icon(Icons.local_laundry_service),
            label: 'Laundry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF6F5ADC),
        unselectedItemColor: Colors.grey[600], // Slightly darker grey for better visibility
        onTap: _onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12, // Explicitly set font size
        unselectedFontSize: 12, // Explicitly set font size
      ),
    );
  }
}

class HomeScreenBody extends StatelessWidget {
  final String userName;
  final bool isLoading;
  final TextEditingController searchController;
  final ScrollController scrollController; // Add this line
  final Function(String) filterLaundryShops;
  final bool isSearching;
  final List<Map<String, dynamic>> promos;
  final List<Map<String, dynamic>> filteredLaundryShops;
  final Future<void> Function() loadUserProfile; // Functions to allow refresh/reload from body
  final Future<void> Function() loadLaundryShops;
  final Future<void> Function() loadPromos;

  const HomeScreenBody({
    super.key,
    required this.userName,
    required this.isLoading,
    required this.searchController,
    required this.scrollController, // Add this line
    required this.filterLaundryShops,
    required this.isSearching,
    required this.promos,
    required this.filteredLaundryShops,
    required this.loadUserProfile,
    required this.loadLaundryShops,
    required this.loadPromos,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: RefreshIndicator( // Added RefreshIndicator
        onRefresh: () async {
          // Call all load methods to refresh data
          await loadUserProfile();
          await loadLaundryShops();
          await loadPromos();
        },
        child: SingleChildScrollView(
          controller: scrollController, // Add this line
          physics: const AlwaysScrollableScrollPhysics(), // Ensure scroll even when content is small
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Welcome, Name, Profile Picture, Filter Icon
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF6F5ADC), // Purple background
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
                            child: const Icon(Icons.person, color: Color(0xFF6F5ADC)),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: searchController, // Use passed controller
                              onSubmitted: filterLaundryShops, // Use passed function
                              onChanged: filterLaundryShops, // Add this line to handle real-time changes
                              style: const TextStyle(color: Colors.black), // Add this line to fix text color
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
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.filter_list, color: Color(0xFF6F5ADC)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Active Orders Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.delivery_dining, size: 40, color: Colors.grey[700]),
                        const SizedBox(height: 4),
                        Text('Pick Up', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.assignment, size: 40, color: Colors.grey[700]),
                        const SizedBox(height: 4),
                        const Text('0 Active orders', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.local_shipping, size: 40, color: Colors.grey[700]),
                        const SizedBox(height: 4),
                        Text('Delivery', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Promos Section
              if (!isSearching) // Use passed isSearching
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Promos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                ),
              if (!isSearching)
                const SizedBox(height: 10),
              if (!isSearching)
                SizedBox(
                  height: 150,
                  child: promos.isEmpty // Use passed promos
                      ? const Center(child: Text('No promos available.'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: promos.length,
                          itemBuilder: (context, index) {
                            final promo = promos[index];
                            final businessName = promo['business_profiles']?['business_name'] ?? 'Unknown Business';
                            return Container(
                              width: 250,
                              margin: EdgeInsets.only(left: index == 0 ? 16.0 : 8.0, right: index == promos.length - 1 ? 16.0 : 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: promo['image_url'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(promo['image_url']),
                                        fit: BoxFit.cover,
                                      )
                                    : const DecorationImage(
                                        image: AssetImage('lib/assets/promo_example.png'),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'By: $businessName',
                                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              const SizedBox(height: 20),
              // Nearest Laundry Shop's Section
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
                              ),
                        ),
                      ),
                      // Responsive View All button
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Check if screen width is small (mobile)
                          bool isMobile = MediaQuery.of(context).size.width < 600;
                          
                          if (isMobile) {
                            // For mobile: Use a more compact button
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6F5ADC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ViewAllScreen(),
                                    ),
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
                            // For larger screens: Use the original TextButton
                            return TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ViewAllScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(color: Color(0xFF6F5ADC)),
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
              // Horizontal list of laundry shops
              SizedBox(
                height: 200,
                child: filteredLaundryShops.isEmpty // Use passed filteredLaundryShops
                    ? Center(
                        child: Text(
                          isSearching ? 'No laundry shops found for this search.' : 'No laundry shops available.',
                          style: const TextStyle(color: Colors.black), // Add this line to make text black
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredLaundryShops.length,
                        itemBuilder: (context, index) {
                          final shop = filteredLaundryShops[index];
                          return Container(
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
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                    image: shop['cover_photo_url'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(shop['cover_photo_url']),
                                            fit: BoxFit.cover,
                                          )
                                        : const DecorationImage(
                                            image: AssetImage('lib/assets/laundry_placeholder.png'),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
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
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              shop['exact_location'] ?? 'Address Placeholder',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 14, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          const Text('4.5', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(shop['does_delivery'] == true ? 'Delivery' : 'No Delivery', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20), // Add some padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}