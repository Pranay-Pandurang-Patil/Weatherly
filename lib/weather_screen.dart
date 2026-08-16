import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:weatherapp/addinfo.dart';
import 'package:weatherapp/hourinfo.dart';
import 'package:http/http.dart' as http;
import 'package:weatherapp/secrets.dart';
import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather;

  /// 🌙 NIGHT = 8 PM → 4 AM
  bool isNightByTime(DateTime time) {
    final hour = time.hour;
    return hour >= 20 || hour < 4;
  }

  Future<Map<String, dynamic>> getCurrentweather() async {
    try {
      String cityName = 'Mumbai';
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openweather',
        ),
      );
      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'An unexpected error occured';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentweather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentweather();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];

          final currentTime = DateTime.now();
          final isNight = isNightByTime(currentTime);

          final currentPressure = currentWeatherData['main']['pressure'];
          final currentHumidity = currentWeatherData['main']['humidity'];
          final currentWindSpeed = currentWeatherData['wind']['speed'];

          /// 🌤 CURRENT WEATHER ICON (TIME-BASED)
          IconData weatherIcon;

          if (currentSky == 'Clouds') {
            weatherIcon = Icons.cloud;
          } else if (currentSky == 'Rain') {
            weatherIcon = Icons.beach_access;
          } else if (currentSky == 'Clear' && isNight) {
            weatherIcon = Icons.nightlight_round;
          } else if (currentSky == 'Clear') {
            weatherIcon = Icons.wb_sunny;
          } else {
            weatherIcon = Icons.wb_cloudy;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '$currentTemp',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(weatherIcon, size: 64),
                              const SizedBox(height: 10),
                              Text(
                                currentSky,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  'Hourly Forecast',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: 5,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final hourlyForecast = data['list'][index + 1];
                      final time = DateTime.parse(hourlyForecast['dt_txt']);

                      final sky = hourlyForecast['weather'][0]['main'];
                      final isNight = isNightByTime(time);

                      IconData hourlyIcon;

                      if (sky == 'Clouds') {
                        hourlyIcon = Icons.cloud;
                      } else if (sky == 'Rain') {
                        hourlyIcon = Icons.beach_access;
                      } else if (sky == 'Clear' && isNight) {
                        hourlyIcon = Icons.nightlight_round;
                      } else if (sky == 'Clear') {
                        hourlyIcon = Icons.wb_sunny;
                      } else {
                        hourlyIcon = Icons.wb_cloudy;
                      }

                      return HourlyForecastItem(
                        time: DateFormat.jm().format(time),
                        temperature: hourlyForecast['main']['temp'].toString(),
                        icon: hourlyIcon,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 50),

                const Text(
                  'Additional Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Addinfo(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: '$currentHumidity %',
                    ),
                    Addinfo(
                      icon: Icons.air,
                      label: 'Wind Speed',
                      value: '$currentWindSpeed m/s',
                    ),
                    Addinfo(
                      icon: Icons.beach_access,
                      label: 'Pressure',
                      value: '$currentPressure hPa',
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
}
