# Weather API Setup

The app uses the **National Weather Service (NWS) API** for weather data, which provides:
- ✅ **Free** - No API key required
- ✅ **US Coverage** - Covers all US territories
- ✅ **Fahrenheit** - Temperatures in °F by default
- ✅ **Reliable** - Official US government weather service
- ✅ **No Rate Limits** - Public API with reasonable usage

## Features

- **Zipcode Search**: Direct zipcode lookup using US Census Bureau Geocoding API
- **City Name Search**: Geocoding for city names
- **Coordinates**: Direct weather lookup by lat/lon
- **Fahrenheit Display**: All temperatures shown in °F
- **Imperial Units**: Wind speed in mph
- **Fallback**: Falls back to default location (San Francisco) if lookup fails

## API Details

### National Weather Service API
- **Base URL**: `https://api.weather.gov`
- **Documentation**: https://www.weather.gov/documentation/services-web-api
- **User-Agent**: Required header identifying the application
- **Coverage**: US territories only

### Geocoding Services
- **US Census Bureau**: Primary geocoding for US zipcodes (free, no key)
- **Open-Meteo**: Fallback geocoding for city names (free, no key)

## How It Works

1. **Zipcode/City Lookup**: Converts zipcode or city name to coordinates
2. **Gridpoint Lookup**: Gets NWS gridpoint from coordinates
3. **Weather Fetch**: Retrieves current conditions and forecast
4. **Display**: Shows temperature in Fahrenheit, wind in mph

## Troubleshooting

### "Weather Unavailable" Error
- Verify location is within US territories (NWS only covers US)
- Check internet connection
- Review app logs for specific error messages
- Try a different zipcode or city name

### Zipcode Not Found
- Ensure zipcode is a valid US zipcode (5 digits)
- Try searching by city name instead
- Some zipcodes may not be in the geocoding database

### Location Outside US
- NWS API only covers US territories
- The app will show an error for non-US locations

## Notes

- **No API Key Required**: NWS API is completely free and open
- **User-Agent Header**: The app includes a User-Agent header as required by NWS
- **Rate Limiting**: NWS API has no strict rate limits, but be respectful of the service
- **Data Source**: All data comes from official US government weather services


