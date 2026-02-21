import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'pantalla_ajustes.dart';
import 'package:text_scroll/text_scroll.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _reproductor = AudioPlayer();

  SongModel? _cancionActual;
  int _indiceActual = -1;
  // NUEVO: Este notificador le gritará a la pantalla gigante cuando cambiemos de canción
  final ValueNotifier<int> _notificadorIndice = ValueNotifier(-1);
  List<SongModel> _listaCanciones = [];
  // NUEVO: Guarda lo que el usuario escribe en la lupa
  String _textoBusqueda = "";

  bool _tienePermiso = false;
  late Future<List<SongModel>> _cancionesFuture;

  @override
  void initState() {
    super.initState();
    _pedirPermisos();

    // NUEVO: El Vigilante que escucha cuándo termina la canción
    _reproductor.playerStateStream.listen((estado) {
      // Si el estado del reproductor es "completado" (llegó al final)
      if (estado.processingState == ProcessingState.completed) {
        // Pasamos automáticamente a la siguiente canción
        _reproducirCancion(_indiceActual + 1);
      }
    });
  }

  Future<void> _pedirPermisos() async {
    PermissionStatus statusStorage = await Permission.storage.request();
    PermissionStatus statusAudio = await Permission.audio.request();

    if (statusStorage.isGranted || statusAudio.isGranted) {
      setState(() {
        _tienePermiso = true;
        _cancionesFuture = _audioQuery.querySongs(
          ignoreCase: true,
          orderType: OrderType.ASC_OR_SMALLER,
          sortType: null,
          uriType: UriType.EXTERNAL,
        );
      });
    }
  }

  String _formatearTiempo(Duration duracion) {
    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    String minutos = dosDigitos(duracion.inMinutes.remainder(60));
    String segundos = dosDigitos(duracion.inSeconds.remainder(60));
    return "$minutos:$segundos";
  }

  void _reproducirCancion(int index) async {
    if (index < 0 || index >= _listaCanciones.length) return;

    var cancion = _listaCanciones[index];

    setState(() {
      _cancionActual = cancion;
      _indiceActual = index;
    });

    _notificadorIndice.value = index;

    if (cancion.uri != null) {
      try {
        await _reproductor.setAudioSource(
          AudioSource.uri(Uri.parse(cancion.uri!)),
        );
        _reproductor.play();
      } catch (e) {
        print("Error al reproducir: $e");
      }
    }
  }

  // --- LA NUEVA PANTALLA GIGANTE PREMIUM ---
  void _mostrarPantallaReproduccion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Envolvemos todo en el escuchador que reacciona a nuestro notificador
        return ValueListenableBuilder<int>(
          valueListenable: _notificadorIndice,
          builder: (context, indiceActualizado, child) {
            // Si por alguna razón el índice es -1, no dibujamos nada
            if (indiceActualizado == -1) return const SizedBox.shrink();

            // Obtenemos la canción correcta basándonos en el nuevo índice en tiempo real
            var cancionMostrar = _listaCanciones[indiceActualizado];

            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[850]!, Colors.black],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),

                    // --- CARÁTULA FLOTANTE ---
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: QueryArtworkWidget(
                          id: cancionMostrar
                              .id, // ¡Usamos la canción actualizada!
                          type: ArtworkType.AUDIO,
                          artworkWidth: MediaQuery.of(context).size.width * 0.8,
                          artworkHeight:
                              MediaQuery.of(context).size.width * 0.8,
                          artworkBorder: BorderRadius.zero,
                          size: 1000,
                          quality: 100,
                          nullArtworkWidget: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.width * 0.8,
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.music_note,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // --- TÍTULO Y ARTISTA ---
                    TextScroll(
                      cancionMostrar.title, // ¡Usamos la canción actualizada!
                      mode: TextScrollMode.bouncing,
                      velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
                      delayBefore: const Duration(seconds: 3),
                      pauseBetween: const Duration(seconds: 10),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextScroll(
                      cancionMostrar.artist ??
                          "Artista desconocido", // ¡Usamos la canción actualizada!
                      mode: TextScrollMode.bouncing,
                      velocity: const Velocity(pixelsPerSecond: Offset(15, 0)),
                      delayBefore: const Duration(seconds: 3),
                      pauseBetween: const Duration(seconds: 10),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),
                    BarraDeProgreso(reproductor: _reproductor),
                    const SizedBox(height: 20),

                    // --- BOTONES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded),
                          iconSize: 45,
                          color: Colors.white,
                          onPressed: () {
                            _reproducirCancion(indiceActualizado - 1);
                            // ¡Mira mamá, sin Navigator.pop!
                          },
                        ),

                        StreamBuilder<bool>(
                          stream: _reproductor.playingStream,
                          builder: (context, snapshot) {
                            bool isPlaying = snapshot.data ?? false;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                padding: const EdgeInsets.all(16),
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                iconSize: 45,
                                color: Colors.black,
                                onPressed: () {
                                  if (isPlaying) {
                                    _reproductor.pause();
                                  } else {
                                    _reproductor.play();
                                  }
                                },
                              ),
                            );
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 45,
                          color: Colors.white,
                          onPressed: () {
                            _reproducirCancion(indiceActualizado + 1);
                            // ¡Mira mamá, sin Navigator.pop!
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiBeat'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaAjustes(),
                ),
              );
            },
          ),
        ],
      ),

      body: !_tienePermiso
          ? const Center(child: Text('Necesito permisos para buscar música 😅'))
          : FutureBuilder<List<SongModel>>(
              future: _cancionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No encontré canciones en tu celular 🎵'),
                  );
                }

                // 1. Nuestro filtro anti-basura original
                _listaCanciones = snapshot.data!.where((cancion) {
                  final duracion = cancion.duration ?? 0;
                  final esMusica = cancion.isMusic ?? true;
                  final esAlarma = cancion.isAlarm ?? false;
                  final esNotificacion = cancion.isNotification ?? false;

                  return duracion >= 60000 &&
                      esMusica &&
                      !esAlarma &&
                      !esNotificacion;
                }).toList();

                // 2. NUEVO: Filtramos por lo que escribes en el buscador
                var cancionesFiltradas = _listaCanciones.where((cancion) {
                  return cancion.title.toLowerCase().contains(
                        _textoBusqueda.toLowerCase(),
                      ) ||
                      (cancion.artist?.toLowerCase().contains(
                            _textoBusqueda.toLowerCase(),
                          ) ??
                          false);
                }).toList();

                if (_listaCanciones.isEmpty) {
                  return const Center(
                    child: Text('No hay canciones válidas 🎵'),
                  );
                }

                // 3. NUEVO: Envolvemos la lista en una Columna para poner el buscador arriba
                // 3. NUEVO: Metemos el buscador DIRECTAMENTE en la lista
                return ListView.builder(
                  // Sumamos 1 al total para hacerle espacio al buscador en la primera posición
                  itemCount: cancionesFiltradas.isEmpty
                      ? 1
                      : cancionesFiltradas.length + 1,
                  itemBuilder: (context, index) {
                    // Si estamos en la posición 0 (hasta arriba), dibujamos el buscador
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar canción o artista...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                          onChanged: (valor) {
                            setState(() {
                              _textoBusqueda = valor;
                            });
                          },
                        ),
                      );
                    }

                    // Si buscó algo que no existe, mostramos este mensaje debajo del buscador
                    if (cancionesFiltradas.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: Center(
                          child: Text('No encontré esa canción 🕵️‍♂️'),
                        ),
                      );
                    }

                    // Si son canciones reales, restamos 1 al índice porque el buscador ocupó el puesto 0
                    var cancion = cancionesFiltradas[index - 1];
                    int indiceOriginal = _listaCanciones.indexOf(cancion);

                    // --- NUEVO DISEÑO ESTRUCTURAL DE LA CANCIÓN ---
                    return Container(
                      // 1. Espacio entre las tarjetas y los bordes de la pantalla
                      margin: const EdgeInsets.only(
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        // 2. Un fondo sutilmente diferente al fondo de la app
                        color: Colors.grey.withOpacity(0.1),
                        // 3. Esquinas súper redondeadas
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        // Más espacio interno para que la canción respire
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        // --- LA CARÁTULA ---
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Redondeamos la imagen
                          child: SizedBox(
                            width: 55,
                            height: 55,
                            child: QueryArtworkWidget(
                              id: cancion.id,
                              type: ArtworkType.AUDIO,
                              artworkBorder: BorderRadius
                                  .zero, // Quitamos el borde por defecto para usar el nuestro
                              nullArtworkWidget: Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // --- TÍTULO Y ARTISTA ---
                        title: Text(
                          cancion.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, // Título más pesado
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            cancion.artist ?? "Artista desconocido",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),

                        // --- ÍCONO DE PLAY VISUAL ---
                        // Agregamos un pequeño botón a la derecha para invitar al usuario a tocar
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, size: 20),
                        ),

                        // --- LA ACCIÓN AL TOCAR ---
                        onTap: () {
                          _reproducirCancion(indiceOriginal);
                          _mostrarPantallaReproduccion(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),

      // --- EL NUEVO MINI-REPRODUCTOR ESTILO PREMIUM ---
      bottomNavigationBar: _cancionActual == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: GestureDetector(
                onTap: () {
                  _mostrarPantallaReproduccion(context);
                },
                child: Container(
                  height: 72, // Un poquito más alto para que quepa todo bien
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    // MI TOQUE 1: Una sombra suave para que flote de verdad
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // ClipRRect asegura que la barrita de progreso no se salga de las esquinas redondeadas
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        // --- LA LÍNEA FINA DE PROGRESO (Estilo Spotify) ---
                        StreamBuilder<Duration>(
                          stream: _reproductor.positionStream,
                          builder: (context, snapshot) {
                            final posicion = snapshot.data ?? Duration.zero;
                            final duracion =
                                _reproductor.duration ??
                                const Duration(seconds: 1);

                            // Calculamos el porcentaje de la canción
                            double progreso =
                                posicion.inMilliseconds /
                                duracion.inMilliseconds;
                            if (progreso.isNaN || progreso.isInfinite)
                              progreso = 0.0;
                            if (progreso > 1.0) progreso = 1.0;

                            return LinearProgressIndicator(
                              value: progreso,
                              minHeight: 3, // Súper finita
                              backgroundColor: Colors.grey[800],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.greenAccent,
                              ),
                            );
                          },
                        ),

                        // --- EL CONTENIDO DEL REPRODUCTOR ---
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Row(
                              children: [
                                // MI TOQUE 2: La carátula real en miniatura
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 45,
                                    height: 45,
                                    child: QueryArtworkWidget(
                                      id: _cancionActual!.id,
                                      type: ArtworkType.AUDIO,
                                      artworkBorder: BorderRadius.zero,
                                      nullArtworkWidget: Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.music_note,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Título y Artista apilados
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _cancionActual!.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _cancionActual!.artist ??
                                            "Artista desconocido",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // MI TOQUE 3: Botones minimalistas y redondeados
                                StreamBuilder<bool>(
                                  stream: _reproductor.playingStream,
                                  builder: (context, snapshot) {
                                    bool isPlaying = snapshot.data ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                      iconSize: 36,
                                      color: Colors.white,
                                      onPressed: () {
                                        if (isPlaying) {
                                          _reproductor.pause();
                                        } else {
                                          _reproductor.play();
                                        }
                                      },
                                    );
                                  },
                                ),
                                // Dejé solo el botón de "Siguiente" para ahorrar espacio y mantenerlo limpio
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded),
                                  iconSize: 32,
                                  color: Colors.white,
                                  onPressed: () {
                                    _reproducirCancion(_indiceActual + 1);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// NUEVO COMPONENTE: Una barra de progreso inteligente
class BarraDeProgreso extends StatefulWidget {
  final AudioPlayer reproductor;
  const BarraDeProgreso({super.key, required this.reproductor});

  @override
  State<BarraDeProgreso> createState() => _BarraDeProgresoState();
}

class _BarraDeProgresoState extends State<BarraDeProgreso> {
  // Guarda la posición de tu dedo mientras arrastras
  double? _valorArrastre;
  // Recuerda si la canción estaba sonando antes de tocar la barra
  bool _estabaReproduciendo = false;

  String _formatearTiempo(Duration duracion) {
    String dosDigitos(int n) => n.toString().padLeft(2, "0");
    String minutos = dosDigitos(duracion.inMinutes.remainder(60));
    String segundos = dosDigitos(duracion.inSeconds.remainder(60));
    return "$minutos:$segundos";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.reproductor.positionStream,
      builder: (context, snapshot) {
        final posicionActual = snapshot.data ?? Duration.zero;
        final duracionTotal = widget.reproductor.duration ?? Duration.zero;

        // Si estamos arrastrando, mostramos el valor del dedo. Si no, mostramos el de la canción.
        double valorSlider =
            _valorArrastre ?? posicionActual.inSeconds.toDouble();
        double maxSlider = duracionTotal.inSeconds.toDouble();

        if (valorSlider > maxSlider) valorSlider = maxSlider;
        if (maxSlider <= 0) maxSlider = 1;

        return Column(
          children: [
            Slider(
              min: 0.0,
              max: maxSlider,
              value: valorSlider,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.grey[800],
              onChangeStart: (value) {
                // 1. Empezamos a tocar: Pausamos en silencio y tomamos el control
                _estabaReproduciendo = widget.reproductor.playing;
                widget.reproductor.pause();
                setState(() {
                  _valorArrastre = value;
                });
              },
              onChanged: (value) {
                // 2. Arrastrando: Solo actualizamos lo visual
                setState(() {
                  _valorArrastre = value;
                });
              },
              onChangeEnd: (value) async {
                // 3. Soltamos: Saltamos al segundo exacto
                await widget.reproductor.seek(Duration(seconds: value.toInt()));
                // Si estaba sonando antes, le volvemos a dar Play
                if (_estabaReproduciendo) {
                  widget.reproductor.play();
                }
                setState(() {
                  _valorArrastre = null; // Le devolvemos el control a la música
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Muestra el tiempo del arrastre o el tiempo actual
                  Text(
                    _formatearTiempo(Duration(seconds: valorSlider.toInt())),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    _formatearTiempo(duracionTotal),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
