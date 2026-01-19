class Product {
  String id;
  String name;
  String category;

  String description;
  String imageUrl;
  double price;
  String warrantyPeriod;
  String shopId;
  String shopName;
  String shopLocation;

  String offers;



  Product({
    required this.id,
    required this.name,
    required this.category,

    required this.description,
    required this.imageUrl,
    required this.price,
    required this.warrantyPeriod,
    required this.shopId,
    required this.shopName,
    required this.shopLocation,
    required this.offers,

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,

      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'warrantyPeriod': warrantyPeriod,
      'shopId': shopId,
      'shopName': shopName,
      'shopLocation': shopLocation,
      'offers': offers,

    };
  }
}
//offers: offersController.text,