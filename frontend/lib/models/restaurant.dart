class Restaurant {
  final int id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String description;
  final double rating;
  final int priceRange;
  final int slotDuration;

  Restaurant({
    this.id = 0,
    this.name = "",
    this.address = "",
    this.city = "",
    this.phone = "",
    this.description = "",
    this.rating = 0.0,
    this.priceRange = 0,
    this.slotDuration = 0
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        city: json['city'],
        phone: json['phone'],
        description: json['description'],
        rating: json['rating'],
        priceRange: json['price_range'],
        slotDuration: json['slot_duration'],
    );
  }
}