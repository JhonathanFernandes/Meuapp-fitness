/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (c) 2026 - 2026 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:wger/features/exercises/models/exercise.dart';
import 'package:wger/features/exercises/widgets/videos.dart';

class VideosSection extends StatelessWidget {
  final Exercise exercise;

  const VideosSection({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final localizedName =
        exercise.getTranslation(Localizations.localeOf(context).languageCode).name;
    final englishName = exercise.getTranslation('en').name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vídeo de execução',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (exercise.videos.isNotEmpty)
            ...exercise.videos.map((video) => ExerciseVideoWidget(video: video))
          else
            _ExerciseDemoPlayer(
              exerciseName: localizedName,
              englishName: englishName,
            ),
          const SizedBox(height: 9),
        ],
      ),
    );
  }
}


class _ExerciseDemoPlayer extends StatefulWidget {
  const _ExerciseDemoPlayer({required this.exerciseName, required this.englishName});

  final String exerciseName;
  final String englishName;

  @override
  State<_ExerciseDemoPlayer> createState() => _ExerciseDemoPlayerState();
}

class _ExerciseDemoPlayerState extends State<_ExerciseDemoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  static const _base = 'https://pub-585d42eb1aa64a67aedf483ec328d3fe.r2.dev/exercise-videos/male/';
  static const _videos = <String, String>{
    'flexão inclinada': 'push-ups.mp4',
    'incline push up': 'push-ups.mp4',
    'incline push-up': 'push-ups.mp4',
    'supino na máquina': 'barbell-bench-press.mp4',
    'chest press': 'barbell-bench-press.mp4',
    'bench press': 'barbell-bench-press.mp4',
    'desenvolvimento na máquina': 'dumbbell-lateral-raise.mp4',
    'shoulder press': 'dumbbell-lateral-raise.mp4',
    'ponte de glúteos': 'glute-bridge.mp4',
    'glute bridge': 'glute-bridge.mp4',
    'elevação pélvica': 'hip-thrust.mp4',
    'hip thrust': 'hip-thrust.mp4',
    'mesa flexora': 'lying-leg-curl.mp4',
    'lying leg curl': 'lying-leg-curl.mp4',
    'leg press': 'leg-press.mp4',
    'prancha': 'plank.mp4',
    'plank': 'plank.mp4',
    'bird dog': 'bird-dog.mp4',
    'remada sentada': 'seated-cable-row.mp4',
    'seated cable row': 'seated-cable-row.mp4',
    'remada com elástico': 'seated-cable-row.mp4',
    'desenvolvimento com elástico': 'shoulder-press.mp4',
    'levantamento terra com mochila': 'deadlift.mp4',
    'deadlift': 'deadlift.mp4',
    'agachamento até uma cadeira': 'bodyweight-squat.mp4',
    'bodyweight squat': 'bodyweight-squat.mp4',
  };

  @override
  void initState() {
    super.initState();
    final filename = _videos[widget.exerciseName.toLowerCase()] ??
        _videos[widget.englishName.toLowerCase()];
    if (filename == null) {
      _failed = true;
      return;
    }
    _controller = VideoPlayerController.networkUrl(Uri.parse('$_base$filename'));
    _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller == null) {
      return const Text(
        'Ainda não há uma demonstração em vídeo disponível para este exercício.',
      );
    }
    if (!controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          Row(
            children: [
              IconButton(
                tooltip: controller.value.isPlaying ? 'Pausar vídeo' : 'Reproduzir vídeo',
                onPressed: () => setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                }),
                icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              Expanded(
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
