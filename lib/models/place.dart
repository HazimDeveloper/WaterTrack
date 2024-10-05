class Place {
  final int index;
  final String placeName;
  final String address1;
  final String hours;
  final int phone;
  final String location;
  final int reviewCount;
  final double totalScore;
  final String website;
  final String category;
  final String claimed;
  final double latitude;
  final double longitude;
  final String placeId;
  final String cid;
  final String featuredImage;
  final String reviewUrl;

  Place({
    required this.index,
    required this.placeName,
    required this.address1,
    required this.hours,
    required this.phone,
    required this.location,
    required this.reviewCount,
    required this.totalScore,
    required this.website,
    required this.category,
    required this.claimed,
    required this.latitude,
    required this.longitude,
    required this.placeId,
    required this.cid,
    required this.featuredImage,
    required this.reviewUrl,
  });

  // Factory constructor to create a Place object from a JSON map
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      index: json['index'] ?? 0,
      placeName: json['Place_name'] ?? '',
      address1: json['Address1'] ?? '',
      hours: json['Hours'] ?? '',
      phone: json['Phone'] ?? 0,
      location: json['Location'] ?? '',
      reviewCount: json['Reviewscount'] ?? 0,
      totalScore: (json['Total_score'] ?? 0).toDouble(),
      website: json['website'] ?? '',  // Handle possible null values
      category: json['Category'] ?? '',
      claimed: json['Claimed'] ?? '',
      latitude: (json['Latitude'] ?? 0).toDouble(),
      longitude: (json['Longitude'] ?? 0).toDouble(),
      placeId: json['Place_id'] ?? '',
      cid: json['Cid'] ?? '',
      featuredImage: json['Featured_Image'] ?? '',
      reviewUrl: json['reviewurl'] ?? '',
    );
  }
}
