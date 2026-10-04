import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../providers/organizer_provider.dart';

class TicketValidationScreen extends ConsumerStatefulWidget {
  const TicketValidationScreen({super.key});

  @override
  ConsumerState<TicketValidationScreen> createState() =>
      _TicketValidationScreenState();
}

class _TicketValidationScreenState
    extends ConsumerState<TicketValidationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() async {
      await ref.read(eventsProvider.notifier).fetchOrganizerEvents();
      final events = ref.read(eventsProvider).events;
      if (events.isNotEmpty && mounted) {
        final firstId = events.first.id ?? '';
        setState(() {
          _selectedEventId = firstId;
        });
        if (firstId.isNotEmpty) {
          ref.read(validationProvider.notifier).fetchAttendees(firstId);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleValidation(String code) async {
    if (_isProcessing || code.trim().isEmpty) return;
    setState(() => _isProcessing = true);

    final result = await ref
        .read(validationProvider.notifier)
        .validateTicket(code.trim());

    if (mounted) {
      if (_selectedEventId != null) {
        ref.read(validationProvider.notifier).fetchAttendees(_selectedEventId!);
      }

      showDialog(
        context: context,
        builder: (ctx) {
          final isValid = result != null && result.valid;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.black, width: 2),
            ),
            backgroundColor: isValid ? AppColors.lightGreen : Colors.white,
            title: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? AppColors.black : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  isValid ? '¡Acceso Concedido!' : 'Acceso Denegado',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            content: Text(
              result?.message ??
                  ref.read(validationProvider).errorMessage ??
                  'No se pudo verificar la entrada.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.black, width: 2),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _codeController.clear();
                  setState(() => _isProcessing = false);
                },
                child: const Text('CONTINUAR',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ).then((_) {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final validationState = ref.watch(validationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Control de Acceso / Puerta',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.black,
          indicatorColor: AppColors.primaryYellow,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escanear QR'),
            Tab(icon: Icon(Icons.keyboard), text: 'Manual'),
            Tab(icon: Icon(Icons.list_alt), text: 'Asistentes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Camera QR Scanner
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.black, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) {
                          if (_isProcessing) return;
                          for (final barcode in capture.barcodes) {
                            final raw = barcode.rawValue;
                            if (raw != null && raw.isNotEmpty) {
                              _handleValidation(raw);
                              break;
                            }
                          }
                        },
                      ),
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.primaryYellow, width: 3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.black, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.flash_on,
                                color: AppColors.black),
                            onPressed: () => _scannerController.toggleTorch(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Apunta la cámara hacia el código QR de la entrada del asistente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),

          // 2. Manual Code Input
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingreso manual de entrada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa el código alfanumérico o código corto de la entrada que aparece debajo del QR.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.black.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Código de entrada / ShortCode',
                    hintText: 'Ej. TC-93821',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.black, width: 2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side:
                            const BorderSide(color: AppColors.black, width: 2),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _handleValidation(_codeController.text),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.black,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text(
                      'VALIDAR ENTRADA',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Attendees List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eventsState.events.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.black, width: 2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedEventId,
                        items: eventsState.events.map((event) {
                          return DropdownMenuItem<String>(
                            value: event.id,
                            child: Text(
                              event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedEventId = val);
                            ref
                                .read(validationProvider.notifier)
                                .fetchAttendees(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: validationState.isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.black),
                        )
                      : validationState.attendees.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay entradas registradas para este evento.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            )
                          : ListView.builder(
                              itemCount: validationState.attendees.length,
                              itemBuilder: (context, index) {
                                final attendee =
                                    validationState.attendees[index];
                                final isUsed = attendee.status == 'USED';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.black, width: 1.5),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      'Entrada #${attendee.shortCode}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    subtitle: Text(
                                      'Comprada: ${attendee.purchaseDate.toString().substring(0, 10)}  |  S/ ${attendee.price}',
                                    ),
                                    trailing: isUsed
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'VALIDADA',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 11),
                                            ),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.lightGreen,
                                              foregroundColor: AppColors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                side: const BorderSide(
                                                    color: AppColors.black,
                                                    width: 1.5),
                                              ),
                                            ),
                                            onPressed: () => _handleValidation(
                                                attendee.shortCode),
                                            child: const Text(
                                              'Marcar entrada',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12),
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
