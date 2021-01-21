import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'dart:convert';
import 'widgets/temps.dart';
import 'widgets/my_flutter_app_icons.dart';

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
  String currentCity = 'Ville actuelle';

  Location location = Location();
  LocationData locationData;
  Stream<LocationData> streamData;

  Coordinates coordinatesChosenCity;

  Temps temps;

  AssetImage night = AssetImage("assets/n.jpg");
  AssetImage sun = AssetImage("assets/d1.jpg");
  AssetImage rain = AssetImage("assets/d2.jpg");

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
                    title: customText(currentCity),
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
      body: (temps == null)
          ? Center(child: Text((chosenCity == null)? currentCity : chosenCity))
          : Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            image: DecorationImage(image : getBackground(), fit: BoxFit.cover)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            customText((chosenCity == null)? currentCity : chosenCity, fontSize: 40.0),
            customText(temps.description, fontSize: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Image(image: getIcon()),
                customText("${temps.temp.toInt()} °C", fontSize: 50.0)
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                extra("${temps.tempMin.toInt()} °C", MyFlutterApp.temperature),
                extra("${temps.tempMax.toInt()} °C", MyFlutterApp.droplet),
                extra("${temps.pressure.toInt()} hPa", MyFlutterApp.arrow_downward),
                extra("${temps.humidity.toInt()} %", MyFlutterApp.arrow_upward),
              ],
            )
          ],
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

  Column extra(String data, IconData iconData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Icon(iconData, color: Colors.white, size: 32.0),
        customText(data),
      ],
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
      String units = "&units=metric";
      String totalQuery = 'http://' + baseApi + coordsQuery + units + language + key;
      final response = await http.get(totalQuery);
      if (response.statusCode == 200) {
        Map map = jsonDecode(response.body);
        setState(() {
          temps = Temps();
          temps.fromJSON(map);
        });
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

  AssetImage getBackground() {
    if (temps.icon.contains("n")) {
      return night;
    } else {
      if (temps.icon.contains("01") || temps.icon.contains("02") || temps.icon.contains("03")) {
        return sun;
      } else {
        return rain;
      }
    }
  }

  AssetImage getIcon() {
    String icon = temps.icon.replaceAll("d", "").replaceAll("n", "");
    return AssetImage("$icon.png");
  }

}
