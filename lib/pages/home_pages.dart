import 'package:flutter/material.dart';
import 'package:google_map_hakas_version/models/place.dart';
import 'package:google_map_hakas_version/pages/map_pages.dart';

import 'package:flutter/services.dart' as rootBundle; // For loading assets

import 'package:google_map_hakas_version/models/place.dart';
import 'dart:convert';

class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages> {
  late Future<List<Place>> futurePlaces;
  // Function to load and parse the JSON from assets
  Future<List<Place>> loadJsonData() async {
    // Load the json file as a string
    final jsonString =
        await rootBundle.rootBundle.loadString('assets/data/masjid.json');

    // Decode the string into a List
    List<dynamic> jsonResponse = jsonDecode(jsonString);
    // Convert the List to a List of Place objects
    return jsonResponse.map((data) => Place.fromJson(data)).toList();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    futurePlaces = loadJsonData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Container(
              margin: EdgeInsets.only(left: 0),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(7),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          image: DecorationImage(
                              image: AssetImage("assets/images/me.png"),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Text(
                          "HazimDev",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        "Terengganu, Malaysia",
                        style: TextStyle(fontSize: 13),
                      )
                    ],
                  ),
                ],
              )),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 15),
              child: Icon(Icons.notifications_none),
            )
          ],
        ),
        body: Column(
          children: [
               Column(
              children: [
                Container(
                  child: Text("Tracking Water Access in Rural Area",style: TextStyle(fontSize: 15),),
                )
              ],
            ),
            
            Expanded(
              child: FutureBuilder<List<Place>>(
                future: futurePlaces,
                builder: (context, snapshot) {
                  ShrinkWrappingViewport;
                  if (snapshot.hasData) {
                    List<Place>? places = snapshot.data;
                    return ListView.builder(
                        shrinkWrap: true,
                        itemCount: places!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            width: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.black, width: 1)),
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                ),
                                Expanded(
                                    child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(places[index].placeName),
                                  ],
                                )),
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => MapPages(
                                                    placeName:
                                                        places[index].placeName,
                                                    latitude:
                                                        places[index].latitude,
                                                    longitude:
                                                        places[index].longitude,
                                                  )));
                                    },
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      size: 20,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          );
                        });
                  }
                  return CircularProgressIndicator();
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2))]),
          child: BottomNavigationBar(
              selectedItemColor: Colors.blue,
              backgroundColor: Colors.white,
              elevation: 0,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat), label: 'Chatbot'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.logout_rounded), label: 'Logout')
              ]),
        ));
  }
}
