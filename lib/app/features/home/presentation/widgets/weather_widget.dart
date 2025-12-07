import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../common/widgets/modern_card.dart';
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
          return _buildErrorCard(context, ref);
        }
        return _buildWeatherCard(context, weather);
      },
      loading: () => _buildLoadingCard(context),
      error: (error, stack) => _buildErrorCard(context, ref),
    );
  }

  Widget _buildWeatherCard(BuildContext context, WeatherModel weather) {
    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeatherLocationPicker(),
          ),
        );
      },
      padding: EdgeInsets.zero,
      child: Container(
        padding: ResponsiveHelper.padding(all: 20),
        decoration: BoxDecoration(
          borderRadius: ResponsiveHelper.borderRadius(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.4),
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
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
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: ResponsiveHelper.borderRadius(16),
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
            SizedBox(width: ResponsiveHelper.w(20)),
            // Weather info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${weather.temperature.round()}°',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.0,
                            ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: ResponsiveHelper.padding(bottom: 6, left: 4),
                          child: Text(
                            weather.description.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: ResponsiveHelper.iconSize(14),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      SizedBox(width: ResponsiveHelper.w(4)),
                      Expanded(
                        child: Text(
                          '${weather.city}, ${weather.country}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
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
                  Icons.water_drop_outlined,
                  '${weather.humidity}%',
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                _buildWeatherDetail(
                  context,
                  Icons.air,
                  '${weather.windSpeed.toStringAsFixed(1)} mph',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    BuildContext context,
    IconData icon,
    String value,
  ) {
    return Container(
      padding: ResponsiveHelper.padding(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: ResponsiveHelper.borderRadius(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveHelper.iconSize(14),
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(width: ResponsiveHelper.w(6)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveHelper.sp(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return ModernCard(
      child: SizedBox(
        height: ResponsiveHelper.h(100),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: ResponsiveHelper.w(2)),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref) {
    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeatherLocationPicker(),
          ),
        );
      },
      backgroundColor: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            padding: ResponsiveHelper.padding(all: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: ResponsiveHelper.iconSize(24),
              color: Theme.of(context).colorScheme.error,
            ),
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
                  'Tap to set location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) {
      return Icons.wb_sunny_rounded;
    }
    if (iconCode.startsWith('02')) {
      return Icons.wb_cloudy_rounded;
    }
    if (iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Icons.cloud_rounded;
    }
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) {
      return Icons.grain_rounded;
    }
    if (iconCode.startsWith('11')) {
      return Icons.flash_on_rounded;
    }
    if (iconCode.startsWith('13')) {
      return Icons.ac_unit_rounded;
    }
    if (iconCode.startsWith('50')) {
      return Icons.blur_on_rounded;
    }
    return Icons.wb_sunny_rounded;
  }
}
