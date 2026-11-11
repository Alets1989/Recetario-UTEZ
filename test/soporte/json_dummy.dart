// Respuestas de ejemplo con la forma real de DummyJSON (recortada).

// Receta completa, tal como llega de GET /recipes.
Map<String, dynamic> recetaPizza() => {
  'id': 1,
  'name': 'Classic Margherita Pizza',
  'ingredients': ['Pizza dough', 'Tomato sauce', 'Fresh mozzarella cheese'],
  'instructions': ['Preheat the oven', 'Bake'],
  'prepTimeMinutes': 20,
  'cookTimeMinutes': 15,
  'servings': 4,
  'difficulty': 'Easy',
  'cuisine': 'Italian',
  'caloriesPerServing': 300,
  'tags': ['Pizza', 'Italian'],
  'userId': 45,
  'image': 'https://cdn.dummyjson.com/recipe-images/1.webp',
  'rating': 4.6,
  'reviewCount': 3,
  'mealType': ['Dinner'],
};

// Receta rápida, con calificación entera (pasa en la API real) y sin tags.
Map<String, dynamic> recetaSalsa() => {
  'id': 7,
  'name': 'Mango Salsa Chicken',
  'prepTimeMinutes': 10,
  'cookTimeMinutes': 15,
  'servings': 2,
  'difficulty': 'Medium',
  'cuisine': 'Mexican',
  'rating': 5,
};

// Receta con dificultad que la app no conoce.
Map<String, dynamic> recetaRara() => {
  'id': 9,
  'name': 'Soufflé',
  'prepTimeMinutes': 40,
  'cookTimeMinutes': 30,
  'servings': 6,
  'difficulty': 'Extreme',
  'cuisine': 'French',
  'rating': 3.94,
  'tags': ['Postre'],
};

Map<String, dynamic> paginaTres() => {
  'recipes': [recetaPizza(), recetaSalsa(), recetaRara()],
  'total': 50,
  'skip': 0,
  'limit': 3,
};

// Lo que responde /recipes/search cuando no hay resultados.
Map<String, dynamic> paginaVacia() => {
  'recipes': <Object>[],
  'total': 0,
  'skip': 0,
  'limit': 0,
};

// Lo que responde DummyJSON en /http/503.
const error503 = {
  'status': 503,
  'title': 'Service Unavailable',
  'message': 'Service Unavailable',
};
