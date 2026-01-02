import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/repositories/weather_repository.dart';

class WeatherLocationPicker extends ConsumerStatefulWidget {
  const WeatherLocationPicker({super.key});

  @override
  ConsumerState<WeatherLocationPicker> createState() =>
      _WeatherLocationPickerState();
}

class _WeatherLocationPickerState extends ConsumerState<WeatherLocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherRepository _weatherRepo = WeatherRepository();
  bool _isValidating = false;
  bool _isZipcodeInput = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check if input is a zipcode (supports US 5-digit, US+4, and international formats)
  bool _isZipcode(String input) {
    final trimmed = input.trim();
    // US zipcode: 5 digits (e.g., 10001) or 5+4 format (e.g., 10001-1234)
    if (RegExp(r'^\d{5}(-\d{4})?$').hasMatch(trimmed)) {
      return true;
    }
    // International zipcode: 4-10 digits (e.g., 60060, 12345, etc.)
    if (RegExp(r'^\d{4,10}$').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  Future<void> _selectLocation(String location) async {
    if (location.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    // Check if input is a zipcode
    final isZipcode = _isZipcode(location);

    // For US zipcode format (5+4), use only the 5-digit part
    final zipcodeToSearch = isZipcode
        ? location
              .trim()
              .split('-')
              .first // Use only the 5-digit part for US zipcodes
        : location.trim();

    // Validate the location by trying to get weather for it
    final weather = isZipcode
        ? await _weatherRepo.getWeather(zipcode: zipcodeToSearch)
        : await _weatherRepo.getWeather(cityName: zipcodeToSearch);

    if (weather != null && mounted) {
      // Save the selected location (use the resolved city name from weather)
      final locationName = weather.city;
      ref.read(selectedWeatherLocationProvider.notifier).state = locationName;
      Navigator.pop(context);
    } else {
      if (mounted) {
        // Clear the invalid location selection so widget doesn't keep trying to use it
        // This will cause the provider to fall back to default location
        ref.read(selectedWeatherLocationProvider.notifier).state = null;

        final errorMessage = isZipcode
            ? 'Could not find weather for zipcode "$location". Please verify the zipcode or try searching by city name.'
            : 'Could not find weather for "$location". Please try another location or zipcode.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(selectedWeatherLocationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weather Location')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Current location option
            SliverToBoxAdapter(
              child: ListTile(
                leading: Icon(
                  Icons.my_location,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Use Current Location'),
                subtitle: const Text('Automatically detect your location'),
                trailing: selectedLocation == null
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  ref.read(selectedWeatherLocationProvider.notifier).state =
                      null;
                  // Force refresh of current location
                  ref.invalidate(currentLocationProvider);
                  Navigator.pop(context);
                },
              ),
            ),
            const SliverToBoxAdapter(child: Divider()),

            // Search section
            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveHelper.padding(all: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search for a City or Zipcode',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(12)),
                    TextField(
                      controller: _searchController,
                      enabled: !_isValidating,
                      keyboardType: _isZipcodeInput
                          ? TextInputType.number
                          : TextInputType.text,
                      decoration: InputDecoration(
                        hintText: _isZipcodeInput
                            ? 'Enter zipcode (e.g., 10001, 60060)'
                            : 'Enter city name or zipcode (e.g., New York, 10001)',
                        helperText: _isZipcodeInput
                            ? 'Searching by zipcode'
                            : 'You can search by city name or zipcode',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isZipcodeInput = false;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                      ),
                      onChanged: (value) {
                        // Detect if user is typing a zipcode
                        final isZipcode = _isZipcode(value);
                        setState(() {
                          _isZipcodeInput = isZipcode;
                        });
                      },
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !_isValidating) {
                          _selectLocation(value);
                        }
                      },
                    ),
                    if (_isValidating) ...[
                      SizedBox(height: ResponsiveHelper.h(8)),
                      Row(
                        children: [
                          SizedBox(
                            width: ResponsiveHelper.w(16),
                            height: ResponsiveHelper.h(16),
                            child: CircularProgressIndicator(
                              strokeWidth: ResponsiveHelper.w(2),
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.w(8)),
                          Text(
                            'Validating location...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Popular cities header
            SliverToBoxAdapter(
              child: Padding(
                padding: ResponsiveHelper.padding(horizontal: 16, bottom: 12),
                child: Text(
                  'Popular Cities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Popular cities list
            SliverPadding(
              padding: ResponsiveHelper.padding(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildPopularCities(context, selectedLocation),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPopularCities(
    BuildContext context,
    String? selectedLocation,
  ) {
    final popularCities = [
      {'name': 'New York', 'country': 'US'},
      {'name': 'London', 'country': 'GB'},
      {'name': 'Tokyo', 'country': 'JP'},
      {'name': 'Paris', 'country': 'FR'},
      {'name': 'Sydney', 'country': 'AU'},
      {'name': 'Toronto', 'country': 'CA'},
      {'name': 'Berlin', 'country': 'DE'},
      {'name': 'Mumbai', 'country': 'IN'},
      {'name': 'São Paulo', 'country': 'BR'},
      {'name': 'Dubai', 'country': 'AE'},
    ];

    return popularCities.map((city) {
      final cityName = city['name'] as String;
      final isSelected = selectedLocation == cityName;

      return ListTile(
        leading: Icon(
          Icons.location_city,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
        title: Text(cityName),
        subtitle: Text(city['country'] as String),
        trailing: isSelected
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: _isValidating ? null : () => _selectLocation(cityName),
      );
    }).toList();
  }
}
