import 'dart:async';
import 'package:flutter/material.dart';

class WorldCity {
  final String name;
  final String country;
  final String flag;
  final String timezone;
  final double utcOffset;
  final String continent;

  const WorldCity({
    required this.name,
    required this.country,
    required this.flag,
    required this.timezone,
    required this.utcOffset,
    required this.continent,
  });

  DateTime get currentTime {
    final utcNow = DateTime.now().toUtc();
    final offset = Duration(minutes: (utcOffset * 60).round());
    return utcNow.add(offset);
  }

  String get timeString {
    final t = currentTime;
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String get dateString {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final t = currentTime;
    return days[t.weekday - 1];
  }

  bool get isDay {
    final h = currentTime.hour;
    return h >= 6 && h < 20;
  }

  String get offsetString {
    final h = utcOffset.abs().truncate();
    final m = ((utcOffset.abs() - h) * 60).round();
    final sign = utcOffset >= 0 ? '+' : '-';
    if (m == 0) return 'UTC$sign${h.toString().padLeft(2, '0')}:00';
    return 'UTC$sign${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

const List<WorldCity> _allCities = [
  // Americas
  WorldCity(name: 'New York', country: 'USA', flag: '🇺🇸', timezone: 'EST', utcOffset: -5, continent: 'Americas'),
  WorldCity(name: 'Los Angeles', country: 'USA', flag: '🇺🇸', timezone: 'PST', utcOffset: -8, continent: 'Americas'),
  WorldCity(name: 'Chicago', country: 'USA', flag: '🇺🇸', timezone: 'CST', utcOffset: -6, continent: 'Americas'),
  WorldCity(name: 'Houston', country: 'USA', flag: '🇺🇸', timezone: 'CST', utcOffset: -6, continent: 'Americas'),
  WorldCity(name: 'Toronto', country: 'Canada', flag: '🇨🇦', timezone: 'EST', utcOffset: -5, continent: 'Americas'),
  WorldCity(name: 'Vancouver', country: 'Canada', flag: '🇨🇦', timezone: 'PST', utcOffset: -8, continent: 'Americas'),
  WorldCity(name: 'Mexico City', country: 'Mexico', flag: '🇲🇽', timezone: 'CST', utcOffset: -6, continent: 'Americas'),
  WorldCity(name: 'São Paulo', country: 'Brazil', flag: '🇧🇷', timezone: 'BRT', utcOffset: -3, continent: 'Americas'),
  WorldCity(name: 'Buenos Aires', country: 'Argentina', flag: '🇦🇷', timezone: 'ART', utcOffset: -3, continent: 'Americas'),
  WorldCity(name: 'Bogotá', country: 'Colombia', flag: '🇨🇴', timezone: 'COT', utcOffset: -5, continent: 'Americas'),
  WorldCity(name: 'Lima', country: 'Peru', flag: '🇵🇪', timezone: 'PET', utcOffset: -5, continent: 'Americas'),
  WorldCity(name: 'Santiago', country: 'Chile', flag: '🇨🇱', timezone: 'CLT', utcOffset: -4, continent: 'Americas'),
  // Europe
  WorldCity(name: 'London', country: 'UK', flag: '🇬🇧', timezone: 'GMT', utcOffset: 0, continent: 'Europe'),
  WorldCity(name: 'Paris', country: 'France', flag: '🇫🇷', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Berlin', country: 'Germany', flag: '🇩🇪', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Madrid', country: 'Spain', flag: '🇪🇸', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Rome', country: 'Italy', flag: '🇮🇹', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Amsterdam', country: 'Netherlands', flag: '🇳🇱', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Moscow', country: 'Russia', flag: '🇷🇺', timezone: 'MSK', utcOffset: 3, continent: 'Europe'),
  WorldCity(name: 'Istanbul', country: 'Turkey', flag: '🇹🇷', timezone: 'TRT', utcOffset: 3, continent: 'Europe'),
  WorldCity(name: 'Stockholm', country: 'Sweden', flag: '🇸🇪', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Zurich', country: 'Switzerland', flag: '🇨🇭', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  WorldCity(name: 'Warsaw', country: 'Poland', flag: '🇵🇱', timezone: 'CET', utcOffset: 1, continent: 'Europe'),
  // Middle East & Africa
  WorldCity(name: 'Dubai', country: 'UAE', flag: '🇦🇪', timezone: 'GST', utcOffset: 4, continent: 'Middle East'),
  WorldCity(name: 'Riyadh', country: 'Saudi Arabia', flag: '🇸🇦', timezone: 'AST', utcOffset: 3, continent: 'Middle East'),
  WorldCity(name: 'Tel Aviv', country: 'Israel', flag: '🇮🇱', timezone: 'IST', utcOffset: 2, continent: 'Middle East'),
  WorldCity(name: 'Tehran', country: 'Iran', flag: '🇮🇷', timezone: 'IRST', utcOffset: 3.5, continent: 'Middle East'),
  WorldCity(name: 'Cairo', country: 'Egypt', flag: '🇪🇬', timezone: 'EET', utcOffset: 2, continent: 'Africa'),
  WorldCity(name: 'Nairobi', country: 'Kenya', flag: '🇰🇪', timezone: 'EAT', utcOffset: 3, continent: 'Africa'),
  WorldCity(name: 'Lagos', country: 'Nigeria', flag: '🇳🇬', timezone: 'WAT', utcOffset: 1, continent: 'Africa'),
  WorldCity(name: 'Johannesburg', country: 'South Africa', flag: '🇿🇦', timezone: 'SAST', utcOffset: 2, continent: 'Africa'),
  WorldCity(name: 'Casablanca', country: 'Morocco', flag: '🇲🇦', timezone: 'WET', utcOffset: 0, continent: 'Africa'),
  WorldCity(name: 'Accra', country: 'Ghana', flag: '🇬🇭', timezone: 'GMT', utcOffset: 0, continent: 'Africa'),
  // Asia
  WorldCity(name: 'Mumbai', country: 'India', flag: '🇮🇳', timezone: 'IST', utcOffset: 5.5, continent: 'Asia'),
  WorldCity(name: 'Delhi', country: 'India', flag: '🇮🇳', timezone: 'IST', utcOffset: 5.5, continent: 'Asia'),
  WorldCity(name: 'Hyderabad', country: 'India', flag: '🇮🇳', timezone: 'IST', utcOffset: 5.5, continent: 'Asia'),
  WorldCity(name: 'Kolkata', country: 'India', flag: '🇮🇳', timezone: 'IST', utcOffset: 5.5, continent: 'Asia'),
  WorldCity(name: 'Bangalore', country: 'India', flag: '🇮🇳', timezone: 'IST', utcOffset: 5.5, continent: 'Asia'),
  WorldCity(name: 'Karachi', country: 'Pakistan', flag: '🇵🇰', timezone: 'PKT', utcOffset: 5, continent: 'Asia'),
  WorldCity(name: 'Dhaka', country: 'Bangladesh', flag: '🇧🇩', timezone: 'BST', utcOffset: 6, continent: 'Asia'),
  WorldCity(name: 'Colombo', country: 'Sri Lanka', flag: '🇱🇰', timezone: 'SLST', utcOffset: 5.5, continent: 'Asia'),
  WorldCity(name: 'Singapore', country: 'Singapore', flag: '🇸🇬', timezone: 'SGT', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Kuala Lumpur', country: 'Malaysia', flag: '🇲🇾', timezone: 'MYT', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Bangkok', country: 'Thailand', flag: '🇹🇭', timezone: 'ICT', utcOffset: 7, continent: 'Asia'),
  WorldCity(name: 'Jakarta', country: 'Indonesia', flag: '🇮🇩', timezone: 'WIB', utcOffset: 7, continent: 'Asia'),
  WorldCity(name: 'Ho Chi Minh', country: 'Vietnam', flag: '🇻🇳', timezone: 'ICT', utcOffset: 7, continent: 'Asia'),
  WorldCity(name: 'Manila', country: 'Philippines', flag: '🇵🇭', timezone: 'PHT', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Beijing', country: 'China', flag: '🇨🇳', timezone: 'CST', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Shanghai', country: 'China', flag: '🇨🇳', timezone: 'CST', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Hong Kong', country: 'China', flag: '🇭🇰', timezone: 'HKT', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Seoul', country: 'South Korea', flag: '🇰🇷', timezone: 'KST', utcOffset: 9, continent: 'Asia'),
  WorldCity(name: 'Tokyo', country: 'Japan', flag: '🇯🇵', timezone: 'JST', utcOffset: 9, continent: 'Asia'),
  WorldCity(name: 'Taipei', country: 'Taiwan', flag: '🇹🇼', timezone: 'CST', utcOffset: 8, continent: 'Asia'),
  WorldCity(name: 'Kathmandu', country: 'Nepal', flag: '🇳🇵', timezone: 'NPT', utcOffset: 5.75, continent: 'Asia'),
  // Oceania
  WorldCity(name: 'Sydney', country: 'Australia', flag: '🇦🇺', timezone: 'AEST', utcOffset: 10, continent: 'Oceania'),
  WorldCity(name: 'Melbourne', country: 'Australia', flag: '🇦🇺', timezone: 'AEST', utcOffset: 10, continent: 'Oceania'),
  WorldCity(name: 'Brisbane', country: 'Australia', flag: '🇦🇺', timezone: 'AEST', utcOffset: 10, continent: 'Oceania'),
  WorldCity(name: 'Perth', country: 'Australia', flag: '🇦🇺', timezone: 'AWST', utcOffset: 8, continent: 'Oceania'),
  WorldCity(name: 'Auckland', country: 'New Zealand', flag: '🇳🇿', timezone: 'NZST', utcOffset: 12, continent: 'Oceania'),
];

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  late Timer _timer;
  List<WorldCity> _selected = [];
  bool _showSearch = false;
  String _searchQuery = '';
  String _selectedContinent = 'All';

  final List<String> _continents = ['All', 'Americas', 'Europe', 'Middle East', 'Africa', 'Asia', 'Oceania'];

  @override
  void initState() {
    super.initState();
    _selected = [
      _allCities.firstWhere((c) => c.name == 'New York'),
      _allCities.firstWhere((c) => c.name == 'London'),
      _allCities.firstWhere((c) => c.name == 'Dubai'),
      _allCities.firstWhere((c) => c.name == 'Mumbai'),
      _allCities.firstWhere((c) => c.name == 'Hyderabad'),
      _allCities.firstWhere((c) => c.name == 'Tokyo'),
      _allCities.firstWhere((c) => c.name == 'Sydney'),
    ];
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  List<WorldCity> get _filteredCities {
    var list = _allCities.toList();
    if (_selectedContinent != 'All') {
      list = list.where((c) => c.continent == _selectedContinent).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((c) =>
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.country.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return list;
  }

  void _toggleCity(WorldCity city) {
    setState(() {
      if (_selected.any((c) => c.name == city.name)) {
        _selected.removeWhere((c) => c.name == city.name);
      } else {
        _selected.add(city);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('WORLD CLOCK',
                      style: TextStyle(fontSize: 13, letterSpacing: 4,
                          color: Color(0xFF4A6A90), fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) _searchQuery = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _showSearch
                            ? const Color(0xFF00B4D8).withOpacity(0.2)
                            : const Color(0xFF00B4D8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF00B4D8).withOpacity(0.4)),
                      ),
                      child: Icon(
                        _showSearch ? Icons.close : Icons.add,
                        color: const Color(0xFF00B4D8), size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_showSearch) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search cities or countries...',
                    hintStyle: const TextStyle(color: Color(0xFF4A6A90)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4A6A90), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF00B4D8))),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Continent filter chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _continents.length,
                  itemBuilder: (_, i) {
                    final c = _continents[i];
                    final isActive = _selectedContinent == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedContinent = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF00B4D8)
                              : const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF00B4D8)
                                : const Color(0xFF1E3A5F),
                          ),
                        ),
                        child: Text(c,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : const Color(0xFF4A6A90),
                            )),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // City count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('${_filteredCities.length} cities',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
                  ],
                ),
              ),

              SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredCities.length,
                  itemBuilder: (_, i) {
                    final city = _filteredCities[i];
                    final isSelected = _selected.any((c) => c.name == city.name);
                    return ListTile(
                      dense: true,
                      leading: Text(city.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(city.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('${city.country} • ${city.offsetString}',
                          style: const TextStyle(color: Color(0xFF4A6A90), fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(city.timeString,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? const Color(0xFF00B4D8)
                                    : const Color(0xFF4A6A90),
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected ? Icons.check_circle : Icons.add_circle_outline,
                            color: isSelected
                                ? const Color(0xFF00B4D8)
                                : const Color(0xFF4A6A90),
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () => _toggleCity(city),
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFF1E3A5F)),
            ],

            // Selected count header
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_selected.length} cities tracked',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
                    GestureDetector(
                      onTap: () => setState(() => _selected.clear()),
                      child: const Text('Clear all',
                          style: TextStyle(fontSize: 11, color: Color(0xFFFF6B6B))),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _selected.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.language, size: 56, color: Color(0xFF1E3A5F)),
                    SizedBox(height: 16),
                    Text('Tap + to add cities',
                        style: TextStyle(color: Color(0xFF4A6A90), fontSize: 16)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selected.length,
                itemBuilder: (_, i) => _WorldCityTile(
                  city: _selected[i],
                  onRemove: () => setState(() => _selected.removeAt(i)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldCityTile extends StatelessWidget {
  final WorldCity city;
  final VoidCallback onRemove;

  const _WorldCityTile({required this.city, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          Text(city.flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      city.isDay ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                      size: 12,
                      color: city.isDay ? const Color(0xFFFFD700) : const Color(0xFF00B4D8),
                    ),
                    const SizedBox(width: 4),
                    Text('${city.country} • ${city.timezone} • ${city.offsetString}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(city.timeString,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
              Text(city.dateString,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF4A6A90))),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.remove_circle_outline,
                color: Color(0xFF2A4A6A), size: 18),
          ),
        ],
      ),
    );
  }
}