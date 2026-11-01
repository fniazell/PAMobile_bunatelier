class ProductItem {
  final String id;
  final String name;
  final String category; // 'burger', 'croissant', 'sides', 'drinks', 'desserts'
  final String description;
  final String ingredients;
  final int price;
  final String imageUrl;
  final bool isSpicy;
  final bool isBestSeller;
  final bool isAvailable;
  final int stock;
  final int minStock;
  final bool isChefsPick;

  const ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.imageUrl,
    this.isSpicy = false,
    this.isBestSeller = false,
    this.isAvailable = true,
    this.stock = 30,
    this.minStock = 5,
    this.isChefsPick = false,
  });

  bool get isOutOfStock => stock <= 0 || !isAvailable;
  bool get isLowStock => stock > 0 && stock <= minStock;

  ProductItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? ingredients,
    int? price,
    String? imageUrl,
    bool? isSpicy,
    bool? isBestSeller,
    bool? isAvailable,
    int? stock,
    int? minStock,
    bool? isChefsPick,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isSpicy: isSpicy ?? this.isSpicy,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      isChefsPick: isChefsPick ?? this.isChefsPick,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'ingredients': ingredients,
      'price': price,
      'imageUrl': imageUrl,
      'isSpicy': isSpicy ? 1 : 0,
      'isBestSeller': isBestSeller ? 1 : 0,
      'isAvailable': isAvailable ? 1 : 0,
      'stock': stock,
      'minStock': minStock,
      'isChefsPick': isChefsPick ? 1 : 0,
    };
  }

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'burger',
      description: map['description']?.toString() ?? '',
      ingredients: map['ingredients']?.toString() ?? '',
      price: (map['price'] as int?) ?? 0,
      imageUrl: map['imageUrl']?.toString() ?? '',
      isSpicy: map['isSpicy'] == 1 || map['isSpicy'] == true,
      isBestSeller: map['isBestSeller'] == 1 || map['isBestSeller'] == true,
      isAvailable: map['isAvailable'] == 1 || map['isAvailable'] == true || map['isAvailable'] == null,
      stock: (map['stock'] as int?) ?? 30,
      minStock: (map['minStock'] as int?) ?? 5,
      isChefsPick: map['isChefsPick'] == 1 || map['isChefsPick'] == true,
    );
  }
}

class ProductAddonItem {
  final String id;
  final String name;
  final int price;
  final bool isSauce;

  const ProductAddonItem({
    required this.id,
    required this.name,
    required this.price,
    this.isSauce = false,
  });
}

class CatalogData {
  static const List<ProductAddonItem> sauces = [
    ProductAddonItem(id: 's-1', name: 'Truffle Aioli Mayo', price: 8000, isSauce: true),
    ProductAddonItem(id: 's-2', name: 'Spicy Sriracha Glaze', price: 7000, isSauce: true),
    ProductAddonItem(id: 's-3', name: 'Smoky Texas BBQ', price: 7000, isSauce: true),
    ProductAddonItem(id: 's-4', name: 'Roasted Garlic Herb Butter', price: 8000, isSauce: true),
    ProductAddonItem(id: 's-5', name: 'Tangy Honey Mustard', price: 6000, isSauce: true),
    ProductAddonItem(id: 's-6', name: 'Melted Cheddar Cheese Sauce', price: 9000, isSauce: true),
  ];

  static const List<ProductAddonItem> addons = [
    ProductAddonItem(id: 'a-1', name: 'Double Australian Beef Patty', price: 25000),
    ProductAddonItem(id: 'a-2', name: 'Extra Melted Red Cheddar', price: 10000),
    ProductAddonItem(id: 'a-3', name: 'Crispy Beef Bacon Strip', price: 12000),
    ProductAddonItem(id: 'a-4', name: 'Caramelized Balsamic Onions', price: 7000),
    ProductAddonItem(id: 'a-5', name: 'Pickled Spiced Jalapeños', price: 6000),
    ProductAddonItem(id: 'a-6', name: 'Sunny-Side Up Omega Egg', price: 8000),
    ProductAddonItem(id: 'a-7', name: 'Sautéed Butter Shiitake', price: 11000),
    ProductAddonItem(id: 'a-8', name: 'Crispy Golden Hashbrown Layer', price: 10000),
  ];

  static const List<ProductItem> allProducts = [
    // 13 Burgers
    ProductItem(
      id: 'b-01',
      name: 'OG Main Character',
      category: 'burger',
      description: 'The burger that started the revolution. Juicy smashed Australian beef patty, double American cheddar, secret atelier sauce on toasted brioche.',
      ingredients: 'Toasted Brioche, 150g Angus Smash Patty, Double Red Cheddar, House Pickle, Atelier Relish Sauce',
      price: 65000,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'b-02',
      name: 'Hot Mess Express',
      category: 'burger',
      description: 'Gloriously unapologetic mess. Dripping spicy habanero glaze, pepper jack cheese, crispy fried onion strings, and ghost pepper mayo.',
      ingredients: 'Charred Brioche, Beef Patty, Pepper Jack, Crispy Fried Onions, Fresh Habanero Jam, Ghost Pepper Mayo',
      price: 72000,
      imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80',
      isSpicy: true,
      isBestSeller: true,
    ),
    ProductItem(
      id: 'b-03',
      name: 'Smash Hit',
      category: 'burger',
      description: 'Lacy, crispy-edged double smash patties loaded with molten caramelized onions, smoky dijonnaise, and sweet dill relish.',
      ingredients: 'Potato Bun, Double 90g Smashed Beef, Caramelized Sweet Onions, American Cheese, Dijonnaise',
      price: 68000,
      imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-04',
      name: 'Crunch Culture',
      category: 'burger',
      description: 'Ultimate crunch sensation featuring buttermilk fried chicken breast, red cabbage apple slaw, and spicy honey sriracha drizzle.',
      ingredients: 'Sesame Bun, 24h Brined Buttermilk Chicken Thigh, Red Slaw, Pickled Cucumber, Hot Honey Butter',
      price: 59000,
      imageUrl: 'https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'b-05',
      name: 'No Cap Cheddar',
      category: 'burger',
      description: 'For genuine cheese fiends. Triple cheddar melt, crispy parmesan tuile, and a bowl of warm cheese lava to pour over.',
      ingredients: 'Brioche Bun, Smashed Patty, Triple Aged Cheddar, Parmesan Crisp, Warm Cheddar Lava Bath',
      price: 76000,
      imageUrl: 'https://images.unsplash.com/photo-1572802419224-296b0aeee0d9?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-06',
      name: 'Slay Bacon',
      category: 'burger',
      description: 'Stack of glazed maple beef bacon strips, smoked scamorza cheese, garlic confit spread, and prime beef patty.',
      ingredients: 'Toasted Potato Bun, Smoked Scamorza, 4x Maple Beef Bacon Strips, Roasted Garlic Confit Aioli',
      price: 79000,
      imageUrl: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'b-07',
      name: 'Big Rizz',
      category: 'burger',
      description: 'Pure charismatic flavor. 200g prime wagyu blend patty, truffle glazed portobello mushroom, and melted gruyere cheese.',
      ingredients: 'Black Sesame Brioche, Wagyu Blend Patty, Melted Swiss Gruyere, Sautéed Portobello, Black Truffle Emulsion',
      price: 88000,
      imageUrl: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-08',
      name: 'Lowkey Spicy',
      category: 'burger',
      description: 'Just the right kick without overwhelming your taste buds. Smoked jalapeño relish, chipotle crema, and pepper jack.',
      ingredients: 'Brioche Bun, Australian Beef Patty, Chipotle Crema, Charred Green Jalapeño Relish, Jack Cheese',
      price: 64000,
      imageUrl: 'assets/images/lowkey_spicy.png',
      isSpicy: true,
    ),
    ProductItem(
      id: 'b-09',
      name: 'Glow Up Garlic',
      category: 'burger',
      description: 'Black garlic aioli, roasted garlic puree, crispy fried garlic chips, and melted provolone over prime beef.',
      ingredients: 'Milk Bun, Beef Patty, Crispy Garlic Chips, Black Garlic Aioli, Melted Provolone, Fresh Arugula',
      price: 67000,
      imageUrl: 'https://images.unsplash.com/photo-1549611016-3a70d82b5040?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-10',
      name: 'Vibe Check',
      category: 'burger',
      description: 'Sweet and savory fusion featuring grilled pineapple glazed in spiced brown sugar, teriyaki glaze, and creamy slaw.',
      ingredients: 'Brioche Bun, Smashed Patty, Grilled Spiced Pineapple, Teriyaki Reduction, Sesame Scallion Slaw',
      price: 62000,
      imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-11',
      name: 'Side Quest',
      category: 'burger',
      description: 'An unexpected journey of deep umami: pulled slow-cooked beef brisket on top of smashed patty with pickled mustard seeds.',
      ingredients: 'Toasted Bun, Smashed Beef Patty, 12-Hour Smoked Pulled Brisket, Pickled Mustard Seed Relish',
      price: 82000,
      imageUrl: 'https://images.unsplash.com/photo-1722076461141-d00f96fca0f4?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-12',
      name: 'Touch Grass',
      category: 'burger',
      description: 'Our premium plant-based champion. Spiced mushroom-lentil patty, smashed avocado, vine tomato, and green goddess herb dressing.',
      ingredients: 'Oat Bun, House Lentil-Mushroom Patty, Ripe Avocado Smash, Heirloom Tomato, Green Goddess Herb Mayo',
      price: 58000,
      imageUrl: 'https://images.unsplash.com/photo-1520072959219-c595dc870360?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'b-13',
      name: 'Delulu Deluxe',
      category: 'burger',
      description: 'So over-the-top it feels unreal: double wagyu patty, crispy beef bacon, fried mac n cheese bite, and liquid gold cheese fountain.',
      ingredients: 'Gold-Dusted Brioche, Double Wagyu, Deep Fried Mac Bite, Beef Bacon, Triple Cheese Fountain Sauce',
      price: 95000,
      imageUrl: 'https://images.unsplash.com/photo-1607013251379-e6eecfffe234?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),

    // 4 Croissant Burgers
    ProductItem(
      id: 'c-01',
      name: 'Truffle Wagyu Croissant Smash',
      category: 'croissant',
      description: 'Laminated French butter croissant bun, juicy smashed beef patty, truffle soft scramble, and melted French emmental cheese.',
      ingredients: 'Hand-rolled Butter Croissant, Smashed Angus Patty, Truffle Soft Scramble, French Emmental',
      price: 74000,
      imageUrl: 'assets/images/truffle_wagyu_croissant.png',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'c-02',
      name: 'Morning Pastrami Croissant Burger',
      category: 'croissant',
      description: 'Flaky layered spiral croissant bun, cured pastrami beef, sunny omega egg, aged yellow cheddar, and sweet pickle relish.',
      ingredients: 'Spiral Croissant, Peppercorn Beef Pastrami, Sunny Egg, Melted Cheddar, House Relish',
      price: 69000,
      imageUrl: 'assets/images/morning_pastrami_croissant.png',
    ),
    ProductItem(
      id: 'c-03',
      name: 'Crispy Chicken Avocado Croissant Burger',
      category: 'croissant',
      description: 'Golden flaky croissant burger with 24-hr brined crispy buttermilk chicken thigh, fresh avocado smash, and roasted garlic mayo.',
      ingredients: 'Butter Croissant Bun, Crispy Buttermilk Chicken Thigh, Fresh Haas Avocado Smash, Garlic Herb Aioli',
      price: 66000,
      imageUrl: 'assets/images/crispy_chicken_avocado_croissant.png',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'c-04',
      name: 'Smoked Bacon & Brie Croissant',
      category: 'croissant',
      description: 'Sweet and savory perfection: crisp beef bacon strips, molten French brie cheese, caramelized balsamic onions in flaky croissant.',
      ingredients: 'Laminated Croissant Bun, Crispy Beef Bacon, French Brie Melt, Balsamic Caramelized Onions',
      price: 76000,
      imageUrl: 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=80',
    ),

    // 8 Side Dishes
    ProductItem(
      id: 'sd-01',
      name: 'French Fries',
      category: 'sides',
      description: 'Skin-on Idaho potatoes, twice-fried for legendary crispiness, tossed with rosemary smoked sea salt.',
      ingredients: 'Idaho Potatoes, Rosemary Smoked Sea Salt, Atelier Dipping Sauce',
      price: 28000,
      imageUrl: 'https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'sd-02',
      name: 'Loaded Nachos',
      category: 'sides',
      description: 'Corn tortilla crisps buried under slow cooked chilli con carne, jalapeño slices, sour cream, and molten cheese.',
      ingredients: 'Stoneground Corn Chips, Spiced Beef Chili, Melted Cheddar, Guacamole, Pico De Gallo, Sour Cream',
      price: 42000,
      imageUrl: 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'sd-03',
      name: 'Smoked Beef Sausage',
      category: 'sides',
      description: 'Grilled coarse-ground artisan beef sausage served with whole grain mustard and honey glaze.',
      ingredients: 'Artisan Beef Sausage, Whole Grain Mustard, Honey Glaze',
      price: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1585325701165-351af916e581?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'sd-04',
      name: 'Atelier Hotdog',
      category: 'sides',
      description: 'Jumbo frankfurter inside a toasted split bun, smothered with beef relish, yellow mustard, and crispy shallots.',
      ingredients: 'Split Brioche Roll, Jumbo All-Beef Frank, Sweet Onion Relish, Yellow Mustard, Crispy Shallots',
      price: 45000,
      imageUrl: 'https://images.unsplash.com/photo-1619740455993-9e612b1af08a?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'sd-05',
      name: 'Beer-Battered Onion Rings',
      category: 'sides',
      description: 'Thick-cut sweet Spanish onions in an airy, crispy beer batter with smoked paprika ranch.',
      ingredients: 'Spanish Yellow Onions, Craft Batter, Smoked Paprika Ranch Dip',
      price: 30000,
      imageUrl: 'https://images.unsplash.com/photo-1630825533949-74f62f54553a?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'sd-06',
      name: 'Truffle Mac n Cheese',
      category: 'sides',
      description: 'Elbow macaroni folded in five cheeses (cheddar, gruyere, mozzarella, fontina, parmesan) and shaved truffle oil.',
      ingredients: 'Elbow Pasta, 5-Cheese Béchamel, White Truffle Oil, Herb Panko Breadcrumbs',
      price: 38000,
      imageUrl: 'assets/images/truffle_mac_n_cheese.jpg',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'sd-07',
      name: 'Crispy Hash Brown',
      category: 'sides',
      description: 'Golden, shredded potato patties with an irresistible outer crust and creamy interior.',
      ingredients: 'Grated Russet Potatoes, Sea Salt, Cracked Black Pepper',
      price: 22000,
      imageUrl: 'assets/images/hash_brown.png',
    ),
    ProductItem(
      id: 'sd-08',
      name: 'Smoky Buffalo Chicken Wings',
      category: 'sides',
      description: 'Crispy fried wingettes & drumettes glazed in spicy tangy buffalo sauce, served with blue cheese dip.',
      ingredients: '6pcs Chicken Wings, Spicy Cayenne Pepper Glaze, Celery Sticks, Blue Cheese Sauce',
      price: 48000,
      imageUrl: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?auto=format&fit=crop&w=800&q=80',
      isSpicy: true,
    ),

    // 8 Drinks
    ProductItem(
      id: 'dr-01',
      name: 'Coca-Cola Classic',
      category: 'drinks',
      description: 'Chilled 330ml Coca-Cola served over ice with a wedge of fresh lime.',
      ingredients: 'Carbonated water, caramel, natural flavors',
      price: 18000,
      imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'dr-02',
      name: 'Sprite Crisp Lemon',
      category: 'drinks',
      description: 'Refreshing lemon-lime carbonated soda with crushed mint leaves.',
      ingredients: 'Carbonated lemon lime soda, fresh mint',
      price: 18000,
      imageUrl: 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'dr-03',
      name: 'Fanta Orange Spark',
      category: 'drinks',
      description: 'Vibrant and fruity orange soda served icy cold.',
      ingredients: 'Carbonated orange soda, ice',
      price: 18000,
      imageUrl: 'https://images.unsplash.com/photo-1625740822008-e45abf4e01d5?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'dr-04',
      name: 'Atelier Berry Slushie',
      category: 'drinks',
      description: 'Frozen blended strawberries, raspberries, and wild blueberries with a citrus splash.',
      ingredients: 'Wild Blueberries, Strawberries, Cranberry Juice, Crushed Ice, Mint',
      price: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'dr-05',
      name: 'Fresh Iced Lemon Tea',
      category: 'drinks',
      description: 'Slow-brewed Ceylon black tea infused with fresh Sunkist lemon juice and wild honey.',
      ingredients: 'Ceylon Black Tea, Fresh Lemon Juice, Pure Honey, Kaffir Lime Leaf',
      price: 22000,
      imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'dr-06',
      name: 'Aqua Reflections Mineral Water',
      category: 'drinks',
      description: 'Pure artisan natural spring water in a premium glass bottle.',
      ingredients: 'Natural Mineral Spring Water 380ml',
      price: 15000,
      imageUrl: 'assets/images/aqua_reflections.png',
    ),
    ProductItem(
      id: 'dr-07',
      name: 'Vintage Root Beer Float',
      category: 'drinks',
      description: 'Classic sarsaparilla root beer topped with a velvety scoop of Madagascar vanilla bean ice cream.',
      ingredients: 'A&W Root Beer, Madagascar Vanilla Gelato, Maraschino Cherry',
      price: 35000,
      imageUrl: 'assets/images/vintage_root_beer_float.png',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'dr-08',
      name: 'Dr Pepper',
      category: 'drinks',
      description: 'Distinctive 23-flavor blend carbonated beverage served chilled over ice.',
      ingredients: 'Original 23 Flavor Blend Soda',
      price: 25000,
      imageUrl: 'assets/images/dr_pepper.jpg',
    ),

    // 5 Desserts
    ProductItem(
      id: 'ds-01',
      name: 'Belgian Waffle Ice Cream',
      category: 'desserts',
      description: 'Warm, pearl-sugar Liege waffle topped with salted caramel gelato and toasted pecan nuts.',
      ingredients: 'Belgian Liege Waffle, Salted Caramel Gelato, Roasted Pecans, Maple Syrup',
      price: 38000,
      imageUrl: 'https://images.unsplash.com/photo-1562513872-634b8fae6dbe?auto=format&fit=crop&w=800&q=80',
      isBestSeller: true,
    ),
    ProductItem(
      id: 'ds-02',
      name: 'Artisan Gelato Cup',
      category: 'desserts',
      description: 'Double scoop of handcrafted gelato (choice of French Vanilla & Dark Chocolate Fudge).',
      ingredients: 'Fresh Whole Milk, Cream, Madagascar Vanilla Bean, 70% Dark Cocoa',
      price: 28000,
      imageUrl: 'assets/images/artisan_gelato_cup.png',
    ),
    ProductItem(
      id: 'ds-03',
      name: 'Triple Choc Melt Muffin',
      category: 'desserts',
      description: 'Rich dark chocolate muffin with molten fudge core, served warm with dusted icing sugar.',
      ingredients: 'Belgian Chocolate, Cocoa Butter, Molten Ganache Core',
      price: 26000,
      imageUrl: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'ds-04',
      name: 'Fluffy Souffle Pancake',
      category: 'desserts',
      description: 'Japanese-style airy soufflé pancakes stacked high, served with whipped butter and berry compote.',
      ingredients: 'Soufflé Batter, Hokkaido Whipped Butter, Wild Berry Compote, Pure Maple',
      price: 42000,
      imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=800&q=80',
    ),
    ProductItem(
      id: 'ds-05',
      name: 'Vanilla Bean Panna Cotta',
      category: 'desserts',
      description: 'Silky smooth Italian sweet cream infused with real vanilla bean, topped with passionfruit coulis.',
      ingredients: 'Heavy Sweet Cream, Gelatin, Vanilla Caviar, Passionfruit Coulis',
      price: 32000,
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=800&q=80',
    ),
  ];
}
