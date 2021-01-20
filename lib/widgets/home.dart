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
              itemCount: cities.length,
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(
                      cities[i],
                      style: TextStyle(color: Colors.white)
                  ),
                  onTap: () {
                    setState(() {
                      chosenCity = cities[i];
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
              }),
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Text(chosenCity == null ? "Ville actuelle" : chosenCity
        ),
      ),
    );
  }
}
