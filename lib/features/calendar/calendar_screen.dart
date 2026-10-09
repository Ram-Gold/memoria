import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPolaroids = ref.watch(polaroidsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria Calendar'),
      ),
      body: asyncPolaroids.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (polaroids) {
          if (polaroids.isEmpty) {
            return const Center(child: Text('No exposures recorded on the calendar yet.'));
          }

          // Group by date YYYY-MM-DD
          final Map<String, int> counts = {};
          for (final p in polaroids) {
            final dateKey = p.createdAt.toIso8601String().split('T')[0];
            counts[dateKey] = (counts[dateKey] ?? 0) + 1;
          }

          final dates = counts.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final count = counts[date] ?? 0;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(date),
                  subtitle: Text('$count exposure(s) recorded'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
