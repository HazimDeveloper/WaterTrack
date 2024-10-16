import 'package:flutter/material.dart';
import 'package:google_map_hakas_version/models/place.dart';
import 'package:google_map_hakas_version/pages/map_pages.dart';

import 'package:flutter/services.dart' as rootBundle; // For loading assets
import 'dart:convert';  
import 'package:google_map_hakas_version/models/place.dart';

import 'package:google_map_hakas_version/widget/custom_navigation_bar.dart';
import 'package:google_map_hakas_version/widget/modern_list_item.dart';

class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages> {
  late int _selectedIndex = 1;
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
              margin: const EdgeInsets.only(left: 0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          image: const DecorationImage(
                              image: AssetImage("assets/images/me.png"),
                              fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 30),
                        child: const Text(
                          "HazimDev",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Text(
                        "Terengganu, Malaysia",
                        style: TextStyle(fontSize: 13),
                      )
                    ],
                  ),
                ],
              )),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 15),
              child: const Icon(Icons.notifications_none),
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: const Text(
                    "Recent Areas",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
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
                    return Expanded(
                      child: FutureBuilder<List<Place>>(
                        future: futurePlaces,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            List<Place>? places = snapshot.data;
                            return ListView.builder(
                              itemCount: places!.length,
                              itemBuilder: (context, index) {
                                return ModernListItem(
                                  placeName: places[index].placeName,
                                  criticalLevel:
                                      "28%", // Replace with actual data if available
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MapPages(
                                          placeName: places[index].placeName,
                                          latitude: places[index].latitude,
                                          longitude: places[index].longitude,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Handle navigation here
          },
        ));
  }
}
