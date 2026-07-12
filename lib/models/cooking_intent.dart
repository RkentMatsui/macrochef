enum IntentType {
  nextStep,
  prevStep,
  repeatStep,
  logIngredient,
  adjustIngredient,
  currentMacros,
  dailyTotal,
  exit,
  unknown,
}

class CookingIntent {
  final IntentType type;
  final String? food;   // for logIngredient
  final double? grams;  // for logIngredient
  const CookingIntent(this.type, {this.food, this.grams});
}
