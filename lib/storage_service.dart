import 'dart:io';
import 'dart:convert';
import 'models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<String> getSavePath() async {
    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString('custom_storage_path');
    if (customPath != null && await Directory(customPath).exists()) {
      return customPath;
    }
    // Standard-Pfad im internen Handyspeicher
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<void> saveData(List<Car> cars, List<RefuelEntry> entries) async {
    final path = await getSavePath();
    final file = File('$path/fuel_data.json');
    final data = {
      'cars': cars.map((c) => c.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data));
  }

  static Future<Map<String, dynamic>> loadData() async {
    try {
      final path = await getSavePath();
      final file = File('$path/fuel_data.json');
      if (!file.existsSync()) return {'cars': <Car>[], 'entries': <RefuelEntry>[]};
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      List<Car> cars = (data['cars'] as List).map((c) => Car.fromJson(c)).toList();
      List<RefuelEntry> entries = (data['entries'] as List).map((e) => RefuelEntry.fromJson(e)).toList();
      return {'cars': cars, 'entries': entries};
    } catch (e) {
      return {'cars': <Car>[], 'entries': <RefuelEntry>[]};
    }
  }
}