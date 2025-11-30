import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/weather_model.dart';
import 'weather_location_picker.dart';

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return weatherAsync.when(
      data: (weather) {
        if (weather == null) {
          // Show error card instead of hiding widget
          return _buildErrorCard(context, ref);
        }
        return _buildWeatherCard(context, weather);
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, ref), // Show error card instead of hiding
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherModel weather) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeatherLocationPicker(),
            ),
          );
        },
        borderRadius: ResponsiveHelper.borderRadius(12),
        child: Container(
          padding: ResponsiveHelper.padding(all: 16),
          decoration: BoxDecoration(
            borderRadius: ResponsiveHelper.borderRadius(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              // Weather icon
              Container(
                width: ResponsiveHelper.w(64),
                height: ResponsiveHelper.h(64),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: ResponsiveHelper.borderRadius(12),
                ),
                child: Image.network(
                  'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                  errorBuilder: (context, error, stackTrace) => Icon(
                    _getWeatherIcon(weather.icon),
                    size: ResponsiveHelper.iconSize(32),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(16)),
              // Weather info
              Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°F',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Text(
                    weather.description.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Text(
                    '${weather.city}, ${weather.country}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: ResponsiveHelper.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            // Additional info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildWeatherDetail(
                  context,
                  Icons.water_drop,
                  '${weather.humidity}%',
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                _buildWeatherDetail(
                  context,
                  Icons.air,
                  '${weather.windSpeed.toStringAsFixed(1)} mph',
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                // Location change icon
                IconButton(
                  icon: Icon(
                    Icons.edit_location_alt,
                    size: ResponsiveHelper.iconSize(18),
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeatherLocationPicker(),
                      ),
                    );
                  },
                  tooltip: 'Change location',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveHelper.iconSize(14),
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        SizedBox(width: ResponsiveHelper.w(4)),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: ResponsiveHelper.sp(11),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      child: Container(
        padding: ResponsiveHelper.padding(all: 16),
        height: ResponsiveHelper.h(96),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: ResponsiveHelper.w(2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeatherLocationPicker(),
            ),
          );
        },
        borderRadius: ResponsiveHelper.borderRadius(12),
        child: Container(
          padding: ResponsiveHelper.padding(all: 16),
          decoration: BoxDecoration(
            borderRadius: ResponsiveHelper.borderRadius(12),
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveHelper.iconSize(32),
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(width: ResponsiveHelper.w(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Weather Unavailable',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(4)),
                    Text(
                      'Tap to select a location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    // Map OpenWeatherMap icon codes to Material icons
    if (iconCode.startsWith('01')) return Icons.wb_sunny; // clear sky
    if (iconCode.startsWith('02')) return Icons.wb_cloudy; // few clouds
    if (iconCode.startsWith('03') || iconCode.startsWith('04')) return Icons.cloud; // clouds
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.grain; // rain
    if (iconCode.startsWith('11')) return Icons.flash_on; // thunderstorm
    if (iconCode.startsWith('13')) return Icons.ac_unit; // snow
    if (iconCode.startsWith('50')) return Icons.blur_on; // mist
    return Icons.wb_sunny;
  }
}

