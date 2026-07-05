/// Lists the career missions with progress bars and rewards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/missions.dart';
import '../state/game_controller.dart';
import '../theme.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch so the list refreshes after a run updates progress.
    ref.watch(gameControllerProvider);
    final views = ref.read(gameControllerProvider.notifier).missionViews;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missionen'),
        backgroundColor: GridColors.background,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: views.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _MissionTile(view: views[i]),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.view});

  final MissionView view;

  @override
  Widget build(BuildContext context) {
    final done = view.completed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? GridColors.placed : GridColors.gridLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  view.mission.description,
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (done)
                const Icon(Icons.check_circle, color: GridColors.placed)
              else
                Text(
                  '🪙 ${view.mission.reward}',
                  style: const TextStyle(color: GridColors.fever, fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: view.fraction,
              minHeight: 8,
              backgroundColor: GridColors.emptyCell,
              valueColor: const AlwaysStoppedAnimation(GridColors.placed),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            done
                ? 'Abgeschlossen'
                : '${view.progress} / ${view.mission.target}',
            style: const TextStyle(color: GridColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
