# Flutter Implementation Guide - Gig Tracking System

## Overview
This guide provides complete Flutter implementation details for the delivery partner gig tracking mobile app.

---

## 📁 Project Structure

```
lib/
├── models/
│   ├── gig.dart
│   ├── gig_slot.dart
│   ├── gig_booking.dart
│   ├── session.dart
│   ├── daily_tracking.dart
│   ├── incentive_offer.dart
│   └── offer_tier.dart
├── services/
│   ├── api_service.dart
│   ├── location_service.dart
│   ├── session_service.dart
│   └── storage_service.dart
├── screens/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── dashboard_widget.dart
│   ├── gigs/
│   │   ├── available_gigs_screen.dart
│   │   ├── my_bookings_screen.dart
│   │   └── gig_details_screen.dart
│   ├── session/
│   │   ├── session_login_screen.dart
│   │   └── active_session_widget.dart
│   └── offers/
│       ├── offers_list_screen.dart
│       ├── offer_details_screen.dart
│       └── my_progress_screen.dart
├── providers/
│   ├── session_provider.dart
│   ├── gig_provider.dart
│   └── offer_provider.dart
└── widgets/
    ├── stat_card.dart
    ├── gig_card.dart
    ├── booking_card.dart
    └── tier_progress_widget.dart
```

---

## 🎨 UI/UX Screens

### 1. Home Dashboard Screen

**Features:**
- Real-time login hours (running clock)
- Today's earnings
- Distance traveled
- Gigs completed
- Online/Offline status toggle
- Quick actions (Book Gig, View Offers)

**Layout:**
```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessionProvider _sessionProvider = SessionProvider();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
    _startClockTimer();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_sessionProvider.isOnline) {
        setState(() {
          // Update running clock
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          // Online/Offline toggle
          Switch(
            value: _sessionProvider.isOnline,
            onChanged: _toggleOnlineStatus,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTodayStats,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Active Session Card (if online)
              if (_sessionProvider.isOnline)
                _buildActiveSessionCard(),

              // Stats Grid
              _buildStatsGrid(),

              // Quick Actions
              _buildQuickActions(),

              // Today's Bookings
              _buildTodayBookings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Active Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _sessionProvider.loginDisplayTime,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hours Today',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: [
        StatCard(
          icon: Icons.currency_rupee,
          title: 'Earnings',
          value: '₹${_sessionProvider.todayStats.totalEarnings.toStringAsFixed(2)}',
          color: Colors.blue,
        ),
        StatCard(
          icon: Icons.local_shipping,
          title: 'Distance',
          value: '${_sessionProvider.todayStats.totalDistanceKm.toStringAsFixed(1)} km',
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.check_circle,
          title: 'Gigs Completed',
          value: '${_sessionProvider.todayStats.gigsCompleted}',
          color: Colors.green,
        ),
        StatCard(
          icon: Icons.delivery_dining,
          title: 'Orders Delivered',
          value: '${_sessionProvider.todayStats.ordersDelivered}',
          color: Colors.purple,
        ),
      ],
    );
  }
}
```

**StatCard Widget:**
```dart
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 2. Session Login/Logout Screen

**Features:**
- Start/End session with GPS
- Show current location
- Disable if already active session
- Show session duration on logout

**Implementation:**
```dart
class SessionLoginScreen extends StatefulWidget {
  @override
  _SessionLoginScreenState createState() => _SessionLoginScreenState();
}

class _SessionLoginScreenState extends State<SessionLoginScreen> {
  final LocationService _locationService = LocationService();
  final SessionService _sessionService = SessionService();

  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      _currentPosition = await _locationService.getCurrentPosition();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _startSession() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enable location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _sessionService.startSession(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session started successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start session: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Start Session')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 100,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Current Location',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _currentPosition != null
                        ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                        : 'Fetching location...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _currentPosition != null ? _startSession : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.green,
                    ),
                    child: Text(
                      'START WORK',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

---

### 3. Available Gigs Screen

**Features:**
- Date selector (calendar)
- List of available gigs
- Show slot availability
- Mark already booked gigs
- Quick book button

**Implementation:**
```dart
class AvailableGigsScreen extends StatefulWidget {
  @override
  _AvailableGigsScreenState createState() => _AvailableGigsScreenState();
}

class _AvailableGigsScreenState extends State<AvailableGigsScreen> {
  final GigProvider _gigProvider = GigProvider();
  DateTime _selectedDate = DateTime.now();
  List<GigSlot> _gigs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGigs();
  }

  Future<void> _loadGigs() async {
    setState(() => _isLoading = true);

    try {
      _gigs = await _gigProvider.getAvailableGigs(
        date: _selectedDate,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load gigs: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadGigs();
    }
  }

  Future<void> _bookGig(GigSlot gig) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking'),
        content: Text('Book ${gig.displayName} for ${gig.slotDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('BOOK'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _gigProvider.bookGig(gig.slotId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gig booked successfully!')),
      );

      _loadGigs(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Gigs'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _selectDate,
                  child: Text('Change Date'),
                ),
              ],
            ),
          ),

          // Gigs list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _gigs.isEmpty
                    ? Center(child: Text('No gigs available for this date'))
                    : ListView.builder(
                        itemCount: _gigs.length,
                        padding: EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final gig = _gigs[index];
                          return GigCard(
                            gig: gig,
                            onBook: () => _bookGig(gig),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
```

**GigCard Widget:**
```dart
class GigCard extends StatelessWidget {
  final GigSlot gig;
  final VoidCallback onBook;

  const GigCard({
    required this.gig,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gig.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gig.isBooked)
                  Chip(
                    label: Text('BOOKED'),
                    backgroundColor: Colors.green.shade100,
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${gig.startTime} - ${gig.endTime}',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${gig.durationHours} hours',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base Earnings',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '₹${gig.baseEarnings.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Slots Available',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${gig.availableSlots}/${gig.totalSlots}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: gig.availableSlots > 0
                            ? Colors.blue
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: gig.isAvailable && !gig.isBooked ? onBook : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  gig.isBooked
                      ? 'ALREADY BOOKED'
                      : gig.availableSlots == 0
                          ? 'FULLY BOOKED'
                          : 'BOOK NOW',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 4. My Bookings Screen

**Features:**
- Tabs: Upcoming / Completed / Cancelled
- Filter by date range
- Show booking details
- Cancel option for upcoming
- Complete option for active gigs

**Implementation:**
```dart
class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GigProvider _gigProvider = GigProvider();

  List<GigBooking> _upcomingBookings = [];
  List<GigBooking> _completedBookings = [];
  List<GigBooking> _cancelledBookings = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final allBookings = await _gigProvider.getMyBookings();

      setState(() {
        _upcomingBookings = allBookings
            .where((b) => b.bookingStatus == 'booked' || b.bookingStatus == 'active')
            .toList();
        _completedBookings = allBookings
            .where((b) => b.bookingStatus == 'completed')
            .toList();
        _cancelledBookings = allBookings
            .where((b) => b.bookingStatus == 'cancelled')
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load bookings: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _cancelBooking(GigBooking booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String inputReason = '';
        return AlertDialog(
          title: Text('Cancel Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Why are you cancelling this gig?'),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => inputReason = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('BACK'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, inputReason),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('CANCEL GIG'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      await _gigProvider.cancelBooking(
        bookingId: booking.bookingId,
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking cancelled')),
      );

      _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Upcoming (${_upcomingBookings.length})'),
            Tab(text: 'Completed (${_completedBookings.length})'),
            Tab(text: 'Cancelled (${_cancelledBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(_upcomingBookings, showCancel: true),
                _buildBookingsList(_completedBookings),
                _buildBookingsList(_cancelledBookings),
              ],
            ),
    );
  }

  Widget _buildBookingsList(
    List<GigBooking> bookings, {
    bool showCancel = false,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Text('No bookings found'),
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
          onCancel: showCancel ? () => _cancelBooking(booking) : null,
        );
      },
    );
  }
}
```

---

### 5. Offers List Screen

**Features:**
- Active incentive offers
- Progress bars for each tier
- Days remaining
- Tap to view details

**Implementation:**
```dart
class OffersListScreen extends StatefulWidget {
  @override
  _OffersListScreenState createState() => _OffersListScreenState();
}

class _OffersListScreenState extends State<OffersListScreen> {
  final OfferProvider _offerProvider = OfferProvider();
  List<IncentiveOffer> _offers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);

    try {
      _offers = await _offerProvider.getActiveOffers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load offers: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Incentive Offers')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? Center(child: Text('No active offers'))
              : ListView.builder(
                  itemCount: _offers.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    return OfferCard(
                      offer: offer,
                      onTap: () => _viewOfferDetails(offer),
                    );
                  },
                ),
    );
  }

  void _viewOfferDetails(IncentiveOffer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDetailsScreen(offerId: offer.offerId),
      ),
    );
  }
}
```

**OfferCard Widget:**
```dart
class OfferCard extends StatelessWidget {
  final IncentiveOffer offer;
  final VoidCallback onTap;

  const OfferCard({
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image
            if (offer.bannerImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  offer.bannerImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    offer.description,
                    style: TextStyle(color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),

                  // Days remaining
                  Row(
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        '${offer.daysRemaining} days left',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Current progress
                  if (offer.myProgress.currentTier != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Current: ${offer.myProgress.currentTier!.tierName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '₹${offer.myProgress.currentTier!.incentiveAmount}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Next tier progress
                  if (offer.myProgress.nextTier != null) ...[
                    SizedBox(height: 12),
                    Text(
                      'Next: ${offer.myProgress.nextTier!.tierName} (₹${offer.myProgress.nextTier!.incentiveAmount})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: offer.myProgress.nextTier!.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₹${offer.myProgress.nextTier!.remainingEarnings} more to unlock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 Services Implementation

### API Service
```dart
class ApiService {
  final String baseUrl = 'https://yourapp.com/api';
  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
```

### Location Service
```dart
class LocationService {
  final Geolocator _geolocator = Geolocator();

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );
  }
}
```

---

## 📊 State Management (Provider)

### Session Provider
```dart
class SessionProvider with ChangeNotifier {
  final SessionService _sessionService = SessionService();
  final LocationService _locationService = LocationService();

  bool isOnline = false;
  DailyTracking? todayStats;
  Session? activeSession;
  Timer? _locationTimer;

  String get loginDisplayTime {
    if (todayStats == null) return '00:00';

    int totalMinutes = todayStats!.totalLoginMinutes;
    if (activeSession != null) {
      final sessionMinutes = DateTime.now()
          .difference(activeSession!.loginAt)
          .inMinutes;
      totalMinutes += sessionMinutes;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> startSession({int? gigBookingId}) async {
    final position = await _locationService.getCurrentPosition();

    await _sessionService.startSession(
      latitude: position.latitude,
      longitude: position.longitude,
      gigBookingId: gigBookingId,
    );

    isOnline = true;
    await loadTodayStats();
    _startLocationTracking();
    notifyListeners();
  }

  Future<void> endSession() async {
    final position = await _locationService.getCurrentPosition();

    await _sessionService.endSession(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    isOnline = false;
    _stopLocationTracking();
    await loadTodayStats();
    notifyListeners();
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(
      Duration(minutes: 5),
      (timer) async {
        final position = await _locationService.getCurrentPosition();
        await _sessionService.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
    );
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> loadTodayStats() async {
    todayStats = await _sessionService.getTodayStats();
    activeSession = todayStats?.activeSession;
    isOnline = todayStats?.onlineStatus == 'online';
    notifyListeners();
  }
}
```

---

## 🎯 Key Features Implementation Notes

### 1. Running Clock
- Use `Timer.periodic` with 1-minute interval
- Calculate: stored_minutes + session_minutes
- Update UI automatically

### 2. Location Tracking
- Request location permission on app start
- Update location every 5 minutes during active session
- Handle permission denied gracefully

### 3. Multi-Gig Booking
- Show all available gigs for selected date
- Allow booking multiple gigs (different slots)
- Prevent double booking same slot

### 4. Offline Support
- Cache today's stats locally
- Queue API calls when offline
- Sync when connection restored

---

## 📦 Required Packages

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.0.0

  # HTTP requests
  http: ^0.13.0

  # Location services
  geolocator: ^9.0.0
  location: ^4.4.0

  # Local storage
  shared_preferences: ^2.0.0

  # Date formatting
  intl: ^0.18.0

  # Image caching
  cached_network_image: ^3.2.0
```

---

## ✅ Testing Checklist

- [ ] Session login/logout with GPS
- [ ] Running clock updates every minute
- [ ] View available gigs for different dates
- [ ] Book multiple gigs (different slots)
- [ ] Cannot book same slot twice
- [ ] Cancel booking
- [ ] Complete gig with earnings
- [ ] View incentive offers
- [ ] Track progress towards tiers
- [ ] Location updates during session
- [ ] Handle offline mode
- [ ] Handle permission denials

---

This guide provides a complete Flutter implementation for the delivery partner app. Customize colors, fonts, and UI elements to match your brand!
