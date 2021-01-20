class Temps {

  String name;
  String main;
  String description;
  String icon;
  var temp;
  var pressure;
  var humidity;
  var tempMin;
  var tempMax;

  Temps();

  void fromJSON(Map map) {
    this.name = map["name"];

    List weather = map["weather"];
    Map mapWeather = weather[0];
    this.main = mapWeather["main"];
    this.description = mapWeather["description"];
    String monIcone = mapWeather["icon"];
    this.icon = "assets/${monIcone.replaceAll("d", "").replaceAll("n", "")}.png";

    Map main = map["main"];
    this.temp = main["temp"];
    this.pressure = main["pressure"];
    this.humidity = main["humidity"];
    this.tempMin = main["temp_min"];
    this.tempMax = main["temp_max"];
  }
}