import 'dart:async';
import 'dart:convert';
import 'package:agri_connect/utils/weatherContainer.dart';
import 'package:http/http.dart' as http;
import 'package:agri_connect/API/api.dart';
import 'package:agri_connect/API/mlApi.dart';
import 'package:agri_connect/constants/sizes.dart';
import 'package:agri_connect/helper_functions/helper_functions.dart';
import 'package:agri_connect/models/nutritionData_model.dart';
import 'package:agri_connect/models/sensorData_model.dart';
import 'package:agri_connect/utils/analysis_box.dart';
import 'package:agri_connect/utils/appbar.dart';
import 'package:agri_connect/utils/home_container.dart';
import 'package:agri_connect/utils/npk_box.dart';
import 'package:agri_connect/utils/sensor_data_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/weather_model.dart';
import '../API/weather_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  List<Color> gradientColors = [
    Colors.cyan,
    Colors.blue,
  ];
  String appBarTittle = '';
  bool showAvg = false;
  final PageController _pageController = PageController();
  final PageController _pageController2 = PageController();
  late Future<List<SensorDataModel>> _sensorDataFuture;
  List<SensorDataModel>? _sensorDataList;
  late Future<List<NutritionDataModel>> _nutritionDataFuture;
  List<NutritionDataModel>? _nutritionDataList;
  double _rotationAngle = 0.0;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String _response = '';
  String _selectedLanguage = 'English';
  Timer? _timer;
  // Motor control
  late AnimationController _motorController;
  String? motorStatus = 'OFF'; // Default motor status
  // Weather service API key
  final _weatherService = WeatherService('90bf9ca3170d2fbeddd2548cddcb6c33');
  Weather? _weather;
  //forecast
  Map<String, dynamic>? data;
  List<dynamic>? hourlyTimes;
  List<dynamic>? hourlyTemperatures;
  List<dynamic>? hourlyHumidities;
  List<dynamic>? hourlyCode;
  String? timezone;
  String? formattedDate;
  String? greeting;
  String? formattedTime;

  // Fetch weather data
  _fetchWeather() async {
    // Get current city
    String cityName = await _weatherService.getCurrentCity();

    // Get weather for city
    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
      });
    } catch (e) {
      print(e);
    }
  }

  // Weather animations
  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/animations/loader4.json';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
        return 'assets/animations/cloud.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/animations/rain.json';
      case 'thunderstorm':
        return 'assets/animations/thunder.json';
      case 'clear':
        return 'assets/animations/sunny.json';
      default:
        return 'assets/animations/sunny.json';
    }
  }

  Future<List<SensorDataModel>> _fetchSensorData() async {
    try {
      final data = await SensorDataService().fetchSensorData();
      setState(() {
        _sensorDataList = data;
        _sensorDataFuture = Future.value(data);
      });
      return data;
    } catch (e) {
      // Handle the error scenario
      setState(() {
        _sensorDataFuture = Future.value(_sensorDataList ?? []);
      });
      return _sensorDataList ?? [];
    }
  }

  Future<List<NutritionDataModel>> _fetchNutritionData() async {
    try {
      final data = await NutritionDataService().fetchSensorData();
      setState(() {
        _nutritionDataList = data;
        _nutritionDataFuture = Future.value(data);
      });
      return data;
    } catch (e) {
      // Handle the error scenario
      setState(() {
        _nutritionDataFuture = Future.value(_nutritionDataList ?? []);
      });
      return _nutritionDataList ?? [];
    }
  }
  void fetchData() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('lat & lon: ${position.latitude} ${position.longitude}');
    // Convert URL string to Uri object
    Uri url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,relative_humidity_2m&hourly=temperature_2m,relative_humidity_2m,weather_code');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        data = jsonDecode(response.body);
        hourlyTimes = data!['hourly']['time'].sublist(0, 24);
        hourlyCode = data!['hourly']['weather_code'].sublist(0, 24);
        hourlyTemperatures = data!['hourly']['temperature_2m'].sublist(0, 24);
        hourlyHumidities =
            data!['hourly']['relative_humidity_2m'].sublist(0, 24);
        timezone = data!['timezone'];



        // Determine the greeting and format the date and time
        DateTime currentTime = DateTime.parse(data!['current']['time']);
        int currentHour = currentTime.hour;
        if (currentHour < 12) {
          greeting = 'Good Morning';
        } else if (currentHour < 17) {
          greeting = 'Good Afternoon';
        } else {
          greeting = 'Good Evening';
        }

        // Formatted date
        formattedDate = DateFormat('EEEE d').format(currentTime);

        // Formatted time
        formattedTime = DateFormat('h:mm a').format(currentTime);
      });
    } else {
      // Handle error
      print('Error: ${response.statusCode}');
    }
  }
  @override
  void initState() {
    super.initState();
    _nutritionDataFuture = _fetchNutritionData();
    _sensorDataFuture = _fetchSensorData();
    _fetchWeather();
    fetchData();
    // Initialize motor status animation controller
    _motorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Spin duration
    );

    // Fetch motor status asynchronously and update state once available
    Irrigation().fetchMotorStatus().then((status) {
      setState(() {
        motorStatus = status;
        if (motorStatus == 'ON') {
          _motorController.repeat(); // Start spinning the motor icon if ON
        } else {
          _motorController.stop(); // Stop the motor icon if OFF
        }
      });
    });

    // Set up a timer to refresh sensor data every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (mounted) {
        _fetchSensorData();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageController2.dispose();
    _timer?.cancel(); // Cancel the timer
    _controller.dispose(); // Dispose of TextEditingController
    _focusNode.dispose(); // Dispose of FocusNode
    _motorController.dispose(); // Dispose of AnimationController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = EHelperFunctions.screenHeight(context);

    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor: Colors.green,
        // Green tone
        primary: true,

        appBar: EAppBar(
          title: Text(
            'Home',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          leadingIcon: Icons.keyboard_arrow_down_rounded,
          // Icon for the dropdown
          leadingIconColor: Colors.white,
          leadingIconSize: 30,
          leadingOnPressed: () {
            // Define dropdown behavior
            showMenu(
              color: Colors.white54,
              context: context,
              position: const RelativeRect.fromLTRB(0, 56.0, 0, 0),
              // Dropdown position
              items: [
                const PopupMenuItem(
                  value: 'Option 1',
                  child: Text('Field 1'),
                ),
                const PopupMenuItem(
                  value: 'Option 2',
                  child: Text('Field 2'),
                ),
                const PopupMenuItem(
                  value: 'Option 3',
                  child: Text('Field 3'),
                ),
              ],
            ).then((value) {});
          },
          precedingIcon: Icons.settings,
          precedingIconColor: Colors.white,
          precedingOnPressed: () {
            context.push('/settings');
          },
          precedingIcon1: Icons.shopping_cart,
          precedingIconColor1: Colors.white,
          precedingOnPressed1: () {
            context.push('/shopHome');
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            setState(() {
              _rotationAngle +=
                  1.0; // Rotates the icon by 360 degrees (1 full turn)
            });
            // Call _showModalBottomSheet with context
            _showModalBottomSheet(context);
          },
          backgroundColor: Colors.white, // Trigger rotation on press
          child: AnimatedRotation(
            turns: _rotationAngle, // Number of 360-degree turns
            duration: const Duration(seconds: 1), // Duration for the rotation
            child: const FaIcon(
              FontAwesomeIcons.hurricane,
              size: 40.0,
              color: Colors.green,
            ),
          ), // Button color
        ),
        body: NestedScrollView(
          floatHeaderSlivers: false,
          headerSliverBuilder: (_, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                pinned: true,
                floating: true,
                expandedHeight: screenHeight * 0.55,
                // Adjust the height as needed
                backgroundColor: Colors.green,
                // Green tone
                flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // Calculate the opacity based on the scroll position
                    var top = constraints.biggest.height;
                    var opacity = (top - 80) / 250; // Adjust for smooth fading

                    return FlexibleSpaceBar(
                      centerTitle: true,
                      title: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        // Ensures opacity stays between 0 and 1
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              // mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height:
                                      EHelperFunctions.screenHeight(context) *
                                          0.15,
                                ),
                                // const Icon(Icons.cloud,
                                //     color: Colors.blue, size: 40),
                                Center(
                                  child: _weather == null
                                      ? const SizedBox(
                                          child: Text(""),
                                        ) // Show loader if _weather is null
                                      : Text(
                                          _weather?.cityName ??
                                              "Loading city...",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                ),
                                Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    SizedBox(
                                        height: EHelperFunctions.screenHeight(
                                                context) *
                                            0.08,
                                        width: EHelperFunctions.screenHeight(
                                                context) *
                                            0.08,
                                        child: Lottie.asset(getWeatherAnimation(
                                            _weather?.mainCondition))),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 64),
                                      child: Column(
                                        children: [
                                          Center(
                                            child: _weather == null
                                                ? const SizedBox(
                                                    child: Text(""),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        '${_weather?.temperature.round()}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 44,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      const Text(
                                                        '°C',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20,
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                          Text(
                                            _weather?.mainCondition ?? "",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ];
          },
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // --Section 1--
                GestureDetector(
                  onLongPress: ()async{await _fetchNutritionData();},
                  child: ReusableContainer(
                    height: 280,
                    width: double.infinity,
                    child: FutureBuilder<List<SensorDataModel>>(
                      future: _sensorDataFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<SensorDataModel>> snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (snapshot.hasData) {
                          final sensorDataList = snapshot.data!;

                          // Compute daily averages from the list of sensor data
                          final averages = SensorDataModel.calculateDailyAverages(
                              sensorDataList);

                          return Padding(
                            padding: const EdgeInsets.all(ESizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Heading
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sensor Readings',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'More Details',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 10,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: ESizes.spaceBtwItems),
                                // Sensor & Values
                                SensorData(
                                  sensorIcon: Icons.water_drop,
                                  iconColor: Colors.white70,
                                  sensorName: "Soil Moisture",
                                  sensorActualValue: sensorDataList.isNotEmpty
                                      ? sensorDataList.last.soilMoisture
                                      : 0,
                                  sensorAvgValue:
                                      averages['avgSoilMoisture'] ?? 0,
                                ),
                                const SizedBox(height: ESizes.md),
                                SensorData(
                                  sensorIcon: Icons.thermostat,
                                  iconColor: Colors.white70,
                                  sensorName: "Temperature",
                                  sensorActualValue: sensorDataList.isNotEmpty
                                      ? sensorDataList.last.temperature
                                      : 0,
                                  sensorAvgValue: averages['avgTemperature'] ?? 0,
                                ),
                                const SizedBox(height: ESizes.md),
                                SensorData(
                                  sensorIcon: Icons.water_damage,
                                  iconColor: Colors.white70,
                                  sensorName: "Humidity",
                                  sensorActualValue: sensorDataList.isNotEmpty
                                      ? sensorDataList.last.humidity
                                      : 0,
                                  sensorAvgValue: averages['avgHumidity'] ?? 0,
                                ),
                                const SizedBox(height: ESizes.spaceBtwSections),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 55,
                                      width: 300,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.push('/analytics');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.white10,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text(
                                          'Analytics',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Center(child: CircularProgressIndicator(
                            color: Colors.black87,
                            backgroundColor: Colors.white54,
                          ));
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16), // Spacing between containers

                // --Section 2--
                SizedBox(
                  height: 130,
                  // Adjust height for scrollable content and indicator
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 3,
                          // Number of items (update this if you add more pages)
                          itemBuilder: (context, index) {
                            // Define your list of AnalysisBox data
                            const List<Widget> analysisBoxes = [
                              Analysis_box(
                                icon: Icons.water_drop,
                                title: 'Soil moisture looks like',
                                subTitle:
                                    'The soil moisture levels are optimal. No additional irrigation is required.',
                              ),
                              Analysis_box(
                                icon: Icons.thermostat,
                                title: 'Temperature looks like',
                                subTitle:
                                    'The field temperature is within the ideal range for crop growth.',
                              ),
                              Analysis_box(
                                icon: Icons.water_damage,
                                title: 'Humidity looks like',
                                subTitle:
                                    'The humidity levels are well-balanced, minimizing the risk of fungal diseases.',
                              ),
                              // Add more items as needed
                            ];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0), // Spacing between items
                              child: analysisBoxes[index],
                            );
                          },
                          physics: const BouncingScrollPhysics(),
                          // Adds a smooth scrolling effect
                          pageSnapping: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Page Indicator
                      SmoothPageIndicator(
                        controller: _pageController, // PageView controller
                        count: 3, // Number of pages
                        effect: const WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --Section 3--
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: (){
                            context.push('/weekScreen');
                          },
                          child: const Row(
                            children: [
                              Text(
                                'More Details',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                              SizedBox(
                                width: 3,
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: ESizes.sm,
                    ),
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(24, (index) {
                                return Row(
                                  children: [
                                    WeatherIcon(
                                      weatherCode: (hourlyCode != null && hourlyCode!.isNotEmpty)
                                          ? hourlyCode![index]
                                          : 0, // Default to 0 if not found
                                      time: '${index == 0 ? 12 : index > 12 ? index - 12 : index}:00 ${index < 12 ? 'AM' : 'PM'}',
                                      temp: (hourlyTemperatures != null && hourlyTemperatures!.isNotEmpty)
                                          ? hourlyTemperatures![index]
                                          : null, // Default temperature if not found
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 16), // Spacing between containers

                // --Section 4--
                Row(
                  children: [
                    // First Container
                    Expanded(
                      child: Column(
                        children: [
                          ReusableContainer(
                            height: 108,
                            width: double.infinity,
                            child: FutureBuilder<List<NutritionDataModel>>(
                              future: _nutritionDataFuture,
                              builder: (context,
                                  AsyncSnapshot<List<NutritionDataModel>>
                                      snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text('No data available'));
                                }
                                final data = snapshot.data!;
                                final fertilizerList = data
                                    .map((e) => e.last_fertilizer)
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                                final latestFertilizer =
                                    fertilizerList.isNotEmpty
                                        ? fertilizerList.join(', ')
                                        : 'N/A';
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      width: EHelperFunctions.screenWidth(
                                              context) *
                                          .01,
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Icon(
                                        //   Icons.recycling,
                                        //   size: 20,
                                        //   color: Colors.white54,
                                        // ),
                                        const Text(
                                          'Current\nfertilizer:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        // Text(
                                        //   'Fertilizer',
                                        //   style: TextStyle(
                                        //     fontSize: 7,
                                        //     fontWeight: FontWeight.bold,
                                        //     color: Colors.white54,
                                        //   ),
                                        // ),
                                        const SizedBox(
                                          height:
                                              8, // Replace with `ESizes.sm` if `ESizes.sm` is defined elsewhere in your code
                                        ),
                                        Text(
                                          latestFertilizer,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: EHelperFunctions.screenWidth(
                                              context) *
                                          .01,
                                    ),
                                    const VerticalDivider(
                                      color: Colors.white54,
                                      endIndent: 15,
                                      indent: 15,
                                    ),
                                    // SizedBox(width: EHelperFunctions.screenWidth(context)*.01,),
                                    TextButton(
                                      onPressed: () {
                                        showPredictionBottomSheet(context);
                                      },
                                      child: const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.speed_sharp,
                                              color: Colors.white54, size: 50),
                                          SizedBox(height: 4),
                                          // Adds some space between the icon and the text
                                          Text(
                                            'Optimize',
                                            style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            height: ESizes.sm,
                          ),
                          const ReusableContainer(
                            height: 108,
                            width: double.infinity,
                            // Set width to infinity to fill the available space
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.pin_drop,
                                      color: Colors.white54,
                                    ),
                                    SizedBox(
                                      width: 1,
                                    ),
                                    Text(
                                      'Field Location',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white54),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ESizes.sm,
                                ),
                                Text(
                                  'V.M Chatram',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                        width: ESizes.sm), // Slight gap between the containers

                    // Second Container
                    Expanded(
                      child: ReusableContainer(
                        height: 224,
                        width: double.infinity,
                        child: FutureBuilder<List<NutritionDataModel>>(
                          future: _nutritionDataFuture,
                          builder: (context,
                              AsyncSnapshot<List<NutritionDataModel>>
                                  snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const Center(child: Text('No data available'));
                            }

                            final data = snapshot.data!;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.equalizer_outlined,
                                      color: Colors.white54,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Soil Nutrition',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Assuming you want to display the average values
                                if (data.isNotEmpty) ...[
                                  NPK(
                                      nutrient: 'Nitrogen',
                                      value: data
                                              .map((e) => e.nitrogen)
                                              .reduce((a, b) => a + b) /
                                          data.length.toInt()),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),
                                  NPK(
                                      nutrient: 'Phosphorous',
                                      value: data
                                              .map((e) => e.phosphorus)
                                              .reduce((a, b) => a + b) /
                                          data.length.toInt()),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),
                                  NPK(
                                      nutrient: 'Potassium',
                                      value: data
                                              .map((e) => e.potassium)
                                              .reduce((a, b) => a + b) /
                                          data.length.toInt()),
                                  const Divider(color: Colors.white24),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                // --Section 5--
                ReusableContainer(
                    height: 100,
                    width: 75,
                    child: Row(
                      children: [
                        const Text("Motor Control", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600, fontSize: 20),),
                        const Spacer(),
                        RotationTransition(
                          turns: _motorController, // Apply rotation to the icon
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
                            child: IconButton(
                              onPressed: () async{
                                if(motorStatus == 'ON'){
                                  await Irrigation().updateMotorStatusOFF();
                                  setState(() {
                                    motorStatus = 'OFF';
                                  });
                                }
                                else{
                                  await Irrigation().updateMotorStatusON();
                                  setState(() {
                                    motorStatus = 'ON';
                                  });
                                }
                              },
                              icon: FaIcon(
                                FontAwesomeIcons.fan,
                                size: 45,
                                color: motorStatus == 'ON' ? const Color(0xFF70BE92): Colors.red, // Change color based on motor status
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                ),
                const SizedBox(
                  height: 8,
                ),
                // --Section 6--
                SizedBox(
                  height: 130,
                  // Adjust height for scrollable content and indicator
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController2,
                          itemCount: 3,
                          // Number of items (update this if you add more pages)
                          itemBuilder: (context, index) {
                            // Define your list of AnalysisBox data
                            const List<Widget> analysisBoxes = [
                              Analysis_box(
                                icon: Icons.query_stats_rounded,
                                title: 'Nitrogen Analysis',
                                subTitle:
                                    'The nitrogen levels are optimal, promoting healthy leaf and stem growth.',
                              ),
                              Analysis_box(
                                icon: Icons.query_stats_rounded,
                                title: 'Phosphorous Analysis',
                                subTitle:
                                    'Phosphorus levels are sufficient, supporting strong root development.',
                              ),
                              Analysis_box(
                                icon: Icons.query_stats_rounded,
                                title: 'Potassium Analysis',
                                subTitle:
                                    'The potassium levels are balanced, enhancing disease resistance.',
                              ),
                              // Add more items as needed
                            ];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0), // Spacing between items
                              child: analysisBoxes[index],
                            );
                          },
                          physics: const BouncingScrollPhysics(),
                          // Adds smooth scrolling effect
                          pageSnapping: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Page Indicator
                      SmoothPageIndicator(
                        controller: _pageController2, // PageView controller
                        count: 3, // Number of pages
                        effect: const WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                // ElevatedButton(
                //     onPressed: () async {
                //       await Irrigation().fetchMotorStatus();
                //     },
                //     child: Text(
                //       'Check Status',
                //       style: TextStyle(color: Colors.white54),
                //     ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showPredictionBottomSheet(BuildContext context) {
    final MlApi mlApi = MlApi();
    bool isLoading = true; // Track loading state
    Map<String, dynamic> predictionData = {}; // Initialize with an empty map

    // Show the bottom sheet immediately with a shimmer effect
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      // Optional: use this to have a transparent background
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            // Function to update the state
            void updateContent(Map<String, dynamic> newData, bool loading) {
              setState(() {
                predictionData = newData; // Update the prediction data
                isLoading = loading; // Update the loading state
              });
            }

            // Fetch the prediction data asynchronously
            Future<void> fetchData() async {
              try {
                await MlApi().trainMl();
                final data = await mlApi.mlPredict();
                updateContent(data, false); // Update with fetched data
              } catch (error) {
                // Handle the error
                updateContent({
                  'Fertilizer': 'Error fetching data',
                  'NPK_values_needed': [],
                }, true);
              }
            }

            // Start fetching data
            fetchData();

            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.green, // Adjust color as needed
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediction Results',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    isLoading
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    width: 150,
                                    height: 20,
                                    color: Colors.white54),
                                const SizedBox(height: 8),
                                Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: Colors.white54),
                                const SizedBox(height: 8),
                                Container(
                                    width: double.infinity,
                                    height: 20,
                                    color: Colors.white54),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fertilizer: ${predictionData['Fertilizer'] ?? 'N/A'}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'NPK Values Needed:',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              ...((predictionData['NPK_values_needed'] ?? [])
                                      as List<List<dynamic>>)
                                  .map<Widget>((values) {
                                return Text(
                                  'N: ${values[0]}, P: ${values[1]}, K: ${values[2]}',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                );
                              }),
                            ],
                          ),
                    const SizedBox(height: 16),
                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                        },
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _responseBuilt = false;

  void _showModalBottomSheet(BuildContext context) {
    Future.delayed(const Duration(seconds: 1), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Watsonxai ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '- $_selectedLanguage',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 125,
                      child: ListView(
                        children: [
                          if (!_responseBuilt)
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Hi, How can I help you?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          _buildResponseSection(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.g_translate, color: Colors.white54),
                          onPressed: () {
                            _showLanguageBottomSheet(
                                context); // Open language selection
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Type your question...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(
                                  color: Colors.white54,
                                  width: 2.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                                borderSide: const BorderSide(
                                  color: Colors.white54,
                                  width: 2.0,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 20.0),
                            ),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            _submitQuestion(
                              "the language you should respond(it doesn't mean translation):$_selectedLanguage\n question: ${_controller.text}",
                            );
                            setState(() {
                              _responseBuilt =
                                  true; // Set to true when the question is submitted
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            color: Colors.green,
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _buildLanguageChip('English'),
                  _buildLanguageChip('Tamil'),
                  _buildLanguageChip('Malayalam'),
                  _buildLanguageChip('Telugu'),
                  _buildLanguageChip('Hindi'),
                  _buildLanguageChip('Kannada'),
                  _buildLanguageChip('Bengali'),
                  _buildLanguageChip('Marathi'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageChip(String language) {
    bool isSelected =
        _selectedLanguage == language; // Check if the chip is selected

    return ChoiceChip(
      selectedColor: Colors.greenAccent,
      label: Text(
        language,
        style: TextStyle(color: isSelected ? Colors.black : Colors.white54),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedLanguage =
                language; // Update to the newly selected language
          });
          // Close the language selection bottom sheet
          context.pop();
          context.pop();
          // Optionally, call _showModalBottomSheet to refresh the main bottom sheet
          _showModalBottomSheet(context);
        }
      },
    );
  }

  Widget _buildResponseSection() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20.0,
                width: 150.0, // Adjust width as needed
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8.0),
              Container(
                height: 20.0,
                width: 200.0, // Adjust width as needed
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8.0),
              Container(
                height: 20.0,
                width: 180.0, // Adjust width as needed
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      );
    } else if (_response.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: MarkdownBody(
          data: _response,
          styleSheet: MarkdownStyleSheet(
            h2: const TextStyle(fontSize: 20, color: Colors.white54),
            p: const TextStyle(fontSize: 16, color: Colors.white),
            strong: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Future<void> _submitQuestion(String question) async {
    if (question.isEmpty) return; // Ensure the question isn't empty

    setState(() {
      _isLoading = true;
      _response = '';
    });

    // Simulate an API request (replace with your actual API call)
    final response = await Gemini().makeApiRequestIBM(question);

    setState(() {
      _isLoading = false;
      _response = response;
    });

    _controller.clear();
    _focusNode.unfocus();
  }
}
