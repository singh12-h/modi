import 'package:flutter/material.dart';
import 'responsive_helper.dart';

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

  void _deleteMedicine(int index) {
    final medicine = _filteredMedicines[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Medicine'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this medicine?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.medication, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['brand']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          medicine['generic'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Find and remove from the original medicines list
                _medicines.removeWhere((m) => 
                  m['brand'] == medicine['brand'] && 
                  m['generic'] == medicine['generic']);
                _filterMedicines();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('${medicine['brand']} deleted successfully'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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
        builder: (context, setState) {
          ResponsiveHelper.init(context);
          final dialogWidth = ResponsiveHelper.isMobile 
              ? ResponsiveHelper.screenWidth * 0.92 
              : 600.0;
          final dialogPadding = ResponsiveHelper.isMobile ? 16.0 : 24.0;
          
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isMobile ? 12 : 40,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: ResponsiveHelper.screenHeight * 0.85,
              ),
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
                  padding: EdgeInsets.all(dialogPadding),
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
        );
      },
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
    // Count medicines by form type
    int tabletCount = _medicines.where((m) => m['form'] == 'Tablet').length;
    int capsuleCount = _medicines.where((m) => m['form'] == 'Capsule').length;
    int syrupCount = _medicines.where((m) => m['form'] == 'Syrup').length;
    int otherCount = _medicines.length - tabletCount - capsuleCount - syrupCount;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF311B92),
              Color(0xFF4A148C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Top Row with back button and title
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💊 Medicine Database',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Manage your medicine inventory',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C853).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _showAddNewMedicineDialog,
                            icon: const Icon(Icons.add, color: Colors.white, size: 28),
                            tooltip: 'Add Medicine',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Stats Cards Row
                    Row(
                      children: [
                        _buildStatCard('Total', _medicines.length.toString(), Icons.medication, const Color(0xFF7C4DFF)),
                        const SizedBox(width: 10),
                        _buildStatCard('Tablets', tabletCount.toString(), Icons.medication, const Color(0xFFE91E63)),
                        const SizedBox(width: 10),
                        _buildStatCard('Capsules', capsuleCount.toString(), Icons.medication_liquid, const Color(0xFFFF9800)),
                        const SizedBox(width: 10),
                        _buildStatCard('Syrups', syrupCount.toString(), Icons.local_drink, const Color(0xFF2196F3)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Premium Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search medicines...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.search, color: Colors.white, size: 20),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterMedicines();
                                  },
                                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Results Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${_filteredMedicines.length} medicines found',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          const Text('A-Z', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Medicine List - White Container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: _filteredMedicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.medication_outlined, size: 60, color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No Medicines Found',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first medicine',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                          itemCount: _filteredMedicines.length,
                          itemBuilder: (context, index) {
                            var medicine = _filteredMedicines[index];
                            return _buildMedicineCard(medicine, index);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, String> medicine, int index) {
    Color formColor;
    IconData formIcon;
    
    switch (medicine['form']) {
      case 'Tablet':
        formColor = const Color(0xFFE91E63);
        formIcon = Icons.medication;
        break;
      case 'Capsule':
        formColor = const Color(0xFFFF9800);
        formIcon = Icons.medication_liquid;
        break;
      case 'Syrup':
        formColor = const Color(0xFF2196F3);
        formIcon = Icons.local_drink;
        break;
      case 'Injection':
        formColor = const Color(0xFF673AB7);
        formIcon = Icons.vaccines;
        break;
      case 'Drops':
        formColor = const Color(0xFF00BCD4);
        formIcon = Icons.water_drop;
        break;
      default:
        formColor = const Color(0xFF4CAF50);
        formIcon = Icons.healing;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: formColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMedicineDetails(medicine),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [formColor, formColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: formColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(formIcon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                
                // Medicine Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine['brand']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: formColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              medicine['form'] ?? 'Medicine',
                              style: TextStyle(
                                color: formColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              medicine['generic'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
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
                              Icon(Icons.business, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  medicine['manufacturer']!,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => _showAddToRxDialog(medicine['brand']!),
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50), size: 22),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        tooltip: 'Add to Rx',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => _deleteMedicine(index),
                        icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                      ),
                    ),
                  ],
                ),
              ],
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
