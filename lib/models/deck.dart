import 'package:flutter/material.dart';

class Deck {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> words;

  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    List<String>? words,
  }) : words = words ?? _getDefaultWordsForCategory(id);

  static List<String> _getDefaultWordsForCategory(String categoryId) {
    switch (categoryId) {
      case '1': // Movies
        return [
          'Titanic', 'Inception', 'The Godfather', 'Avatar', 'Star Wars',
          'Jurassic Park', 'The Dark Knight', 'Forrest Gump', 'The Matrix', 'Frozen',
          'Toy Story', 'The Lion King', 'Avengers', 'Jaws', 'Back to the Future',
          'E.T.', 'The Wizard of Oz', 'Titanic', 'The Shawshank Redemption', 'Pulp Fiction'
        ];
      case '2': // Animals
        return [
          'Elephant', 'Giraffe', 'Penguin', 'Kangaroo', 'Dolphin',
          'Octopus', 'Cheetah', 'Gorilla', 'Panda', 'Koala',
          'Zebra', 'Hippopotamus', 'Crocodile', 'Eagle', 'Owl',
          'Shark', 'Whale', 'Butterfly', 'Chameleon', 'Platypus'
        ];
      case '3': // Actions
        return [
          'Dancing', 'Jumping', 'Singing', 'Swimming', 'Running',
          'Sleeping', 'Laughing', 'Crying', 'Whispering', 'Yawning',
          'Pointing', 'Climbing', 'Falling', 'Waving', 'Hugging',
          'Kicking', 'Throwing', 'Catching', 'Whistling', 'Sneezing'
        ];
      case '4': // Food
        return [
          'Pizza', 'Hamburger', 'Sushi', 'Pasta', 'Ice Cream',
          'Chocolate', 'Pancakes', 'Taco', 'Salad', 'Steak',
          'Sandwich', 'Donut', 'Popcorn', 'Noodles', 'Curry',
          'Burrito', 'Waffle', 'Cupcake', 'Sausage', 'Omelet'
        ];
      case '5': // Professions
        return [
          'Doctor', 'Teacher', 'Firefighter', 'Astronaut', 'Chef',
          'Police Officer', 'Artist', 'Musician', 'Scientist', 'Athlete',
          'Journalist', 'Pilot', 'Engineer', 'Dentist', 'Farmer',
          'Actor', 'Singer', 'Dancer', 'Writer', 'Architect'
        ];
      case '6': // Sports
        return [
          'Basketball', 'Soccer', 'Tennis', 'Golf', 'Swimming',
          'Boxing', 'Cycling', 'Running', 'Volleyball', 'Baseball',
          'Gymnastics', 'Wrestling', 'Cricket', 'Hockey', 'Badminton',
          'Table Tennis', 'Rugby', 'Surfing', 'Skiing', 'Archery'
        ];
      default:
        return [
          'Example Word 1', 'Example Word 2', 'Example Word 3',
          'Example Word 4', 'Example Word 5'
        ];
    }
  }

  // Factory method to create a deck from a map (e.g., from JSON)
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: _getIconData(map['icon'] ?? ''),
      color: _getColor(map['color'] ?? 'blue'),
      words: List<String>.from(map['words'] ?? []),
    );
  }

  // Convert deck to a map (e.g., for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': _getIconName(icon),
      'color': _getColorName(color),
      'words': words,
    };
  }

  // Helper method to get IconData from string
  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'movie':
        return Icons.movie;
      case 'pets':
        return Icons.pets;
      case 'directions_run':
        return Icons.directions_run;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  // Helper method to get string from IconData
  static String _getIconName(IconData icon) {
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.pets) return 'pets';
    if (icon == Icons.directions_run) return 'directions_run';
    if (icon == Icons.restaurant) return 'restaurant';
    return 'category';
  }

  // Helper method to get Color from string
  static Color _getColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Helper method to get string from Color
  static String _getColorName(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.green) return 'green';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.orange) return 'orange';
    return 'blue';
  }
}
