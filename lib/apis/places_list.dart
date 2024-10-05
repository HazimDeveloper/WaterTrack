import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as rootBundle; // For loading assets

import 'package:google_map_hakas_version/models/place.dart'; // Import your Place model

class PlacesList extends StatefulWidget {
  @override
  _PlacesListState createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  late Future<List<Place>> futurePlaces;

  // Function to load and parse the JSON from assets
  Future<List<Place>> loadJsonData() async {
    // Load the json file as a string
    final jsonString = await rootBundle.rootBundle.loadString('assets/data/masjid.json');
    
    // Decode the string into a List
    List<dynamic> jsonResponse = jsonDecode(jsonString);
    print(jsonResponse);
    // Convert the List to a List of Place objects
    return jsonResponse.map((data) => Place.fromJson(data)).toList();
  }

  @override
  void initState() {
    super.initState();
    futurePlaces = loadJsonData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Places List'),
      ),
      body: FutureBuilder<List<Place>>(
        future: futurePlaces,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Place>? places = snapshot.data;
            return ListView.builder(
              itemCount: places!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(places[index].placeName),
                  subtitle: Text(places[index].address1),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
