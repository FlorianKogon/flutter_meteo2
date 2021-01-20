import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'dart:io';

Future main() async {
  await DotEnv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Meteo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String key = 'cities';

  List<String> cities = [];

  String chosenCity = '';

  Location location = Location();
  LocationData locationData;
  Stream<LocationData> streamData;

  Coordinates coordinatesChosenCity;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getSharedPreferences();
    //getFirstLocation();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.blue,
          child: ListView.builder(
              itemCount: cities.length + 2,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return DrawerHeader(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        customText("Mes villes", fontSize: 22.0),
                        RaisedButton(
                          elevation: 5.0,
                          onPressed: addCity,
                          color: Colors.teal,
                          child: customText('Ajouter une ville'),
                        ),
                      ],
                    ),
                  );
                }
                else if (i == 1) {
                  return ListTile(
                    title: customText("Ma ville actuelle"),
                    onTap: () {
                      setState(() {
                        chosenCity = null;
                        coordinatesChosenCity = null;
                        Navigator.pop(context);
                      });
                    },
                  );
                }
                else {
                  String city = cities[i - 2];
                  return ListTile(
                    title: customText(city),
                    onTap: () {
                      setState(() {
                        chosenCity = city;
                        getCoordFromAdress();
                        Navigator.pop(context);
                      });
                    },
                    trailing: FlatButton(
                      onPressed: () => {
                        deleteSharedPreferences(city)
                      },
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                  );
                }
              }),
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: customText(
            chosenCity == null ? "Ville actuelle" : chosenCity,
            color: Colors.black87
        ),
      ),
    );
  }


  //Custom Methods
  Text customText(String data, {color: Colors.white, fontSize: 17.0, fontStyle: FontStyle.italic, textAlign: TextAlign.center} ) {
    return Text(
      data,
      textAlign: textAlign,
      style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontStyle: fontStyle
      ),
    );
  }

  //Call API
  callApi() async {
    double lat;
    double lon;
    if (coordinatesChosenCity != null) {
      lat = coordinatesChosenCity.latitude;
      lon = coordinatesChosenCity.longitude;
    } else if (locationData != null) {
      lat = locationData.latitude;
      lon = locationData.longitude;
    }
    if (lat != null && lon != null) {
      final key = '&appid=${DotEnv.env['API_KEY']}';
      String language = '&lang=${Localizations.localeOf(context).languageCode}';
      String baseApi = 'api.openweathermap.org/data/2.5/weather?';
      String coordsQuery = 'lat=$lat&lon=$lon';
      String units = "&units=metrics";
      String totalQuery = baseApi + coordsQuery + units + language + key;
      final response = await http.get(totalQuery);
      if (response.statusCode == 200) {
        print(response.body);
      }
    }
  }

  Future<Null> addCity() async {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext buildContext) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(20.0),
            title: customText("Ajouter une ville", fontSize: 22.0, color: Colors.teal),
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                    labelText: "Nouvelle ville"
                ),
                onSubmitted: (String str) {
                  saveSharedPreferences(str);
                  Navigator.pop(buildContext);
                },
              )
            ],
          );
        }
    );
  }

  //SHARED PREFERENCES

  void getSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> list = await sharedPreferences.getStringList(key);
    if (list != null) {
      setState(() {
        cities = list;
      });
    }
  }

  void saveSharedPreferences(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    cities.add(str);
    await sharedPreferences.setStringList(key, cities);
    getSharedPreferences();
  }

  void deleteSharedPreferences(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    cities.remove(str);
    await sharedPreferences.setStringList(key, cities);
    getSharedPreferences();
  }

  //LOCATION

  getFirstLocation() async {
    try {
      locationData = await location.getLocation();
      print(locationData.latitude);
      print(locationData.longitude);
    } catch (e) {
      print("Error $e");
    }
  }

  getCurrentLocation() {
    streamData = location.onLocationChanged;
    streamData.listen((event) {
      if ((locationData != null) || ((locationData.latitude != event.latitude) && (locationData.longitude != event.longitude))) {
        print("Nouvelle position : ${event.longitude} / ${event.latitude}");
        setState(() {
          locationData = event;
          getAdressFromCoord();
        });
      }
    });
  }

  //GEOCODER

  getAdressFromCoord() async {
    if (locationData != null) {
      Coordinates coordinates = Coordinates(locationData.latitude, locationData.longitude);
      final cityName = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      setState(() {
        chosenCity = cityName.first.locality;
        callApi();
      });
    }
  }

  getCoordFromAdress() async {
    if (chosenCity != null) {
      List<Address> addresses = await Geocoder.local.findAddressesFromQuery(chosenCity);
      if (addresses.length > 0) {
        Address first = addresses.first;
        Coordinates coordinates = first.coordinates;
        setState(() {
          coordinatesChosenCity = coordinates;
          callApi();
        });
      }
    }
  }
}
