<?php

/**
 * Menus for the seven restaurants in store 15 (Food).
 *
 * Store 15 holds 43 products across all seven vendors, so the clone strategy
 * used by zenfoo:stock-vendors cannot work here — it would put pizza in a sweet
 * shop. These are real menus instead, written per cuisine.
 *
 * Item tuple: [name, price, mrp, indicator, unit_id, image query, must-words]
 *   indicator  1 = veg, 2 = non-veg (drives the green/red dot in the app)
 *   unit_id    34 Plate, 35 Serving, 37 Bowl, 38 Cup, 39 Glass, 41 Slice,
 *              3 Pieces, 2 Grams
 *   must-words comma separated; the photo's caption must contain all of them,
 *              which is what stops "Snake Gourd" style near-miss matches
 *
 * Dish names repeat across restaurants on purpose — two shops really do both
 * sell Gulab Jamun — and the image fetcher resolves each unique name once.
 *
 * Used by: zenfoo:stock-restaurants
 */

return [

    // ── Masala Magic — biryani house ─────────────────────────────────────
    45 => [
        'Biryani' => [
            ['Hyderabadi Chicken Dum Biryani', 289, 349, 2, 34, 'chicken biryani rice', 'biryani'],
            ['Mutton Dum Biryani', 379, 449, 2, 34, 'mutton biryani rice', 'biryani'],
            ['Boneless Chicken Biryani', 309, 369, 2, 34, 'biryani rice chicken', 'biryani'],
            ['Chicken Fry Piece Biryani', 329, 389, 2, 34, 'biryani fried chicken rice', 'biryani'],
            ['Egg Biryani', 199, 249, 2, 34, 'egg biryani rice', 'biryani'],
            ['Veg Dum Biryani', 189, 229, 1, 34, 'vegetable biryani rice', 'biryani'],
            ['Paneer Biryani', 229, 279, 1, 34, 'paneer biryani rice', 'biryani'],
            ['Prawn Biryani', 349, 419, 2, 34, 'prawn biryani rice seafood', 'biryani'],
        ],
        'Starters' => [
            ['Apollo Fish', 279, 329, 2, 34, 'fried fish starter indian', 'fish'],
            ['Chilli Chicken', 239, 289, 2, 34, 'chilli chicken indian chinese', 'chicken'],
            ['Paneer 65', 219, 259, 1, 34, 'fried paneer cubes indian', 'paneer'],
            ['Gobi Manchurian', 189, 229, 1, 34, 'gobi manchurian cauliflower', 'manchurian,cauliflower'],
            ['Mutton Pepper Fry', 329, 389, 2, 34, 'mutton pepper fry indian', 'mutton'],
            ['Chicken Lollipop', 249, 299, 2, 34, 'chicken lollipop fried', 'chicken'],
        ],
        'Kebabs' => [
            ['Chicken Malai Kebab', 289, 339, 2, 34, 'chicken kebab skewer grilled', 'kebab,chicken'],
            ['Mutton Seekh Kebab', 339, 399, 2, 34, 'seekh kebab minced meat', 'kebab'],
            ['Tangdi Kebab', 269, 319, 2, 34, 'tandoori chicken leg kebab', 'tandoori,chicken'],
            ['Hariyali Chicken Tikka', 279, 329, 2, 34, 'chicken tikka green marinade', 'tikka,chicken'],
        ],
        'Curries' => [
            ['Butter Chicken', 319, 379, 2, 37, 'butter chicken curry indian', 'butter,chicken'],
            ['Chicken Tikka Masala', 309, 369, 2, 37, 'chicken tikka masala curry', 'tikka,chicken'],
            ['Mutton Rogan Josh', 379, 449, 2, 37, 'mutton curry indian lamb', 'curry'],
            ['Paneer Butter Masala', 249, 299, 1, 37, 'paneer butter masala curry', 'paneer'],
            ['Kadai Chicken', 289, 349, 2, 37, 'kadai chicken curry indian', 'chicken,curry'],
            ['Dal Tadka', 179, 219, 1, 37, 'dal tadka lentil curry indian', 'dal,lentil'],
        ],
        'Breads' => [
            ['Butter Naan', 45, 55, 1, 3, 'naan bread indian', 'naan'],
            ['Garlic Naan', 55, 65, 1, 3, 'garlic naan bread', 'naan'],
            ['Tandoori Roti', 35, 45, 1, 3, 'tandoori roti indian flatbread', 'roti,bread'],
            ['Laccha Paratha', 55, 69, 1, 3, 'paratha layered indian bread', 'paratha'],
        ],
        'Beverages' => [
            ['Sweet Lassi', 79, 99, 1, 39, 'lassi yogurt drink indian', 'lassi'],
            ['Mango Lassi', 99, 119, 1, 39, 'mango lassi drink', 'mango,lassi'],
            ['Masala Chaas', 59, 75, 1, 39, 'buttermilk drink glass indian', 'buttermilk'],
        ],
        'Desserts' => [
            ['Qubani Ka Meetha', 129, 159, 1, 37, 'apricot dessert bowl', 'apricot'],
            ['Gulab Jamun', 89, 109, 1, 37, 'gulab jamun indian sweet', 'gulab,jamun'],
            ['Rasmalai', 109, 129, 1, 37, 'rasmalai indian sweet dessert', 'rasmalai'],
        ],
    ],

    // ── Maharaja chat — chaat house ──────────────────────────────────────
    96 => [
        'Chaat' => [
            ['Pani Puri', 69, 89, 1, 34, 'pani puri golgappa indian street food', 'puri'],
            ['Bhel Puri', 79, 99, 1, 34, 'bhel puri indian street food', 'bhel'],
            ['Sev Puri', 79, 99, 1, 34, 'sev puri chaat indian', 'puri'],
            ['Dahi Puri', 89, 109, 1, 34, 'dahi puri chaat yogurt', 'puri'],
            ['Papdi Chaat', 89, 109, 1, 34, 'papdi chaat indian snack', 'chaat'],
            ['Samosa Chaat', 99, 119, 1, 34, 'samosa chaat indian snack', 'samosa'],
            ['Raj Kachori', 109, 129, 1, 34, 'kachori indian street food', 'kachori'],
            ['Aloo Chaat', 79, 99, 1, 34, 'aloo chaat potato indian snack', 'chaat'],
            ['Corn Chaat', 89, 109, 1, 37, 'sweet corn chaat bowl', 'corn'],
        ],
        'Tikki & Fritters' => [
            ['Aloo Tikki', 79, 99, 1, 34, 'aloo tikki potato patty indian', 'tikki'],
            ['Ragda Pattice', 99, 119, 1, 34, 'ragda pattice indian street food', 'pattice,ragda'],
            ['Dahi Vada', 89, 109, 1, 34, 'dahi vada yogurt indian', 'vada'],
            ['Mirchi Bajji', 69, 89, 1, 34, 'mirchi bajji chilli fritter indian', 'bajji,fritter'],
            ['Punugulu', 69, 89, 1, 34, 'fried snack balls indian', 'fritter,snack'],
            ['Onion Pakoda', 79, 99, 1, 34, 'onion pakora fritter indian', 'pakora,fritter'],
        ],
        'Tiffins' => [
            ['Masala Dosa', 119, 149, 1, 34, 'masala dosa south indian', 'dosa'],
            ['Plain Dosa', 89, 109, 1, 34, 'dosa south indian crepe', 'dosa'],
            ['Onion Uttapam', 109, 129, 1, 34, 'uttapam south indian pancake', 'uttapam'],
            ['Idli Sambar', 79, 99, 1, 34, 'idli sambar south indian', 'idli'],
            ['Medu Vada', 79, 99, 1, 34, 'medu vada south indian', 'vada'],
            ['Poori Curry', 99, 119, 1, 34, 'poori bhaji indian breakfast', 'poori,puri'],
        ],
        'Rolls & Sandwiches' => [
            ['Veg Frankie', 109, 129, 1, 3, 'veg wrap roll indian street food', 'wrap,roll'],
            ['Paneer Kathi Roll', 139, 169, 1, 3, 'paneer kathi roll wrap', 'roll,wrap'],
            ['Chicken Kathi Roll', 159, 189, 2, 3, 'chicken kathi roll wrap', 'roll,wrap'],
            ['Grilled Veg Sandwich', 119, 139, 1, 3, 'grilled vegetable sandwich', 'sandwich'],
            ['Bombay Masala Sandwich', 129, 149, 1, 3, 'masala sandwich indian street food', 'sandwich'],
        ],
        'Sweets' => [
            ['Jalebi', 89, 109, 1, 34, 'jalebi indian sweet', 'jalebi'],
            ['Gulab Jamun', 89, 109, 1, 37, 'gulab jamun indian sweet', 'gulab,jamun'],
            ['Rabdi', 109, 129, 1, 37, 'rabri indian milk dessert', 'dessert'],
        ],
        'Beverages' => [
            ['Masala Chai', 39, 49, 1, 38, 'masala chai indian tea cup', 'chai,tea'],
            ['Filter Coffee', 49, 59, 1, 38, 'south indian filter coffee', 'coffee'],
            ['Rose Milk', 69, 89, 1, 39, 'rose milk pink drink glass', 'milk'],
            ['Sugarcane Juice', 59, 79, 1, 39, 'sugarcane juice glass', 'sugarcane,juice'],
            ['Sweet Lassi', 69, 89, 1, 39, 'lassi yogurt drink indian', 'lassi'],
            ['Mango Lassi', 89, 109, 1, 39, 'mango lassi drink', 'mango,lassi'],
        ],
    ],

    // ── Sugar Silo — sweet shop and bakery ───────────────────────────────
    62 => [
        'Milk Sweets' => [
            ['Kaju Katli', 189, 229, 1, 2, 'kaju katli indian sweet cashew', 'sweet'],
            ['Kalakand', 169, 199, 1, 2, 'kalakand indian milk sweet', 'sweet'],
            ['Malai Peda', 179, 209, 1, 2, 'peda indian milk sweet', 'sweet'],
            ['Mysore Pak', 149, 179, 1, 2, 'mysore pak indian sweet', 'sweet'],
            ['Doodh Peda', 169, 199, 1, 2, 'peda indian sweets plate', 'sweet'],
            ['Rasmalai', 199, 239, 1, 37, 'rasmalai indian sweet dessert', 'rasmalai'],
            ['Rabdi', 179, 209, 1, 37, 'rabri indian milk dessert', 'dessert'],
        ],
        'Dry Fruit Sweets' => [
            ['Dry Fruit Laddu', 249, 299, 1, 2, 'dry fruit laddu indian sweet', 'laddu,sweet'],
            ['Anjeer Barfi', 279, 329, 1, 2, 'fig barfi indian sweet', 'sweet'],
            ['Badam Halwa', 259, 309, 1, 37, 'almond halwa indian dessert', 'halwa,almond'],
            ['Kaju Pista Roll', 289, 339, 1, 2, 'cashew pistachio indian sweet', 'sweet'],
            ['Dates And Nuts Roll', 269, 319, 1, 2, 'dates nuts roll sweet', 'dates'],
        ],
        'Bengali Sweets' => [
            ['Rasgulla', 149, 179, 1, 37, 'rasgulla bengali sweet', 'rasgulla'],
            ['Sandesh', 169, 199, 1, 2, 'sandesh bengali sweet', 'sweet'],
            ['Cham Cham', 179, 209, 1, 2, 'bengali sweet dessert plate', 'sweet'],
            ['Rajbhog', 189, 219, 1, 37, 'indian sweet syrup bowl', 'sweet'],
            ['Mishti Doi', 99, 129, 1, 37, 'sweet yogurt bengali dessert', 'yogurt'],
        ],
        'Festive Boxes' => [
            ['Assorted Sweet Box 500g', 549, 649, 1, 17, 'indian sweets assorted box', 'sweet'],
            ['Diwali Special Hamper', 899, 1099, 1, 17, 'diwali sweets gift box', 'sweet,gift'],
            ['Kaju Assorted Box', 749, 899, 1, 17, 'cashew indian sweets box', 'sweet'],
            ['Ghee Sweets Box', 649, 779, 1, 17, 'indian sweets tray assorted', 'sweet'],
        ],
        'Cakes & Bakes' => [
            ['Chocolate Truffle Pastry', 119, 149, 1, 41, 'chocolate cake slice pastry', 'chocolate,cake'],
            ['Black Forest Slice', 109, 139, 1, 41, 'black forest cake slice', 'cake'],
            ['Butterscotch Pastry', 109, 139, 1, 41, 'butterscotch cake slice pastry', 'cake'],
            ['Plum Cake', 149, 179, 1, 41, 'fruit plum cake slice', 'cake'],
            ['Red Velvet Pastry', 129, 159, 1, 41, 'red velvet cake slice', 'cake'],
            ['Vanilla Cupcake', 79, 99, 1, 3, 'vanilla cupcake frosting', 'cupcake'],
        ],
        'Namkeen' => [
            ['Soan Papdi', 129, 159, 1, 17, 'soan papdi indian sweet', 'sweet'],
            ['Mixture Namkeen', 99, 129, 1, 2, 'indian namkeen mixture snack', 'snack'],
            ['Ratlami Sev', 109, 139, 1, 2, 'sev indian namkeen snack', 'snack'],
            ['Chakli', 119, 149, 1, 2, 'chakli murukku indian snack', 'snack'],
            ['Murukku', 119, 149, 1, 2, 'murukku indian snack spiral', 'snack'],
            ['Aloo Bhujia', 89, 109, 1, 2, 'bhujia indian namkeen snack', 'snack'],
            ['Khara Boondi', 89, 109, 1, 2, 'boondi indian namkeen snack', 'snack'],
        ],
    ],

    // ── Pulla Reddy Sweets — traditional sweets and hot chips ────────────
    67 => [
        'Milk Based Sweets' => [
            ['Kaju Katli', 199, 239, 1, 2, 'kaju katli indian sweet cashew', 'sweet'],
            ['Badusha', 149, 179, 1, 2, 'badusha balushahi indian sweet', 'sweet'],
            ['Dharwad Peda', 179, 209, 1, 2, 'peda indian milk sweet plate', 'sweet'],
            ['Basundi', 129, 159, 1, 37, 'basundi indian milk dessert', 'dessert'],
            ['Rasgulla', 159, 189, 1, 37, 'rasgulla bengali sweet', 'rasgulla'],
            ['Kalakand', 179, 209, 1, 2, 'kalakand indian milk sweet', 'sweet'],
            ['Kova Kajjikayalu', 189, 229, 1, 2, 'indian sweet dumpling plate', 'sweet'],
        ],
        'Ghee Sweets' => [
            ['Ghee Mysore Pak', 199, 239, 1, 2, 'mysore pak indian sweet ghee', 'sweet'],
            ['Bombay Halwa', 169, 199, 1, 2, 'halwa indian sweet dessert', 'halwa'],
            ['Sunnundalu', 189, 219, 1, 2, 'laddu indian sweet balls', 'laddu'],
            ['Ariselu', 169, 199, 1, 2, 'indian sweet rice jaggery', 'sweet'],
            ['Boondi Laddu', 149, 179, 1, 2, 'boondi laddu indian sweet', 'laddu'],
        ],
        'Dry Fruit Sweets' => [
            ['Kaju Pista Roll', 299, 349, 1, 2, 'cashew pistachio indian sweet', 'sweet'],
            ['Anjeer Barfi', 289, 339, 1, 2, 'fig barfi indian sweet', 'sweet'],
            ['Dry Fruit Laddu', 259, 309, 1, 2, 'dry fruit laddu indian sweet', 'laddu,sweet'],
            ['Badam Halwa', 269, 319, 1, 37, 'almond halwa indian dessert', 'halwa,almond'],
        ],
        'Hot Chips' => [
            ['Ribbon Pakodi', 109, 139, 1, 2, 'ribbon pakoda indian snack', 'snack'],
            ['Karapusa', 99, 129, 1, 2, 'sev indian namkeen snack', 'snack'],
            ['Mixture', 109, 139, 1, 2, 'indian namkeen mixture snack', 'snack'],
            ['Chekkalu', 119, 149, 1, 2, 'indian rice cracker snack', 'snack,cracker'],
            ['Murukku', 119, 149, 1, 2, 'murukku indian snack spiral', 'snack'],
            ['Corn Chips', 89, 109, 1, 2, 'corn chips snack bowl', 'chips'],
        ],
        'Milk Drinks' => [
            ['Kesar Milk', 79, 99, 1, 39, 'saffron milk drink glass', 'milk'],
            ['Filter Coffee', 49, 59, 1, 38, 'south indian filter coffee', 'coffee'],
            ['Sweet Lassi', 69, 89, 1, 39, 'lassi yogurt drink indian', 'lassi'],
            ['Mango Lassi', 89, 109, 1, 39, 'mango lassi drink', 'mango,lassi'],
        ],
    ],

    // ── Zenfoo Crazy Fast Food — fast food and Indo-Chinese ──────────────
    29 => [
        'Pizza' => [
            ['Margherita Pizza', 199, 249, 1, 34, 'margherita pizza cheese', 'pizza'],
            ['Farmhouse Pizza', 279, 329, 1, 34, 'vegetable pizza whole', 'pizza'],
            ['Peppy Paneer Pizza', 299, 349, 1, 34, 'paneer pizza indian', 'pizza'],
            ['Chicken Tikka Pizza', 329, 389, 2, 34, 'chicken pizza slice', 'pizza'],
            ['Double Cheese Pizza', 309, 369, 1, 34, 'cheese pizza melted', 'pizza,cheese'],
        ],
        'Statters' => [
            ['Chilli Chicken', 249, 299, 2, 34, 'chilli chicken indian chinese', 'chicken'],
            ['Chicken Lollipop', 259, 309, 2, 34, 'chicken lollipop fried', 'chicken'],
            ['Veg Manchurian', 199, 239, 1, 37, 'veg manchurian balls gravy', 'manchurian'],
            ['French Fries', 119, 149, 1, 34, 'french fries potato', 'fries'],
            ['Crispy Corn', 149, 179, 1, 37, 'crispy fried corn snack', 'corn'],
        ],
        'Burgers' => [
            ['Veg Burger', 119, 149, 1, 3, 'veggie burger sandwich', 'burger'],
            ['Chicken Zinger Burger', 179, 219, 2, 3, 'crispy chicken burger', 'burger,chicken'],
            ['Cheese Burst Burger', 169, 199, 1, 3, 'cheese burger melted', 'burger,cheese'],
            ['Paneer Burger', 149, 179, 1, 3, 'paneer burger indian', 'burger'],
        ],
        'Rolls & Wraps' => [
            ['Chicken Shawarma Roll', 169, 199, 2, 3, 'chicken shawarma wrap roll', 'shawarma,wrap'],
            ['Paneer Wrap', 149, 179, 1, 3, 'paneer wrap roll indian', 'wrap,roll'],
            ['Veg Frankie', 119, 149, 1, 3, 'veg wrap roll indian street food', 'wrap,roll'],
        ],
        'Noodles & Pasta' => [
            ['Hakka Noodles', 179, 219, 1, 37, 'hakka noodles vegetable stir fry', 'noodle'],
            ['Schezwan Chicken Noodles', 219, 259, 2, 37, 'chicken noodles schezwan', 'noodle'],
            ['Chicken Fried Rice', 199, 239, 2, 37, 'chicken fried rice', 'rice'],
            ['White Sauce Pasta', 209, 249, 1, 37, 'white sauce pasta creamy', 'pasta'],
            ['Red Sauce Pasta', 199, 239, 1, 37, 'tomato sauce pasta penne', 'pasta'],
        ],
        'Beverages' => [
            ['Cold Coffee', 99, 129, 1, 39, 'iced cold coffee glass', 'coffee'],
            ['Chocolate Milkshake', 129, 159, 1, 39, 'chocolate milkshake glass', 'milkshake'],
            ['Fresh Lime Soda', 69, 89, 1, 39, 'lime soda drink glass', 'lime,soda'],
            ['Masala Chai', 39, 49, 1, 38, 'masala chai indian tea cup', 'chai,tea'],
        ],
    ],

    // ── CinnaMan's Café — café, burgers and shawarma ─────────────────────
    32 => [
        'Burgers' => [
            ['Classic Chicken Burger', 189, 229, 2, 3, 'chicken burger sandwich', 'burger,chicken'],
            ['Crispy Veg Burger', 139, 169, 1, 3, 'veggie burger sandwich', 'burger'],
            ['Paneer Tikka Burger', 169, 199, 1, 3, 'paneer burger indian', 'burger'],
        ],
        'Shawarma' => [
            ['Chicken Shawarma Plate', 229, 279, 2, 34, 'chicken shawarma plate', 'shawarma'],
            ['Falafel Shawarma Wrap', 179, 219, 1, 3, 'falafel wrap pita', 'falafel'],
            ['Shawarma Rice Bowl', 249, 299, 2, 37, 'chicken rice bowl middle eastern', 'rice,chicken'],
        ],
        'Starters' => [
            ['Peri Peri Fries', 149, 179, 1, 34, 'peri peri french fries', 'fries'],
            ['Chicken Wings', 249, 299, 2, 34, 'chicken wings sauce', 'wing'],
            ['Nachos With Salsa', 199, 239, 1, 34, 'nachos salsa cheese', 'nacho'],
            ['Garlic Bread', 129, 159, 1, 3, 'garlic bread cheese', 'garlic,bread'],
        ],
        'Coffee & Beverages' => [
            ['Cappuccino', 129, 159, 1, 38, 'cappuccino coffee cup latte art', 'cappuccino,coffee'],
            ['Cafe Latte', 139, 169, 1, 38, 'cafe latte coffee cup', 'latte,coffee'],
            ['Espresso', 99, 119, 1, 38, 'espresso coffee shot cup', 'espresso'],
            ['Iced Americano', 149, 179, 1, 39, 'iced americano coffee glass', 'coffee,iced'],
            ['Cold Coffee', 159, 189, 1, 39, 'iced cold coffee glass', 'coffee'],
            ['Hot Chocolate', 149, 179, 1, 38, 'hot chocolate mug cocoa', 'chocolate'],
        ],
        'Bakery' => [
            ['Chocolate Croissant', 129, 159, 1, 3, 'chocolate croissant pastry', 'croissant'],
            ['Blueberry Muffin', 119, 149, 1, 3, 'blueberry muffin bakery', 'muffin'],
            ['Chocolate Brownie', 129, 159, 1, 3, 'chocolate brownie dessert', 'brownie'],
            ['Cheesecake Slice', 179, 219, 1, 41, 'cheesecake slice dessert', 'cheesecake'],
        ],
        'Sandwiches' => [
            ['Club Sandwich', 189, 229, 2, 3, 'club sandwich triple decker', 'sandwich'],
            ['Grilled Cheese Sandwich', 149, 179, 1, 3, 'grilled cheese sandwich', 'sandwich,cheese'],
            ['Chicken Mayo Sandwich', 169, 199, 2, 3, 'chicken sandwich mayo', 'sandwich,chicken'],
        ],
    ],

    // ── UrbanBite Cafe — all-day café ────────────────────────────────────
    36 => [
        'Breakfast' => [
            ['Masala Omelette', 119, 149, 2, 34, 'omelette eggs breakfast plate', 'omelette,egg'],
            ['Veg Sandwich', 109, 139, 1, 3, 'vegetable sandwich breakfast', 'sandwich'],
            ['Pancakes With Honey', 169, 199, 1, 34, 'pancakes stack honey syrup', 'pancake'],
            ['Poha', 89, 109, 1, 37, 'poha indian breakfast flattened rice', 'poha,breakfast'],
            ['Upma', 89, 109, 1, 37, 'upma south indian breakfast', 'upma,breakfast'],
            ['Aloo Paratha', 119, 149, 1, 34, 'aloo paratha indian breakfast', 'paratha'],
        ],
        'Coffee & Tea' => [
            ['Cappuccino', 139, 169, 1, 38, 'cappuccino coffee cup latte art', 'cappuccino,coffee'],
            ['Cafe Latte', 149, 179, 1, 38, 'cafe latte coffee cup', 'latte,coffee'],
            ['Filter Coffee', 59, 79, 1, 38, 'south indian filter coffee', 'coffee'],
            ['Green Tea', 79, 99, 1, 38, 'green tea cup', 'tea'],
            ['Masala Chai', 49, 59, 1, 38, 'masala chai indian tea cup', 'chai,tea'],
            ['Iced Coffee', 159, 189, 1, 39, 'iced coffee glass ice', 'coffee,iced'],
        ],
        'Burgers & Wraps' => [
            ['Veg Burger', 139, 169, 1, 3, 'veggie burger sandwich', 'burger'],
            ['Chicken Burger', 189, 229, 2, 3, 'chicken burger sandwich', 'burger,chicken'],
            ['Paneer Wrap', 159, 189, 1, 3, 'paneer wrap roll indian', 'wrap,roll'],
            ['Falafel Wrap', 169, 199, 1, 3, 'falafel wrap pita', 'falafel'],
        ],
        'Pasta & Bowls' => [
            ['Alfredo Pasta', 229, 269, 1, 37, 'alfredo pasta creamy white', 'pasta'],
            ['Arrabbiata Pasta', 219, 259, 1, 37, 'tomato sauce pasta penne', 'pasta'],
            ['Buddha Bowl', 249, 299, 1, 37, 'buddha bowl vegetables healthy', 'bowl'],
            ['Chicken Rice Bowl', 259, 309, 2, 37, 'chicken rice bowl middle eastern', 'rice,chicken'],
        ],
        'Bakery' => [
            ['Chocolate Brownie', 139, 169, 1, 3, 'chocolate brownie dessert', 'brownie'],
            ['Banana Bread', 129, 159, 1, 41, 'banana bread loaf slice', 'banana,bread'],
            ['Blueberry Muffin', 129, 159, 1, 3, 'blueberry muffin bakery', 'muffin'],
            ['Butter Croissant', 119, 149, 1, 3, 'butter croissant pastry', 'croissant'],
            ['Red Velvet Pastry', 149, 179, 1, 41, 'red velvet cake slice', 'cake'],
        ],
        'Shakes & Smoothies' => [
            ['Oreo Shake', 179, 209, 1, 39, 'cookies cream milkshake glass', 'milkshake'],
            ['Mango Smoothie', 169, 199, 1, 39, 'mango smoothie glass', 'smoothie,mango'],
            ['Cold Coffee Shake', 169, 199, 1, 39, 'iced cold coffee glass', 'coffee'],
            ['Banana Peanut Smoothie', 179, 209, 1, 39, 'banana smoothie glass', 'smoothie,banana'],
        ],
        'Indian Sweets' => [
            ['Kaju Katli', 199, 239, 1, 2, 'kaju katli indian sweet cashew', 'sweet'],
            ['Gulab Jamun', 99, 119, 1, 37, 'gulab jamun indian sweet', 'gulab,jamun'],
            ['Rasmalai', 119, 139, 1, 37, 'rasmalai indian sweet dessert', 'rasmalai'],
        ],
    ],
];
