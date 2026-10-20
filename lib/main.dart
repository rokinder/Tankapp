import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'storage_service.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BenzinApp());
}

class BenzinApp extends StatelessWidget {
  const BenzinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Benzinrechner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Car> cars = [];
  List<RefuelEntry> entries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await StorageService.loadData();
    setState(() {
      cars = data['cars'];
      entries = data['entries'];
      isLoading = false;
    });
  }

  Future<void> _saveData() async {
    await StorageService.saveData(cars, entries);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benzin- & Verbrauchsrechner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen(onPathChanged: _loadData)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Großer Button: Neuer Tankvorgang
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.local_gas_station, size: 28),
                label: const Text('Tankvorgang erfassen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (cars.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bitte legen Sie zuerst ein Auto an!')),
                    );
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddEntryScreen(cars: cars)),
                  );
                  _loadData();
                },
              ),
            ),
            const SizedBox(height: 16),
            // Großer Button: Auto verwalten
            SizedBox(
              height: 60,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                icon: const Icon(Icons.directions_car, size: 28),
                label: const Text('Autos verwalten / Hinzufügen', style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CarManageScreen(cars: cars, onCarChanged: _saveData)),
                  );
                  _loadData();
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('Gespeicherte Tankdaten:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Noch keine Tankvorgänge eingetragen.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final car = cars.firstWhere((c) => c.id == entry.carId, orElse: () => Car(id: '', brand: 'Unbekannt', model: '', iconName: ''));
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          child: ListTile(
                            leading: const Icon(Icons.directions_car, size: 36, color: Colors.blue),
                            title: Text('${car.brand} ${car.model} - ${DateFormat('dd.MM.yyyy').format(entry.date)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Kilometerstand: ${entry.mileage} km | Getankt: ${entry.liters} L (${entry.price} €)'),
                            trailing: entry.isIntermediate ? const Chip(label: Text('Zwischentank')) : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Einstellungen für Speicherort
class SettingsScreen extends StatefulWidget {
  final VoidCallback onPathChanged;
  const SettingsScreen({super.key, required this.onPathChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String currentPath = '';

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    String path = await StorageService.getSavePath();
    setState(() {
      currentPath = path;
    });
  }

  Future<void> _pickDirectory() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_storage_path', selectedDirectory);
      setState(() {
        currentPath = selectedDirectory;
      });
      widget.onPathChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speicherort erfolgreich geändert!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen - Speicherort')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Aktueller Speicherort der JSON-Daten:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(currentPath, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Anderen Speicherort wählen', style: TextStyle(fontSize: 16)),
                onPressed: _pickDirectory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Auto-Verwaltung Screen
class CarManageScreen extends StatefulWidget {
  final List<Car> cars;
  final VoidCallback onCarChanged;
  const CarManageScreen({super.key, required this.cars, required this.onCarChanged});

  @override
  State<CarManageScreen> createState() => _CarManageScreenState();
}

class _CarManageScreenState extends State<CarManageScreen> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();

  void _addCar() {
    if (_brandController.text.isEmpty || _modelController.text.isEmpty) return;
    setState(() {
      widget.cars.add(Car(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: _brandController.text,
        model: _modelController.text,
        iconName: 'default',
      ));
      _brandController.clear();
      _modelController.clear();
    });
    widget.onCarChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autos verwalten')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Automarke (z.B. VW, BMW)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Modell (z.B. Golf, 3er)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addCar,
                child: const Text('Auto hinzufügen', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cars.length,
                itemBuilder: (context, index) {
                  final car = widget.cars[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_car, size: 32, color: Colors.blue),
                      title: Text('${car.brand} ${car.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            widget.cars.removeAt(index);
                          });
                          widget.onCarChanged();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tankvorgang erfassen Screen
class AddEntryScreen extends StatefulWidget {
  final List<Car> cars;
  const AddEntryScreen({super.key, required this.cars});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  Car? selectedCar;
  DateTime selectedDate = DateTime.now();
  final _mileageController = TextEditingController();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _canisterController = TextEditingController(text: '0');
  bool isIntermediate = false;

  @override
  void initState() {
    super.initState();
    if (widget.cars.isNotEmpty) selectedCar = widget.cars.first;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveEntry() async {
    if (selectedCar == null || _mileageController.text.isEmpty || _litersController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte alle Pflichtfelder ausfüllen!')));
      return;
    }

    final entry = RefuelEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      carId: selectedCar!.id,
      date: selectedDate,
      mileage: double.parse(_mileageController.text),
      liters: double.parse(_litersController.text),
      price: double.tryParse(_priceController.text) ?? 0.0,
      canisterLiters: double.tryParse(_canisterController.text) ?? 0.0,
      isIntermediate: isIntermediate,
    );

    final data = await StorageService.loadData();
    List<RefuelEntry> entries = data['entries'];
    entries.add(entry);
    await StorageService.saveData(data['cars'], entries);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tankvorgang erfassen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Car>(
              value: selectedCar,
              decoration: const InputDecoration(labelText: 'Auto auswählen', border: OutlineInputBorder()),
              items: widget.cars.map((car) {
                return DropdownMenuItem(
                  value: car,
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text('${car.brand} ${car.model}', style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedCar = val),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Datum', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd.MM.yyyy').format(selectedDate), style: const TextStyle(fontSize: 18)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mileageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Gesamtkilometerstand (km)', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _litersController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Getankte Liter gesamt (Säule)', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bezahlter Gesamtpreis (€)', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _canisterController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Nicht ins Auto getankt (z.B. Kanister in Liter)', border: OutlineInputBorder()),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Zwischentankung (kein kompletter Tankzyklus, Verbrauch pausiert)', style: TextStyle(fontSize: 16)),
              value: isIntermediate,
              onChanged: (val) => setState(() => isIntermediate = val ?? false),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                onPressed: _saveEntry,
                child: const Text('Speichern', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}