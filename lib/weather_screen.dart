import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weatherapp/addinfo.dart';
import 'package:weatherapp/hourinfo.dart';
import 'package:weatherapp/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather;

  String cityName = 'Mumbai';

  bool usingCurrentLocation = false;

  final TextEditingController searchController =
  TextEditingController();

  /// 🌙 NIGHT = 8 PM → 4 AM
  bool isNightByTime(DateTime time) {
    final hour = time.hour;
    return hour >= 20 || hour < 4;
  }

  /// 🌤 WEATHER ICON
  IconData getWeatherIcon(String sky, bool isNight) {
    if (sky == 'Thunderstorm') {
      return Icons.thunderstorm;
    } else if (sky == 'Drizzle') {
      return Icons.grain;
    } else if (sky == 'Rain') {
      return Icons.water_drop;
    } else if (sky == 'Snow') {
      return Icons.ac_unit;
    } else if (sky == 'Clear' && isNight) {
      return Icons.nightlight_round;
    } else if (sky == 'Clear') {
      return Icons.wb_sunny;
    } else if (sky == 'Clouds') {
      return Icons.cloud;
    } else if (sky == 'Mist' ||
        sky == 'Fog' ||
        sky == 'Haze' ||
        sky == 'Smoke' ||
        sky == 'Dust' ||
        sky == 'Sand' ||
        sky == 'Ash') {
      return Icons.blur_on;
    } else {
      return Icons.wb_cloudy;
    }
  }

  /// 📍 GET CURRENT LOCATION
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied.';
    }

    return await Geolocator.getCurrentPosition();
  }

  /// 📍 GET WEATHER USING CURRENT LOCATION
  Future<Map<String, dynamic>> getWeatherByLocation() async {
    try {
      final position = await getCurrentLocation();

      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast'
              '?lat=${position.latitude}'
              '&lon=${position.longitude}'
              '&APPID=$openweather'
              '&units=metric',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw data['message'] ?? 'Unable to fetch weather';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  /// 💾 SAVE LAST SEARCHED CITY
  Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('last_city', city);
  }

  /// 🌤 GET WEATHER USING CITY NAME
  Future<Map<String, dynamic>> getCurrentweather() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast'
              '?q=$cityName'
              '&APPID=$openweather'
              '&units=metric',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw data['message'] ?? 'Unable to fetch weather';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  /// 💾 LOAD SAVED CITY AND WEATHER
  Future<Map<String, dynamic>> loadWeather() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCity = prefs.getString('last_city');

    if (savedCity != null && savedCity.isNotEmpty) {
      cityName = savedCity;
    }

    return getCurrentweather();
  }

  @override
  void initState() {
    super.initState();

    weather = loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (usingCurrentLocation) {
                  weather = getWeatherByLocation();
                } else {
                  weather = getCurrentweather();
                }
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load weather',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (usingCurrentLocation) {
                          weather =
                              getWeatherByLocation();
                        } else {
                          weather =
                              getCurrentweather();
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          final locationName = data['city']['name'];
          final countryCode = data['city']['country'];

          final currentWeatherData = data['list'][0];

          final currentTemp =
          currentWeatherData['main']['temp'];

          final feelsLike =
          currentWeatherData['main']['feels_like'];

          final currentSky =
          currentWeatherData['weather'][0]['main'];

          final currentDescription =
          currentWeatherData['weather'][0]
          ['description'];

          final currentTime = DateTime.now();

          final isNight =
          isNightByTime(currentTime);

          final currentPressure =
          currentWeatherData['main']['pressure'];

          final currentHumidity =
          currentWeatherData['main']['humidity'];

          final currentWindSpeed =
          currentWeatherData['wind']['speed'];

          /// 🌤 CURRENT WEATHER ICON
          final IconData weatherIcon =
          getWeatherIcon(
            currentSky,
            isNight,
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                /// 🔎 SEARCH CITY
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        textInputAction:
                        TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search city',
                          prefixIcon:
                          const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward,
                            ),
                            onPressed: () {
                              final value =
                              searchController.text
                                  .trim();

                              if (value.isEmpty) {
                                return;
                              }

                              setState(() {
                                cityName = value;
                                usingCurrentLocation =
                                false;
                                weather =
                                    getCurrentweather();
                              });

                              saveCity(cityName);

                              searchController.clear();
                            },
                          ),
                          border:
                          const OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isEmpty) {
                            return;
                          }

                          setState(() {
                            cityName = value.trim();
                            usingCurrentLocation =
                            false;
                            weather =
                                getCurrentweather();
                          });

                          saveCity(cityName);

                          searchController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Use my location',
                      onPressed: () {
                        setState(() {
                          usingCurrentLocation = true;
                          weather =
                              getWeatherByLocation();
                        });
                      },
                      icon: const Icon(
                        Icons.my_location,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// 📍 LOCATION
                Text(
                  '$locationName, $countryCode',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🌡️ CURRENT WEATHER
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),
                        child: Padding(
                          padding:
                          const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '${currentTemp.round()}°C',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Icon(
                                weatherIcon,
                                size: 64,
                              ),

                              const SizedBox(height: 10),

                              Text(
                                currentDescription
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Feels like ${feelsLike.round()}°C',
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                /// 🕐 3-HOUR FORECAST
                const Text(
                  '3-Hour Forecast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount:
                    data['list'].length > 1
                        ? (data['list'].length - 1)
                        .clamp(0, 5)
                        : 0,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final hourlyForecast =
                      data['list'][index + 1];

                      final time = DateTime.parse(
                        hourlyForecast['dt_txt'],
                      );

                      final sky =
                      hourlyForecast['weather'][0]
                      ['main'];

                      final isNight =
                      isNightByTime(time);

                      final IconData hourlyIcon =
                      getWeatherIcon(
                        sky,
                        isNight,
                      );

                      return HourlyForecastItem(
                        time:
                        DateFormat.jm().format(time),
                        temperature:
                        '${hourlyForecast['main']['temp'].round()}°C',
                        icon: hourlyIcon,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 50),

                /// ℹ️ ADDITIONAL INFORMATION
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    Addinfo(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value:
                      '$currentHumidity %',
                    ),
                    Addinfo(
                      icon: Icons.air,
                      label: 'Wind Speed',
                      value:
                      '${currentWindSpeed.toStringAsFixed(1)} m/s',
                    ),
                    Addinfo(
                      icon: Icons.beach_access,
                      label: 'Pressure',
                      value:
                      '$currentPressure hPa',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}