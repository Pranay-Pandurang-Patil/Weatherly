import 'dart:convert';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      return Icons.thunderstorm_rounded;
    } else if (sky == 'Drizzle') {
      return Icons.grain_rounded;
    } else if (sky == 'Rain') {
      return Icons.water_drop_rounded;
    } else if (sky == 'Snow') {
      return Icons.ac_unit_rounded;
    } else if (sky == 'Clear' && isNight) {
      return Icons.nightlight_round;
    } else if (sky == 'Clear') {
      return Icons.wb_sunny_rounded;
    } else if (sky == 'Clouds') {
      return Icons.cloud_rounded;
    } else if (sky == 'Mist' ||
        sky == 'Fog' ||
        sky == 'Haze' ||
        sky == 'Smoke' ||
        sky == 'Dust' ||
        sky == 'Sand' ||
        sky == 'Ash') {
      return Icons.blur_on_rounded;
    } else {
      return Icons.wb_cloudy_rounded;
    }
  }

  /// 🎨 BACKGROUND COLORS
  List<Color> getBackgroundColors(
      String sky,
      bool isNight,
      ) {
    if (isNight) {
      if (sky == 'Rain' ||
          sky == 'Drizzle' ||
          sky == 'Thunderstorm') {
        return const [
          Color(0xFF101827),
          Color(0xFF1B2740),
          Color(0xFF283A5A),
        ];
      }

      return const [
        Color(0xFF080D21),
        Color(0xFF111A3D),
        Color(0xFF26345E),
      ];
    }

    if (sky == 'Rain' ||
        sky == 'Drizzle' ||
        sky == 'Thunderstorm') {
      return const [
        Color(0xFF355C7D),
        Color(0xFF4C7895),
        Color(0xFF6C8EA3),
      ];
    }

    if (sky == 'Clouds') {
      return const [
        Color(0xFF4F79A1),
        Color(0xFF7195B5),
        Color(0xFFA7BBCB),
      ];
    }

    if (sky == 'Snow') {
      return const [
        Color(0xFF8EB6D1),
        Color(0xFFB9D5E6),
        Color(0xFFE0EDF3),
      ];
    }

    return const [
      Color(0xFF2387D9),
      Color(0xFF43A5E8),
      Color(0xFF8BCBF1),
    ];
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
  Future<Map<String, dynamic>> getCurrentWeather() async {
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

  /// 💾 LOAD SAVED CITY
  Future<Map<String, dynamic>> loadWeather() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCity = prefs.getString('last_city');

    if (savedCity != null && savedCity.isNotEmpty) {
      cityName = savedCity;
    }

    return getCurrentWeather();
  }

  @override
  void initState() {
    super.initState();

    weather = loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const _LoadingScreen();
          }

          if (snapshot.hasError) {
            return _ErrorScreen(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  if (usingCurrentLocation) {
                    weather = getWeatherByLocation();
                  } else {
                    weather = getCurrentWeather();
                  }
                });
              },
            );
          }

          final data = snapshot.data!;

          final locationName =
          data['city']['name'];

          final countryCode =
          data['city']['country'];

          final forecastList =
          data['list'] as List;

          final currentWeatherData =
          forecastList[0];

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

          final weatherIcon =
          getWeatherIcon(
            currentSky,
            isNight,
          );

          final backgroundColors =
          getBackgroundColors(
            currentSky,
            isNight,
          );

          final forecastCount =
          forecastList.length > 1
              ? (forecastList.length - 1)
              .clamp(0, 5)
              : 0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: backgroundColors,
              ),
            ),
            child: Stack(
              children: [
                _WeatherDecoration(
                  sky: currentSky,
                  isNight: isNight,
                ),

                SafeArea(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        if (usingCurrentLocation) {
                          weather =
                              getWeatherByLocation();
                        } else {
                          weather =
                              getCurrentWeather();
                        }
                      });

                      await weather;
                    },
                    child: CustomScrollView(
                      physics:
                      const BouncingScrollPhysics(
                        parent:
                        AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding:
                          const EdgeInsets.fromLTRB(
                            20,
                            12,
                            20,
                            32,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                /// TOP BAR
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    _GlassIconButton(
                                      icon: Icons
                                          .refresh_rounded,
                                      onTap: () {
                                        setState(() {
                                          if (usingCurrentLocation) {
                                            weather =
                                                getWeatherByLocation();
                                          } else {
                                            weather =
                                                getCurrentWeather();
                                          }
                                        });
                                      },
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .location_on_rounded,
                                              color:
                                              Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(
                                              width: 4,
                                            ),
                                            Text(
                                              '$locationName, $countryCode',
                                              style:
                                              const TextStyle(
                                                color:
                                                Colors.white,
                                                fontSize: 18,
                                                fontWeight:
                                                FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    _GlassIconButton(
                                      icon: isNight
                                          ? Icons
                                          .dark_mode_rounded
                                          : Icons
                                          .wb_sunny_rounded,
                                      onTap: () {},
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 22),

                                /// SEARCH
                                _GlassSearchBar(
                                  controller:
                                  searchController,
                                  onSearch: (value) {
                                    if (value
                                        .trim()
                                        .isEmpty) {
                                      return;
                                    }

                                    setState(() {
                                      cityName =
                                          value.trim();
                                      usingCurrentLocation =
                                      false;
                                      weather =
                                          getCurrentWeather();
                                    });

                                    saveCity(cityName);
                                    searchController.clear();
                                  },
                                  onLocation: () {
                                    setState(() {
                                      usingCurrentLocation =
                                      true;
                                      weather =
                                          getWeatherByLocation();
                                    });
                                  },
                                ),

                                const SizedBox(height: 34),

                                /// MAIN WEATHER
                                Column(
                                  children: [
                                    Text(
                                      '${currentTemp.round()}°',
                                      style:
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 86,
                                        height: 0.95,
                                        fontWeight:
                                        FontWeight.w300,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        Icon(
                                          weatherIcon,
                                          color:
                                          Colors.white,
                                          size: 28,
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Text(
                                          currentDescription
                                              .toString()
                                              .replaceFirst(
                                            currentDescription
                                                .toString()[0],
                                            currentDescription
                                                .toString()[0]
                                                .toUpperCase(),
                                          ),
                                          style:
                                          const TextStyle(
                                            color:
                                            Colors.white,
                                            fontSize: 21,
                                            fontWeight:
                                            FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Feels like ${feelsLike.round()}°C',
                                      style:
                                      TextStyle(
                                        color: Colors.white
                                            .withValues(alpha:
                                          0.78,
                                        ),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                /// GLASS WEATHER SUMMARY
                                _GlassWeatherSummary(
                                  temperature:
                                  currentTemp.round(),
                                  feelsLike:
                                  feelsLike.round(),
                                  description:
                                  currentDescription
                                      .toString(),
                                  icon: weatherIcon,
                                ),

                                const SizedBox(height: 28),

                                /// FORECAST
                                _GlassSection(
                                  title:
                                  '3-Hour Forecast',
                                  trailing:
                                  'Next 15 hours',
                                  child: SizedBox(
                                    height: 158,
                                    child:
                                    ListView.builder(
                                      scrollDirection:
                                      Axis.horizontal,
                                      physics:
                                      const BouncingScrollPhysics(),
                                      itemCount:
                                      forecastCount,
                                      itemBuilder:
                                          (context, index) {
                                        final forecast =
                                        forecastList[
                                        index + 1];

                                        final time =
                                        DateTime.parse(
                                          forecast[
                                          'dt_txt'],
                                        );

                                        final sky =
                                        forecast[
                                        'weather']
                                        [0]['main'];

                                        final forecastNight =
                                        isNightByTime(
                                          time,
                                        );

                                        final icon =
                                        getWeatherIcon(
                                          sky,
                                          forecastNight,
                                        );

                                        return _ForecastCard(
                                          time:
                                          DateFormat.jm()
                                              .format(
                                            time,
                                          ),
                                          temperature:
                                          '${forecast['main']['temp'].round()}°',
                                          icon: icon,
                                          active: index == 0,
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                /// ADDITIONAL INFORMATION
                                _GlassSection(
                                  title:
                                  'Weather Details',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        _WeatherDetailCard(
                                          icon: Icons
                                              .water_drop_rounded,
                                          title:
                                          'Humidity',
                                          value:
                                          '$currentHumidity%',
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child:
                                        _WeatherDetailCard(
                                          icon: Icons
                                              .air_rounded,
                                          title:
                                          'Wind',
                                          value:
                                          '${currentWindSpeed.toStringAsFixed(1)} m/s',
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child:
                                        _WeatherDetailCard(
                                          icon: Icons
                                              .speed_rounded,
                                          title:
                                          'Pressure',
                                          value:
                                          '$currentPressure',
                                          suffix: 'hPa',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                /// FEELS LIKE CARD
                                _GlassInfoCard(
                                  icon:
                                  Icons.thermostat_rounded,
                                  title:
                                  'Feels like',
                                  value:
                                  '${feelsLike.round()}°C',
                                  subtitle:
                                  'Based on current conditions',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

/// ─────────────────────────────────────────────
/// LOADING
/// ─────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2387D9),
            Color(0xFF4264A8),
            Color(0xFF18264B),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_rounded,
              color: Colors.white,
              size: 58,
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            SizedBox(height: 18),
            Text(
              'Loading weather...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// ERROR
/// ─────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF263D62),
            Color(0xFF111A30),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 18),
              const Text(
                'Weather unavailable',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha:0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// WEATHER BACKGROUND DECORATION
/// ─────────────────────────────────────────────

class _WeatherDecoration extends StatefulWidget {
  final String sky;
  final bool isNight;

  const _WeatherDecoration({
    required this.sky,
    required this.isNight,
  });

  @override
  State<_WeatherDecoration> createState() =>
      _WeatherDecorationState();
}

class _WeatherDecorationState
    extends State<_WeatherDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          // Smooth repeating wave from -1 to 1.
          final wave = sin(progress * 2 * pi);

          // Smooth repeating wave from 0 to 1.
          final pulse = (wave + 1) / 2;

          return Stack(
            children: [
              /// ☀️ SUNNY GLOW
              if (!widget.isNight &&
                  widget.sky == 'Clear')
                Positioned(
                  top: 65 + (pulse * 8),
                  right: -35,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha:
                        0.07 + (pulse * 0.04),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withValues(alpha:
                            0.12 + (pulse * 0.08),
                          ),
                          blurRadius: 65 + (pulse * 20),
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),

              /// 🌙 NIGHT STARS
              if (widget.isNight)
                ...List.generate(
                  14,
                      (index) {
                    final positions = [
                      const Offset(30, 90),
                      const Offset(95, 145),
                      const Offset(170, 80),
                      const Offset(250, 125),
                      const Offset(335, 75),
                      const Offset(55, 230),
                      const Offset(215, 205),
                      const Offset(315, 280),
                      const Offset(130, 300),
                      const Offset(40, 370),
                      const Offset(280, 380),
                      const Offset(190, 420),
                      const Offset(350, 440),
                      const Offset(90, 470),
                    ];

                    final starPulse =
                    ((sin(
                      (progress * 2 * pi) +
                          (index * 0.7),
                    ) +
                        1) /
                        2);

                    return Positioned(
                      left: positions[index].dx,
                      top: positions[index].dy,
                      child: Opacity(
                        opacity:
                        0.2 + (starPulse * 0.6),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 5,
                        ),
                      ),
                    );
                  },
                ),

              /// 🌧️ RAIN
              if (widget.sky == 'Rain' ||
                  widget.sky == 'Drizzle')
                ...List.generate(
                  20,
                      (index) {
                    final x =
                        (index * 47.0) % 420;

                    final rainProgress =
                        (progress +
                            (index * 0.055)) %
                            1;

                    final y =
                        -80 + (rainProgress * 900);

                    return Positioned(
                      left: x,
                      top: y,
                      child: Container(
                        width: 1.5,
                        height: 18,
                        decoration: BoxDecoration(
                          color:
                          Colors.white.withValues(alpha:
                            0.20,
                          ),
                          borderRadius:
                          BorderRadius.circular(4),
                        ),
                      ),
                    );
                  },
                ),

              /// ❄️ SNOW
              if (widget.sky == 'Snow')
                ...List.generate(
                  16,
                      (index) {
                    final baseX =
                        (index * 61.0) % 420;

                    final snowProgress =
                        (progress +
                            (index * 0.08)) %
                            1;

                    final y =
                        -30 + (snowProgress * 900);

                    final drift =
                        sin(
                          (snowProgress * 2 * pi) +
                              index,
                        ) *
                            15;

                    return Positioned(
                      left: baseX + drift,
                      top: y,
                      child: Opacity(
                        opacity: 0.5,
                        child: const Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 5,
                        ),
                      ),
                    );
                  },
                ),

              /// ☁️ CLOUDS
              if (widget.sky == 'Clouds')
                Positioned(
                  top: 105,
                  left: -55 + (wave * 45),
                  child: Opacity(
                    opacity: 0.08,
                    child: const Icon(
                      Icons.cloud_rounded,
                      size: 180,
                      color: Colors.white,
                    ),
                  ),
                ),

              /// ⛈️ THUNDERSTORM
              if (widget.sky == 'Thunderstorm')
                Positioned(
                  top: 120,
                  right: 35,
                  child: Opacity(
                    opacity: pulse > 0.88 ? 0.8 : 0.05,
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 110,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// GLASS SEARCH BAR
/// ─────────────────────────────────────────────

class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onLocation;

  const _GlassSearchBar({
    required this.controller,
    required this.onSearch,
    required this.onLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.25),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha:0.8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction:
                  TextInputAction.search,
                  onSubmitted: onSearch,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search city...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha:0.55),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  if (controller.text
                      .trim()
                      .isNotEmpty) {
                    onSearch(controller.text);
                  }
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.16),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onLocation,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// GLASS ICON BUTTON
/// ─────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.18),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// WEATHER SUMMARY
/// ─────────────────────────────────────────────

class _GlassWeatherSummary extends StatelessWidget {
  final int temperature;
  final int feelsLike;
  final String description;
  final IconData icon;

  const _GlassWeatherSummary({
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.11),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Current temperature',
                      style: TextStyle(
                        color:
                        Colors.white.withValues(alpha:0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$temperature°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// SECTION
/// ─────────────────────────────────────────────

class _GlassSection extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _GlassSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: TextStyle(
                        color:
                        Colors.white.withValues(alpha:0.55),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// FORECAST CARD
/// ─────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final String time;
  final String temperature;
  final IconData icon;
  final bool active;

  const _ForecastCard({
    required this.time,
    required this.temperature,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha:0.20)
            : Colors.white.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha:0.45)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: active
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha:
                active ? 1 : 0.72,
              ),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
          Text(
            temperature,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// WEATHER DETAIL CARD
/// ─────────────────────────────────────────────

class _WeatherDetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? suffix;

  const _WeatherDetailCard({
    required this.icon,
    required this.title,
    required this.value,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha:0.60),
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (suffix != null)
                const SizedBox(width: 3),
              if (suffix != null)
                Text(
                  suffix!,
                  style: TextStyle(
                    color:
                    Colors.white.withValues(alpha:0.55),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// INFO CARD
/// ─────────────────────────────────────────────

class _GlassInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _GlassInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.09),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                        Colors.white.withValues(alpha:0.65),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                        Colors.white.withValues(alpha:0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}