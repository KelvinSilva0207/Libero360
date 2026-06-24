class CategoryCalculator {
  static String calculate(int age) {
    if (age <= 0) return 'Sin categoría';
    if (age <= 12) return 'U13';
    if (age <= 14) return 'U15';
    if (age <= 16) return 'U17';
    if (age <= 18) return 'U19';
    return 'Libre';
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
