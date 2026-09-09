import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/event_model.dart';
import '../providers/events_provider.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isPublic = true;
  
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona las fechas de inicio y fin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final event = EventModel(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      quantity: int.tryParse(_quantityController.text) ?? 0,
      category: _categoryController.text.trim(),
      address: _addressController.text.trim(),
      location: _locationController.text.trim(),
      photos: [
        "https://via.placeholder.com/600x400.png?text=Event+Photo"
      ], // Placeholder until you implement photo upload
      startDate: _startDate!,
      endDate: _endDate!,
      isPublic: _isPublic,
    );

    final success = await ref.read(eventsProvider.notifier).createEvent(event);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Evento creado exitosamente!'),
          backgroundColor: AppColors.lightGreen,
        ),
      );
      context.pop(); // Return to dashboard
    }
  }
  
  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryYellow, // header background color
              onPrimary: AppColors.black, // header text color
              onSurface: AppColors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context, 
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryYellow,
                onPrimary: AppColors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time != null && mounted) {
        setState(() {
          final dateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startDate = dateTime;
          } else {
            _endDate = dateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);

    ref.listen<EventsState>(eventsProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Crear Evento',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.black),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalles del evento',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Precio', prefixText: 'S/ '),
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Capacidad'),
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Categoría', hintText: 'Ej. Música'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Ciudad / Localidad'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Fechas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.black, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _startDate != null ? _startDate.toString().substring(0, 16) : 'Inicio',
                          style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.black, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _endDate != null ? _endDate.toString().substring(0, 16) : 'Fin',
                          style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                SwitchListTile(
                  title: const Text('Evento Público', style: TextStyle(fontWeight: FontWeight.w700)),
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                  activeColor: AppColors.primaryYellow,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: eventsState.isSubmitting ? null : _submit,
                    child: eventsState.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                          )
                        : const Text('Crear Evento'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
