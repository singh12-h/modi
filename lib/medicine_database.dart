import 'package:flutter/material.dart';

class MedicineDatabase extends StatefulWidget {
  const MedicineDatabase({super.key});

  @override
  State<MedicineDatabase> createState() => _MedicineDatabaseState();
}

class _MedicineDatabaseState extends State<MedicineDatabase> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _medicines = [
    {
      'brand': 'Tab. Paracetamol 500mg',
      'generic': 'Acetaminophen',
      'manufacturer': 'GlaxoSmithKline',
      'mrName': 'Rajesh Kumar',
      'composition': 'Paracetamol 500mg',
      'form': 'Tablet'
    },
    {
      'brand': 'Cap. Amoxicillin 250mg',
      'generic': 'Amoxicillin',
      'manufacturer': 'Cipla Ltd',
      'mrName': 'Priya Sharma',
      'composition': 'Amoxicillin 250mg',
      'form': 'Capsule'
    },
    {
      'brand': 'Syp. Cough Relief 5ml',
      'generic': 'Dextromethorphan',
      'manufacturer': 'Sun Pharma',
      'mrName': 'Amit Verma',
      'composition': 'Dextromethorphan HBr 10mg/5ml',
      'form': 'Syrup'
    },
  ];
  List<Map<String, String>> _filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    _filteredMedicines = _medicines;
    _searchController.addListener(_filterMedicines);
  }

  void _filterMedicines() {
    setState(() {
      _filteredMedicines = _medicines
          .where((medicine) =>
              medicine['brand']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              medicine['generic']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              (medicine['manufacturer'] != null && medicine['manufacturer']!.toLowerCase().contains(_searchController.text.toLowerCase())))
          .toList();
    });
  }

  void _addToRx(String medicine) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$medicine added to Rx')),
    );
  }

  void _showMedicineDetails(Map<String, String> medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine['brand']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generic: ${medicine['generic']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Manufacturer: ${medicine['manufacturer'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text('MR Name: ${medicine['mrName'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text('Composition: ${medicine['composition'] ?? 'N/A'}'),
            const SizedBox(height: 4),
            Text('Form: ${medicine['form'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            const Text('Common uses: Pain relief, fever reduction'),
            const SizedBox(height: 4),
            const Text('Side effects: Rare, may include nausea'),
            const SizedBox(height: 4),
            const Text('Contraindications: Liver disease'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddNewMedicineDialog() {
    final TextEditingController brandController = TextEditingController();
    final TextEditingController genericController = TextEditingController();
    final TextEditingController manufacturerController = TextEditingController();
    final TextEditingController mrNameController = TextEditingController();
    final TextEditingController compositionController = TextEditingController();
    String selectedForm = 'Tablet';
    final List<String> medicineForm = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Cream', 'Ointment'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 600,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE1BEE7),
                  Color(0xFFF3E5F5),
                  Color(0xFFFFE0F0),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Medicine',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A1B9A),
                                ),
                              ),
                              Text(
                                'Fill in the medicine details',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8E24AA),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Brand Name
                    _buildStyledTextField(
                      controller: brandController,
                      label: 'Brand Name',
                      icon: Icons.label,
                      hint: 'e.g., Tab. Paracetamol 500mg',
                    ),
                    const SizedBox(height: 16),
                    
                    // Generic Name
                    _buildStyledTextField(
                      controller: genericController,
                      label: 'Generic Name',
                      icon: Icons.science,
                      hint: 'e.g., Acetaminophen',
                    ),
                    const SizedBox(height: 16),
                    
                    // Manufacturer
                    _buildStyledTextField(
                      controller: manufacturerController,
                      label: 'Manufacturer',
                      icon: Icons.factory,
                      hint: 'e.g., GlaxoSmithKline',
                    ),
                    const SizedBox(height: 16),
                    
                    // MR Name
                    _buildStyledTextField(
                      controller: mrNameController,
                      label: 'MR Name',
                      icon: Icons.person,
                      hint: 'e.g., Rajesh Kumar',
                    ),
                    const SizedBox(height: 16),
                    
                    // Composition
                    _buildStyledTextField(
                      controller: compositionController,
                      label: 'Composition',
                      icon: Icons.biotech,
                      hint: 'e.g., Paracetamol 500mg',
                    ),
                    const SizedBox(height: 16),
                    
                    // Form Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.medication, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedForm,
                                decoration: const InputDecoration(
                                  labelText: 'Medicine Form',
                                  border: InputBorder.none,
                                  labelStyle: TextStyle(color: Color(0xFF6A1B9A)),
                                ),
                                items: medicineForm.map((form) {
                                  return DropdownMenuItem(
                                    value: form,
                                    child: Text(form),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedForm = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF6A1B9A),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (brandController.text.isNotEmpty && genericController.text.isNotEmpty) {
                                setState(() {
                                  this._medicines.add({
                                    'brand': brandController.text,
                                    'generic': genericController.text,
                                    'manufacturer': manufacturerController.text,
                                    'mrName': mrNameController.text,
                                    'composition': compositionController.text,
                                    'form': selectedForm,
                                  });
                                  _filteredMedicines = _medicines;
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text('${brandController.text} added successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Please fill Brand Name and Generic Name'),
                                      ],
                                    ),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_circle, color: Colors.white),
                            label: const Text(
                              'Add Medicine',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF6A1B9A)),
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  void _showAddToRxDialog(String medicine) {
    String instructions = 'After Food';
    final TextEditingController morningController = TextEditingController(text: '1');
    final TextEditingController afternoonController = TextEditingController(text: '0');
    final TextEditingController nightController = TextEditingController(text: '1');
    final TextEditingController durationController = TextEditingController(text: '5');
    final TextEditingController notesController = TextEditingController();
    final TextEditingController startDateController = TextEditingController(
      text: DateTime.now().toString().split(' ')[0]
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add $medicine to Rx'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    hintText: 'Select start date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        startDateController.text = pickedDate.toString().split(' ')[0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Dosage Pattern:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Morning:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: morningController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Afternoon:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: afternoonController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Night:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: nightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Duration:'),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '5'),
                      ),
                    ),
                    const Text(' Days'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Before Food'),
                      value: 'Before Food',
                      groupValue: instructions,
                      onChanged: (value) => setState(() => instructions = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('After Food'),
                      value: 'After Food',
                      groupValue: instructions,
                      onChanged: (value) => setState(() => instructions = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('With Food'),
                      value: 'With Food',
                      groupValue: instructions,
                      onChanged: (value) => setState(() => instructions = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Empty Stomach'),
                      value: 'Empty Stomach',
                      groupValue: instructions,
                      onChanged: (value) => setState(() => instructions = value!),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Additional Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addToRx(medicine);
                Navigator.pop(context);
              },
              child: const Text('Add to Rx'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Database',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _showAddNewMedicineDialog,
              icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
              tooltip: 'Add New Medicine',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 Search medicines by name, generic, or manufacturer...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 24),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            
            // Header with count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medication, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Available Medicines (${_filteredMedicines.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
            
            // Medicine List
            Expanded(
              child: _filteredMedicines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No medicines found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filteredMedicines.length,
                      itemBuilder: (context, index) {
                        var medicine = _filteredMedicines[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Color(0xFFF3E5F5).withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: medicine['form'] == 'Tablet'
                                      ? [const Color(0xFFD81B60), const Color(0xFF8E24AA)] // Magenta -> Purple
                                      : medicine['form'] == 'Syrup'
                                          ? [const Color(0xFF1976D2), const Color(0xFF64B5F6)] // Blue -> Light Blue
                                          : medicine['form'] == 'Capsule'
                                              ? [const Color(0xFFFFD600), const Color(0xFFFF6D00)] // Yellow -> Orange
                                              : medicine['form'] == 'Injection'
                                                  ? [const Color(0xFF303F9F), const Color(0xFF7986CB)] // Indigo -> Blue
                                                  : [const Color(0xFF0288D1), const Color(0xFF26C6DA)], // Cyan -> Teal
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (medicine['form'] == 'Tablet'
                                            ? const Color(0xFFD81B60)
                                            : medicine['form'] == 'Syrup'
                                                ? const Color(0xFF1976D2)
                                                : medicine['form'] == 'Capsule'
                                                    ? const Color(0xFFFFD600)
                                                    : medicine['form'] == 'Injection'
                                                        ? const Color(0xFF303F9F)
                                                        : const Color(0xFF0288D1))
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                medicine['form'] == 'Tablet'
                                    ? Icons.medication
                                    : medicine['form'] == 'Syrup'
                                        ? Icons.local_drink
                                        : medicine['form'] == 'Capsule'
                                            ? Icons.medication_liquid
                                            : medicine['form'] == 'Injection'
                                                ? Icons.vaccines
                                                : medicine['form'] == 'Drops'
                                                    ? Icons.water_drop
                                                    : medicine['form'] == 'Cream' || medicine['form'] == 'Ointment'
                                                        ? Icons.healing
                                                        : Icons.medical_services,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              medicine['brand']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE1BEE7), Color(0xFFF8BBD0)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        medicine['form'] ?? 'Medicine',
                                        style: const TextStyle(
                                          color: Color(0xFF6A1B9A),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        medicine['generic']!,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (medicine['manufacturer'] != null && medicine['manufacturer']!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.factory, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            medicine['manufacturer']!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFBA68C8), Color(0xFFCE93D8)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () => _showMedicineDetails(medicine),
                                    icon: const Icon(Icons.info, color: Colors.white, size: 22),
                                    tooltip: 'Details',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () => _showAddToRxDialog(medicine['brand']!),
                                    icon: const Icon(Icons.add_circle, color: Colors.white, size: 22),
                                    tooltip: 'Add to Rx',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddNewMedicineDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          label: const Text(
            'Add Medicine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
