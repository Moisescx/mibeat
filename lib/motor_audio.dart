import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MotorAudio extends BaseAudioHandler with QueueHandler, SeekHandler {
  // 1. Creamos la variable del ecualizador
  final AndroidEqualizer ecualizador = AndroidEqualizer();

  // 2. Ponemos 'late final' para que el reproductor espere a ser construido en el MotorAudio()
  late final AudioPlayer reproductor;

  MotorAudio() {
    // 3. Inicializamos el reproductor conectándole la "tubería" (AudioPipeline) con el ecualizador
    reproductor = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [ecualizador]),
    );

    // --- DE AQUÍ EN ADELANTE, TU CÓDIGO SIGUE EXACTAMENTE IGUAL ---
    reproductor.playbackEventStream.listen(_notificarEstadoAlSistema);

    reproductor.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  void _notificarEstadoAlSistema(PlaybackEvent event) {
    final playing = reproductor.playing;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],

        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[reproductor.processingState]!,
        playing: playing,
        updatePosition: reproductor.position,
        bufferedPosition: reproductor.bufferedPosition,
        speed: reproductor.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() => reproductor.play();

  @override
  Future<void> pause() => reproductor.pause();

  @override
  Future<void> skipToNext() => reproductor.seekToNext();

  @override
  Future<void> skipToPrevious() => reproductor.seekToPrevious();

  @override
  Future<void> stop() async {
    await reproductor.stop();
    return super.stop();
  }
}
