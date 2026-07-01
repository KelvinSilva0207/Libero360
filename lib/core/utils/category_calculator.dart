import '../services/category_service.dart';

class CategoryCalculator {
  static String calculate(int age) {
    return CategoryService.instance.calculate(age);
  }

  static String calculateFromBirth(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return calculate(age);
  }
}
