import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../engagement/presentation/providers/engagement_provider.dart';

class SavedEventsView extends ConsumerStatefulWidget {
  const SavedEventsView({super.key});

  @override
  ConsumerState<SavedEventsView> createState() => _SavedEventsViewState();
}

class _SavedEventsViewState extends ConsumerState<SavedEventsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(engagementProvider.notifier).fetchSavedEvents());
  }

  @override
  Widget build(BuildContext context) {
    final engagementState = ref.watch(engagementProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Favoritos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: () => ref.read(engagementProvider.notifier).fetchSavedEvents(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (engagementState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (engagementState.savedEvents.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.black, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aún no tienes eventos favoritos.\n¡Ve al catálogo y guarda algunos!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.black.withOpacity(0.5)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: engagementState.savedEvents.length,
              itemBuilder: (context, index) {
                final event = engagementState.savedEvents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        color: AppColors.grey,
                        child: (event.photos.isNotEmpty) 
                          ? Image.network(event.photos.first, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50, color: Colors.black26))
                          : const Icon(Icons.image, size: 50, color: Colors.black26),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ref.read(engagementProvider.notifier).toggleSaved(event),
                                  icon: const Icon(Icons.favorite, color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.startDate.toString().substring(0, 10)} • ${event.location}',
                              style: TextStyle(color: AppColors.black.withOpacity(0.7), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
