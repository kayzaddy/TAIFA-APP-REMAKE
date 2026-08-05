import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/registry_providers.dart';
import '../domain/registry_application.dart';

class RegistryScreen extends ConsumerStatefulWidget {
  const RegistryScreen({super.key});

  @override
  ConsumerState<RegistryScreen> createState() => _RegistryScreenState();
}

class _RegistryScreenState extends ConsumerState<RegistryScreen> {
  RegistryApplicationType _type = RegistryApplicationType.driver;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};

  TextEditingController _controller(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registryControllerProvider);
    final controller = ref.read(registryControllerProvider.notifier);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('National Mobility Registry'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Register', icon: Icon(Icons.app_registration_rounded)),
              Tab(
                text: 'Applications',
                icon: Icon(Icons.verified_user_rounded),
              ),
            ],
          ),
          actions: [
            if (state.pendingOffline > 0)
              TextButton.icon(
                onPressed: state.loading ? null : controller.synchronize,
                icon: const Icon(Icons.sync_rounded),
                label: Text('${state.pendingOffline} pending'),
              ),
          ],
        ),
        body: Column(
          children: [
            if (state.loading) const LinearProgressIndicator(),
            if (state.message != null)
              _Banner(text: state.message!, color: Colors.green.shade700),
            if (state.error != null)
              _Banner(text: state.error!, color: Colors.red.shade700),
            Expanded(
              child: TabBarView(
                children: [
                  _registrationForm(controller),
                  RefreshIndicator(
                    onRefresh: controller.load,
                    child: _applications(state.applications),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registrationForm(RegistryController controller) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<RegistryApplicationType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Registration type',
              border: OutlineInputBorder(),
            ),
            items: RegistryApplicationType.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_typeLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 16),
          ..._specification(_type).map(
            (field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _controller(field.key),
                keyboardType: field.keyboardType,
                obscureText: field.sensitive,
                decoration: InputDecoration(
                  labelText: field.label,
                  helperText: field.helper,
                  border: const OutlineInputBorder(),
                ),
                validator: field.required
                    ? (value) => (value == null || value.trim().isEmpty)
                          ? '${field.label} is required'
                          : null
                    : null,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final succeeded = await controller.submit(_type, _payload());
              if (succeeded && mounted) {
                for (final field in _fields.values) {
                  field.clear();
                }
                DefaultTabController.of(context).animateTo(1);
              }
            },
            icon: const Icon(Icons.lock_rounded),
            label: const Text('Save registration securely'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sensitive values are encrypted by the registry. Offline forms are '
            'kept in platform secure storage and synchronized automatically.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _applications(List<RegistryApplication> applications) {
    if (applications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.badge_outlined, size: 64),
          SizedBox(height: 12),
          Center(child: Text('No registry applications yet')),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: application.mayOperate
                  ? Colors.green
                  : Colors.orange,
              child: Icon(
                application.mayOperate ? Icons.verified : Icons.hourglass_top,
                color: Colors.white,
              ),
            ),
            title: Text(application.number),
            subtitle: Text(
              '${_typeLabel(application.type)} • ${application.stage}\n'
              '${application.region}, ${application.district}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'document') _uploadDocument(application);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'document',
                  child: ListTile(
                    leading: Icon(Icons.upload_file_rounded),
                    title: Text('Upload document'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadDocument(RegistryApplication application) async {
    final kinds = _documentKinds(application.type);
    var kind = kinds.first;
    final number = TextEditingController();
    final selected = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Secure document upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: kind,
                items: kinds
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => kind = value!),
                decoration: const InputDecoration(labelText: 'Document type'),
              ),
              TextField(
                controller: number,
                decoration: const InputDecoration(labelText: 'Document number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Choose file'),
            ),
          ],
        ),
      ),
    );
    if (selected != true || !mounted) {
      number.dispose();
      return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final path = picked?.files.single.path;
    if (path != null) {
      await ref
          .read(registryControllerProvider.notifier)
          .uploadDocument(
            applicationId: application.id,
            kind: kind,
            filePath: path,
            documentNumber: number.text.trim(),
          );
    }
    number.dispose();
  }

  Map<String, dynamic> _payload() {
    String value(String key) => _controller(key).text.trim();
    final common = {'region': value('region'), 'district': value('district')};
    return switch (_type) {
      RegistryApplicationType.driver => {
        ...common,
        'full_name': value('full_name'),
        'national_id_number': value('national_id_number'),
        'passport_number': value('passport_number'),
        'phone_number': value('phone_number'),
        'email': value('email'),
        'gender': value('gender'),
        'date_of_birth': value('date_of_birth'),
        'nationality': value('nationality'),
        'ward': value('ward'),
        'street': value('street'),
        'postal_address': value('postal_address'),
        'emergency_contact_name': value('emergency_contact_name'),
        'emergency_contact_phone': value('emergency_contact_phone'),
        'preferred_language': value('preferred_language').isEmpty
            ? 'sw'
            : value('preferred_language'),
        'bank_account': value('bank_account'),
      },
      RegistryApplicationType.vehicle => {
        ...common,
        'mode': value('mode'),
        'registration_number': value('registration_number'),
        'chassis_number': value('chassis_number'),
        'engine_number': value('engine_number'),
        'make': value('make'),
        'model': value('model'),
        'year': int.tryParse(value('year')) ?? 0,
        'fuel_type': value('fuel_type'),
        'color': value('color'),
        'capacity': int.tryParse(value('capacity')) ?? 0,
      },
      RegistryApplicationType.station => {
        ...common,
        'name': value('name'),
        'code': value('code'),
        'latitude': value('latitude'),
        'longitude': value('longitude'),
        'ward': value('ward'),
        'street': value('street'),
        'phone_number': value('phone_number'),
        'email': value('email'),
        'operating_hours': {'opens': value('opens'), 'closes': value('closes')},
        'capacity': int.tryParse(value('capacity')) ?? 0,
        'description': value('description'),
      },
      RegistryApplicationType.fleet ||
      RegistryApplicationType.transportCompany => {
        ...common,
        'fleet_type': value('fleet_type'),
        'business_name': value('business_name'),
        'brela_number': value('brela_number'),
        'tin': value('tin'),
        'business_license_number': value('business_license_number'),
        'address': value('address'),
        'declared_fleet_size': int.tryParse(value('declared_fleet_size')) ?? 0,
        'bank_details': value('bank_details'),
      },
    };
  }

  List<_FieldSpec> _specification(RegistryApplicationType type) {
    const common = [
      _FieldSpec('region', 'Region'),
      _FieldSpec('district', 'District'),
    ];
    return switch (type) {
      RegistryApplicationType.driver => const [
        _FieldSpec('full_name', 'Full name'),
        _FieldSpec('national_id_number', 'National ID number', sensitive: true),
        _FieldSpec(
          'passport_number',
          'Passport number (optional)',
          required: false,
          sensitive: true,
        ),
        _FieldSpec(
          'phone_number',
          'Phone number',
          keyboardType: TextInputType.phone,
        ),
        _FieldSpec(
          'email',
          'Email',
          required: false,
          keyboardType: TextInputType.emailAddress,
        ),
        _FieldSpec('gender', 'Gender'),
        _FieldSpec('date_of_birth', 'Date of birth', helper: 'YYYY-MM-DD'),
        _FieldSpec('nationality', 'Nationality'),
        ...common,
        _FieldSpec('ward', 'Ward'),
        _FieldSpec('street', 'Street'),
        _FieldSpec('postal_address', 'Postal address', required: false),
        _FieldSpec('emergency_contact_name', 'Emergency contact'),
        _FieldSpec(
          'emergency_contact_phone',
          'Emergency contact phone',
          keyboardType: TextInputType.phone,
        ),
        _FieldSpec(
          'preferred_language',
          'Preferred language',
          helper: 'sw or en',
        ),
        _FieldSpec(
          'bank_account',
          'Bank account (optional)',
          required: false,
          sensitive: true,
        ),
      ],
      RegistryApplicationType.vehicle => const [
        _FieldSpec(
          'mode',
          'Vehicle type',
          helper: 'motorcycle, bajaji, taxi, van, bus or truck',
        ),
        _FieldSpec('registration_number', 'Registration number'),
        _FieldSpec('chassis_number', 'Chassis number', sensitive: true),
        _FieldSpec('engine_number', 'Engine number', sensitive: true),
        _FieldSpec('make', 'Make'),
        _FieldSpec('model', 'Model'),
        _FieldSpec('year', 'Year', keyboardType: TextInputType.number),
        _FieldSpec('fuel_type', 'Fuel type'),
        _FieldSpec('color', 'Color'),
        _FieldSpec('capacity', 'Capacity', keyboardType: TextInputType.number),
        ...common,
      ],
      RegistryApplicationType.station => const [
        _FieldSpec('name', 'Station name'),
        _FieldSpec('code', 'Station code'),
        _FieldSpec('latitude', 'Latitude', keyboardType: TextInputType.number),
        _FieldSpec(
          'longitude',
          'Longitude',
          keyboardType: TextInputType.number,
        ),
        ...common,
        _FieldSpec('ward', 'Ward'),
        _FieldSpec('street', 'Street'),
        _FieldSpec(
          'phone_number',
          'Phone number',
          keyboardType: TextInputType.phone,
        ),
        _FieldSpec('email', 'Email', required: false),
        _FieldSpec('opens', 'Opens', helper: '06:00'),
        _FieldSpec('closes', 'Closes', helper: '22:00'),
        _FieldSpec('capacity', 'Capacity', keyboardType: TextInputType.number),
        _FieldSpec('description', 'Description', required: false),
      ],
      RegistryApplicationType.fleet ||
      RegistryApplicationType.transportCompany => const [
        _FieldSpec(
          'fleet_type',
          'Fleet type',
          helper:
              'independent, small, corporate, government, rental or business',
        ),
        _FieldSpec('business_name', 'Business name'),
        _FieldSpec(
          'brela_number',
          'BRELA number',
          required: false,
          sensitive: true,
        ),
        _FieldSpec('tin', 'TIN', required: false, sensitive: true),
        _FieldSpec(
          'business_license_number',
          'Business license number',
          required: false,
        ),
        _FieldSpec('address', 'Address'),
        _FieldSpec(
          'declared_fleet_size',
          'Fleet size',
          keyboardType: TextInputType.number,
        ),
        _FieldSpec(
          'bank_details',
          'Bank details (optional)',
          required: false,
          sensitive: true,
        ),
        ...common,
      ],
    };
  }

  List<String> _documentKinds(RegistryApplicationType type) => switch (type) {
    RegistryApplicationType.driver => const [
      'national_id',
      'driving_license',
      'passport_photo',
      'selfie_verification',
      'vehicle_permit',
      'good_conduct',
      'police_clearance',
      'tin_certificate',
      'medical_certificate',
    ],
    RegistryApplicationType.vehicle => const [
      'vehicle_registration_card',
      'road_license',
      'insurance',
      'inspection_certificate',
      'ownership_certificate',
      'emission_certificate',
    ],
    RegistryApplicationType.station => const [
      'local_government_approval',
      'station_registration',
      'leader_identification',
      'station_photo',
    ],
    RegistryApplicationType.fleet => const [
      'business_license',
      'owner_identification',
    ],
    RegistryApplicationType.transportCompany => const [
      'brela_certificate',
      'tin_certificate',
      'business_license',
      'owner_identification',
    ],
  };

  String _typeLabel(RegistryApplicationType type) => switch (type) {
    RegistryApplicationType.driver => 'Driver',
    RegistryApplicationType.vehicle => 'Vehicle',
    RegistryApplicationType.station => 'Transport station',
    RegistryApplicationType.fleet => 'Fleet',
    RegistryApplicationType.transportCompany => 'Transport company',
  };
}

class _FieldSpec {
  const _FieldSpec(
    this.key,
    this.label, {
    this.required = true,
    this.sensitive = false,
    this.keyboardType = TextInputType.text,
    this.helper,
  });

  final String key;
  final String label;
  final bool required;
  final bool sensitive;
  final TextInputType keyboardType;
  final String? helper;
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: color,
    padding: const EdgeInsets.all(10),
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );
}
