import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/user_role.dart';

/// Selector tipo "segmented control" para elegir con qué rol se hace
/// login o registro, siguiendo el mismo lenguaje visual (bordes negros
/// marcados) del panel web.
class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key, required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildOption(context, 'Asistente', UserRole.user),
          _buildOption(context, 'Organizador', UserRole.organizer),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, UserRole role) {
    final isSelected = value == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
