import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:text_scroll/text_scroll.dart';
import 'progress_bar.dart';

class PlayerSheet extends StatefulWidget {
  final SongModel cancionMostrar;
  final AudioPlayer reproductor;
  final ValueNotifier<List<Color>> coloresFondo;
  // final ValueNotifier<bool> viendoLetra; // SUSPENDIDO
  // final ValueNotifier<String> letraActual; // SUSPENDIDO
  final ValueNotifier<List<String>> notificadorFavoritos;
  final int indiceActual;
  final Function(SongModel) onAgregarAPlaylist;

  const PlayerSheet({
    super.key,
    required this.cancionMostrar,
    required this.reproductor,
    required this.coloresFondo,
    // required this.viendoLetra, // SUSPENDIDO
    // required this.letraActual, // SUSPENDIDO
    required this.notificadorFavoritos,
    required this.indiceActual,
    required this.onAgregarAPlaylist,
  });

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Color>>(
      valueListenable: widget.coloresFondo,
      builder: (context, colores, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colores,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _buildPlayerView(),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 45,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildPlayerView() {
    return Column(
      children: [
        _buildDragHandle(),
        const SizedBox(height: 20),
        const Spacer(),
        _buildArtwork(),
        const Spacer(),
        _buildSongInfo(),
        const SizedBox(height: 10),
        BarraDeProgreso(
          reproductor: widget.reproductor,
          coloresFondo: widget.coloresFondo,
        ),
        const SizedBox(height: 10),
        _buildControlButtons(),
        const Spacer(),
      ],
    );
  }

  // --- MÉTODOS DE LETRAS (SUSPENDIDOS) ---
  /*
  Widget _buildTabSelector() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.viendoLetra,
      builder: (context, viendo, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton("Canción", !viendo, () => widget.viendoLetra.value = false),
              _buildTabButton("Letras", viendo, () => widget.viendoLetra.value = true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildArtworkOrLyrics() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.viendoLetra,
      builder: (context, viendo, child) {
        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 500),
          crossFadeState: viendo ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: _buildArtwork(),
          secondChild: _buildLyrics(),
        );
      },
    );
  }
  */

  Widget _buildArtwork() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: QueryArtworkWidget(
          key: ValueKey(widget.cancionMostrar.id),
          keepOldArtwork: true,
          id: widget.cancionMostrar.id,
          type: ArtworkType.AUDIO,
          artworkWidth: MediaQuery.of(context).size.width * 0.8,
          artworkHeight: MediaQuery.of(context).size.width * 0.8,
          artworkBorder: BorderRadius.zero,
          size: 1000,
          quality: 100,
          nullArtworkWidget: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            color: Colors.grey[900],
            child: const Icon(Icons.music_note, size: 100, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // --- MÉTODO DE LETRAS (SUSPENDIDO) ---
  /*
  Widget _buildLyrics() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ValueListenableBuilder<String>(
          valueListenable: widget.letraActual,
          builder: (context, letra, child) {
            return Text(
              letra,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      ),
    );
  }
  */

  Widget _buildSongInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFavoriteButton(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                TextScroll(
                  widget.cancionMostrar.title,
                  mode: TextScrollMode.bouncing,
                  velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
                  delayBefore: const Duration(seconds: 3),
                  pauseBetween: const Duration(seconds: 10),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                TextScroll(
                  widget.cancionMostrar.artist ?? "Artista desconocido",
                  mode: TextScrollMode.bouncing,
                  velocity: const Velocity(pixelsPerSecond: Offset(15, 0)),
                  delayBefore: const Duration(seconds: 3),
                  pauseBetween: const Duration(seconds: 10),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add_rounded),
          color: Colors.white70,
          iconSize: 30,
          onPressed: () {
            Navigator.pop(context);
            widget.onAgregarAPlaylist(widget.cancionMostrar);
          },
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: widget.notificadorFavoritos,
      builder: (context, listaFavoritos, child) {
        String idActual = widget.cancionMostrar.id.toString();
        bool esFavorita = listaFavoritos.contains(idActual);

        return IconButton(
          icon: Icon(
            esFavorita ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
          color: esFavorita ? Colors.greenAccent : Colors.white70,
          iconSize: 28,
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            List<String> nuevaLista = List.from(listaFavoritos);

            if (esFavorita) {
              nuevaLista.remove(idActual);
            } else {
              nuevaLista.add(idActual);
            }
            widget.notificadorFavoritos.value = nuevaLista;
            await prefs.setStringList('mis_favoritas', nuevaLista);
          },
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShuffleButton(),
              _buildPreviousButton(),
              _buildPlayPauseButton(),
              _buildNextButton(),
              _buildLoopButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShuffleButton() {
    return StreamBuilder<bool>(
      stream: widget.reproductor.shuffleModeEnabledStream,
      builder: (context, snapshot) {
        final isShuffle = snapshot.data ?? false;
        return IconButton(
          icon: const Icon(Icons.shuffle_rounded),
          iconSize: 24,
          color: isShuffle ? Colors.greenAccent : Colors.white54,
          onPressed: () async {
            final enable = !isShuffle;
            if (enable) await widget.reproductor.shuffle();
            await widget.reproductor.setShuffleModeEnabled(enable);
          },
        );
      },
    );
  }

  Widget _buildPreviousButton() {
    return IconButton(
      icon: const Icon(Icons.skip_previous_rounded),
      iconSize: 36,
      color: Colors.white,
      onPressed: () {
        if (widget.reproductor.processingState == ProcessingState.idle) {
          // Implementar lógica de anterior
        } else if (widget.reproductor.hasPrevious) {
          widget.reproductor.seekToPrevious();
        }
      },
    );
  }

  Widget _buildPlayPauseButton() {
    return StreamBuilder<bool>(
      stream: widget.reproductor.playingStream,
      builder: (context, snapshot) {
        bool isPlaying = snapshot.data ?? false;

        return ValueListenableBuilder<List<Color>>(
          valueListenable: widget.coloresFondo,
          builder: (context, colores, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: colores[0].withValues(alpha: 0.6),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                padding: const EdgeInsets.all(18),
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                iconSize: 38,
                color: Colors.black,
                onPressed: () {
                  if (isPlaying) {
                    widget.reproductor.pause();
                  } else {
                    if (widget.reproductor.processingState == ProcessingState.idle) {
                      // Implementar lógica de reproducción
                    } else {
                      widget.reproductor.play();
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNextButton() {
    return IconButton(
      icon: const Icon(Icons.skip_next_rounded),
      iconSize: 36,
      color: Colors.white,
      onPressed: () {
        if (widget.reproductor.processingState == ProcessingState.idle) {
          // Implementar lógica de siguiente
        } else if (widget.reproductor.hasNext) {
          widget.reproductor.seekToNext();
        }
      },
    );
  }

  Widget _buildLoopButton() {
    return StreamBuilder<LoopMode>(
      stream: widget.reproductor.loopModeStream,
      builder: (context, snapshot) {
        final loopMode = snapshot.data ?? LoopMode.off;
        IconData icon = Icons.repeat_rounded;
        Color color = Colors.white54;

        if (loopMode == LoopMode.all) {
          color = Colors.greenAccent;
        } else if (loopMode == LoopMode.one) {
          icon = Icons.repeat_one_rounded;
          color = Colors.greenAccent;
        }

        return IconButton(
          icon: Icon(icon, color: color),
          iconSize: 24,
          onPressed: () async {
            if (loopMode == LoopMode.off) {
              await widget.reproductor.setLoopMode(LoopMode.all);
            } else if (loopMode == LoopMode.all) {
              await widget.reproductor.setLoopMode(LoopMode.one);
            } else {
              await widget.reproductor.setLoopMode(LoopMode.off);
            }
          },
        );
      },
    );
  }
}
