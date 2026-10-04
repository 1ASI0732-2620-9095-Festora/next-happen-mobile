import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        title: const Text('Términos y Condiciones', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const SingleChildScrollView(
          child: Text(
            'Bienvenido a NextHappen. Al utilizar nuestra plataforma, aceptas que '
            'nuestro servicio conecta organizadores de ferias y eventos independientes con asistentes. '
            'Las compras de entradas se procesan de manera segura a través de pasarelas certificadas. '
            'Las cancelaciones y solicitudes de reembolso se rigen por las políticas de cada organizador.',
            style: TextStyle(height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.black,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 2.5),
                  boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(3, 3))],
                ),
                child: Center(
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.fullName ?? 'Usuario NextHappen',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              child: Text(
                user?.role.name.toUpperCase() ?? 'USER',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 28),

            // Card con datos
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.black, width: 2),
                boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.black),
                    title: const Text('Correo Electrónico', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    subtitle: Text(user?.email ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.black),
                    title: const Text('Teléfono', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    subtitle: const Text('No registrado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: AppColors.black),
                    title: const Text('Identificador de Usuario', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    subtitle: Text(user?.id.substring(0, 13) ?? '—', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Opciones
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.black, width: 2),
                boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.black),
                    title: const Text('Términos y Condiciones', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTerms(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Botón de Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.black, width: 2),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
