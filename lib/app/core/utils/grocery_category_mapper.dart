/// Utility class for automatically mapping grocery item names to categories
class GroceryCategoryMapper {
  /// Maps an item name to its most likely category
  /// Returns the category string or 'other' if no match is found
  static String categorizeItem(String itemName) {
    final normalizedName = itemName.toLowerCase().trim();
    
    // Produce (fruits and vegetables)
    if (_matchesProduce(normalizedName)) {
      return 'produce';
    }
    
    // Dairy & Eggs
    if (_matchesDairy(normalizedName)) {
      return 'dairy';
    }
    
    // Meat & Seafood
    if (_matchesMeat(normalizedName)) {
      return 'meat';
    }
    
    // Bakery
    if (_matchesBakery(normalizedName)) {
      return 'bakery';
    }
    
    // Frozen
    if (_matchesFrozen(normalizedName)) {
      return 'frozen';
    }
    
    // Pantry (dry goods, canned goods, etc.)
    if (_matchesPantry(normalizedName)) {
      return 'pantry';
    }
    
    // Beverages
    if (_matchesBeverages(normalizedName)) {
      return 'beverages';
    }
    
    // Household
    if (_matchesHousehold(normalizedName)) {
      return 'household';
    }
    
    // Health & Personal Care
    if (_matchesHealth(normalizedName)) {
      return 'health';
    }
    
    // Default to 'other' if no match
    return 'other';
  }
  
  static bool _matchesProduce(String name) {
    final produceKeywords = [
      // Fruits
      'apple', 'banana', 'orange', 'grape', 'strawberry', 'blueberry', 'raspberry',
      'blackberry', 'mango', 'pineapple', 'watermelon', 'melon', 'peach', 'pear',
      'plum', 'cherry', 'kiwi', 'lemon', 'lime', 'avocado', 'coconut', 'papaya',
      'cantaloupe', 'honeydew', 'grapefruit', 'tangerine', 'clementine',
      // Vegetables
      'lettuce', 'spinach', 'kale', 'cabbage', 'broccoli', 'cauliflower', 'carrot',
      'celery', 'onion', 'garlic', 'tomato', 'potato', 'cucumber', 'pepper',
      'bell pepper', 'jalapeno', 'zucchini', 'squash', 'eggplant', 'mushroom',
      'corn', 'peas', 'green beans', 'asparagus', 'artichoke', 'beet', 'radish',
      'turnip', 'parsnip', 'sweet potato', 'yam', 'leek', 'scallion', 'shallot',
      'herbs', 'basil', 'cilantro', 'parsley', 'rosemary', 'thyme', 'oregano',
      'mint', 'dill', 'sage', 'chive', 'ginger', 'turmeric',
    ];
    
    return produceKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesDairy(String name) {
    final dairyKeywords = [
      'milk', 'cream', 'cheese', 'yogurt', 'yoghurt', 'butter', 'margarine',
      'sour cream', 'cottage cheese', 'cream cheese', 'mozzarella', 'cheddar',
      'swiss', 'provolone', 'parmesan', 'feta', 'ricotta', 'gouda', 'brie',
      'egg', 'eggs', 'quail egg', 'duck egg',
    ];
    
    return dairyKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesMeat(String name) {
    final meatKeywords = [
      // Beef
      'beef', 'steak', 'ground beef', 'hamburger', 'burger', 'roast beef',
      'ribeye', 'sirloin', 'tenderloin', 'brisket', 'chuck', 'round',
      // Pork
      'pork', 'bacon', 'ham', 'sausage', 'chorizo', 'pork chop', 'pork loin',
      'ribs', 'pulled pork',
      // Poultry
      'chicken', 'turkey', 'duck', 'goose', 'quail', 'cornish hen',
      'chicken breast', 'chicken thigh', 'chicken wing', 'drumstick',
      // Seafood
      'fish', 'salmon', 'tuna', 'cod', 'halibut', 'tilapia', 'mackerel',
      'sardine', 'anchovy', 'trout', 'bass', 'snapper', 'grouper',
      'shrimp', 'prawn', 'crab', 'lobster', 'scallop', 'mussel', 'clam',
      'oyster', 'squid', 'octopus', 'caviar',
      // Other
      'lamb', 'veal', 'venison', 'bison', 'organ', 'liver', 'kidney',
    ];
    
    return meatKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesBakery(String name) {
    final bakeryKeywords = [
      'bread', 'bagel', 'muffin', 'croissant', 'donut', 'doughnut', 'pastry',
      'roll', 'bun', 'biscuit', 'scone', 'cake', 'pie', 'tart', 'cookie',
      'cracker', 'pretzel', 'pita', 'naan', 'tortilla', 'wrap', 'flatbread',
      'focaccia', 'ciabatta', 'sourdough', 'rye bread', 'wheat bread',
      'white bread', 'whole grain', 'baguette',
    ];
    
    return bakeryKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesFrozen(String name) {
    final frozenKeywords = [
      'frozen', 'ice cream', 'icecream', 'sorbet', 'gelato', 'frozen yogurt',
      'frozen pizza', 'frozen meal', 'frozen vegetable', 'frozen fruit',
      'frozen berry', 'frozen fish', 'frozen chicken', 'frozen dinner',
      'frozen entree', 'frozen waffle', 'frozen pancake', 'frozen french fry',
      'frozen potato', 'frozen corn', 'frozen pea', 'frozen bean',
    ];
    
    return frozenKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesPantry(String name) {
    final pantryKeywords = [
      // Grains & Pasta
      'rice', 'pasta', 'noodle', 'spaghetti', 'penne', 'macaroni', 'fettuccine',
      'linguine', 'lasagna', 'ravioli', 'quinoa', 'couscous', 'barley',
      'oats', 'oatmeal', 'wheat', 'flour', 'bread flour', 'all purpose',
      // Canned Goods
      'canned', 'can of', 'jar of', 'bottle of',
      // Condiments & Sauces
      'sauce', 'ketchup', 'mustard', 'mayonnaise', 'mayo', 'relish',
      'soy sauce', 'worcestershire', 'hot sauce', 'sriracha', 'tabasco',
      'bbq sauce', 'barbecue sauce', 'marinara', 'pasta sauce', 'alfredo',
      // Oils & Vinegars
      'oil', 'olive oil', 'vegetable oil', 'canola oil', 'coconut oil',
      'vinegar', 'balsamic', 'apple cider vinegar',
      // Spices & Seasonings
      'salt', 'pepper', 'black pepper', 'white pepper', 'paprika', 'cumin',
      'coriander', 'cinnamon', 'nutmeg', 'clove', 'cardamom', 'star anise',
      'bay leaf', 'bay leaves', 'chili powder', 'cayenne', 'red pepper',
      'curry', 'turmeric', 'garam masala', 'allspice', 'fennel',
      // Baking
      'sugar', 'brown sugar', 'powdered sugar', 'confectioners sugar',
      'honey', 'maple syrup', 'molasses', 'vanilla extract', 'vanilla',
      'baking powder', 'baking soda', 'yeast', 'cocoa', 'chocolate chips',
      // Nuts & Seeds
      'nut', 'almond', 'walnut', 'pecan', 'cashew', 'pistachio', 'hazelnut',
      'macadamia', 'peanut', 'seed', 'sunflower seed', 'pumpkin seed',
      'sesame seed', 'chia seed', 'flax seed',
      // Legumes
      'bean', 'black bean', 'kidney bean', 'pinto bean', 'chickpea', 'garbanzo',
      'lentil', 'split pea',
      // Other Pantry Items
      'cereal', 'granola', 'cracker', 'chip', 'pretzel', 'popcorn',
      'peanut butter', 'almond butter', 'jelly', 'jam', 'preserves',
      'broth', 'stock', 'bouillon', 'soup', 'canned soup',
    ];
    
    return pantryKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesBeverages(String name) {
    final beverageKeywords = [
      'juice', 'soda', 'pop', 'cola', 'water', 'sparkling water', 'seltzer',
      'coffee', 'tea', 'green tea', 'black tea', 'herbal tea', 'chai',
      'beer', 'wine', 'champagne', 'liquor', 'spirits', 'whiskey', 'vodka',
      'rum', 'gin', 'tequila', 'smoothie', 'shake', 'milkshake',
      'energy drink', 'sports drink', 'gatorade', 'powerade', 'lemonade',
      'iced tea', 'iced coffee', 'espresso', 'latte', 'cappuccino',
      'hot chocolate', 'cocoa', 'kombucha', 'cider',
    ];
    
    return beverageKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesHousehold(String name) {
    final householdKeywords = [
      'paper towel', 'paper towels', 'toilet paper', 'tissue', 'tissues',
      'napkin', 'napkins', 'trash bag', 'garbage bag', 'ziploc', 'zipper bag',
      'aluminum foil', 'foil', 'plastic wrap', 'saran wrap', 'cling wrap',
      'laundry detergent', 'detergent', 'fabric softener', 'bleach', 'stain remover',
      'dish soap', 'dishwasher detergent', 'dishwasher pod', 'sponge', 'scrubber',
      'broom', 'mop', 'vacuum', 'duster', 'cleaning spray', 'all purpose cleaner',
      'window cleaner', 'bathroom cleaner', 'toilet cleaner', 'air freshener',
      'candle', 'battery', 'batteries', 'light bulb', 'lightbulb', 'bulb',
      'tape', 'scotch tape', 'masking tape', 'duct tape', 'packing tape',
    ];
    
    return householdKeywords.any((keyword) => name.contains(keyword));
  }
  
  static bool _matchesHealth(String name) {
    final healthKeywords = [
      'shampoo', 'conditioner', 'soap', 'body wash', 'body soap', 'hand soap',
      'toothpaste', 'toothbrush', 'dental floss', 'floss', 'mouthwash',
      'deodorant', 'antiperspirant', 'razor', 'shaving cream', 'aftershave',
      'lotion', 'moisturizer', 'sunscreen', 'sunblock', 'lip balm', 'chapstick',
      'vitamin', 'supplement', 'medicine', 'medication', 'bandage', 'bandaid',
      'gauze', 'cotton ball', 'cotton swab', 'q tip', 'qtip', 'tissue',
      'facial tissue', 'baby wipe', 'diaper', 'tampon', 'pad', 'sanitary',
      'contact solution', 'eye drop', 'nasal spray',
    ];
    
    return healthKeywords.any((keyword) => name.contains(keyword));
  }
}

