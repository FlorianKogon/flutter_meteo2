import 'package:flutter/material.dart';


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> cities = ['Paris', 'Bordeaux', 'Marseille'];

  String chosenCity = '';

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
                        Navigator.pop(context);
                      });
                    },
                    trailing: FlatButton(
                      onPressed: () => {
                        cities.removeAt(i)
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

  Future<Null> addCity() async {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(20.0),
            title: customText("Ajouter une ville", fontSize: 22.0, color: Colors.teal),
            children: [
              TextField(
                decoration: InputDecoration(
                    labelText: "Nouvelle ville"
                ),
                onSubmitted: (String str) {
                  Navigator.pop(context);
                  setState(() {
                    cities.add(str);
                  });
                },
              )
            ],
          );
        }
    );
  }
}
