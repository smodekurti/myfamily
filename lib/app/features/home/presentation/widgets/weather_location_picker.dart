import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/repositories/weather_repository.dart';

class WeatherLocationPicker extends ConsumerStatefulWidget {
  const WeatherLocationPicker({super.key});

  @override
  ConsumerState<WeatherLocationPicker> createState() => _WeatherLocationPickerState();
}

class _WeatherLocationPickerState extends ConsumerState<WeatherLocationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherRepository _weatherRepo = WeatherRepository();
  bool _isValidating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation(String location) async {
    if (location.isEmpty) return;

    setState(() {
      _isValidating = true;
    });

    // Check if input is a zipcode (numeric, 5 digits for US, or other formats)
    final isZipcode = RegExp(r'^\d{4,10}$').hasMatch(location.trim());
    
    // Validate the location by trying to get weather for it
    final weather = isZipcode
        ? await _weatherRepo.getWeather(zipcode: location.trim())
        : await _weatherRepo.getWeather(cityName: location.trim());
    
    if (weather != null && mounted) {
      // Save the selected location (use the resolved city name from weather)
      final locationName = weather.city;
      ref.read(selectedWeatherLocationProvider.notifier).state = locationName;
      Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find weather for "$location". Please try another location or zipcode.'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      appBar: AppBar(
        title: const Text('Weather Location'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Current location option
            ListTile(
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
                ref.read(selectedWeatherLocationProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),
            const Divider(),
            
            // Search section
            Padding(
              padding: ResponsiveHelper.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search for a City',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(12)),
                  TextField(
                    controller: _searchController,
                    enabled: !_isValidating,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Enter city name or zipcode (e.g., New York, 10001)',
                      helperText: 'You can search by city name or zipcode',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: ResponsiveHelper.borderRadius(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Popular cities
            Expanded(
              child: ListView(
                padding: ResponsiveHelper.padding(horizontal: 16),
                children: [
                  Text(
                    'Popular Cities',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(12)),
                  ..._buildPopularCities(context, selectedLocation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPopularCities(BuildContext context, String? selectedLocation) {
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        title: Text(cityName),
        subtitle: Text(city['country'] as String),
        trailing: isSelected
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: _isValidating ? null : () => _selectLocation(cityName),
      );
    }).toList();
  }
}
