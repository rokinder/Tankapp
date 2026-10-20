class Car {
  String id;
  String brand; // z.B. "Volkswagen", "BMW", "Audi"
  String model;
  String iconName; // Identifikator für das Marken-Icon

  Car({required this.id, required this.brand, required this.model, required this.iconName});

  Map<String, dynamic> toJson() => {'id': id, 'brand': brand, 'model': model, 'iconName': iconName};
  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'],
        brand: json['brand'],
        model: json['model'],
        iconName: json['iconName'],
      );
}

class RefuelEntry {
  String id;
  String carId;
  DateTime date;
  double mileage;       // Gesamtkilometerstand
  double liters;        // Getankte Liter gesamt an der Säule
  double price;         // Bezahlter Gesamtpreis
  double canisterLiters;// Liter, die NICHT ins Auto getankt wurden (z.B. Kanister)
  bool isIntermediate;  // Zwischentankung aus Kanister (kein voller Tank -> kein Verbrauch berechenbar)

  RefuelEntry({
    required this.id,
    required this.carId,
    required this.date,
    required this.mileage,
    required this.liters,
    required this.price,
    required this.canisterLiters,
    required this.isIntermediate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'carId': carId,
        'date': date.toIso8601String(),
        'mileage': mileage,
        'liters': liters,
        'price': price,
        'canisterLiters': canisterLiters,
        'isIntermediate': isIntermediate,
      };

  factory RefuelEntry.fromJson(Map<String, dynamic> json) => RefuelEntry(
        id: json['id'],
        carId: json['carId'],
        date: DateTime.parse(json['date']),
        mileage: json['mileage'],
        liters: json['liters'],
        price: json['price'],
        canisterLiters: json['canisterLiters'] ?? 0.0,
        isIntermediate: json['isIntermediate'] ?? false,
      );
}