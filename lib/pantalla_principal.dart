import 'dart:async';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'pantalla_ajustes.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final ValueNotifier<int> _notificadorIndice = ValueNotifier(-1);
  List<SongModel> _listaCanciones = [];
  StreamSubscription<PlayerState>? _playerStateSub;
  String _textoBusqueda = "";

  List<String> _misPlaylists = [];

  bool _tienePermiso = false;
  late Future<List<SongModel>> _cancionesFuture;

  @override
  void initState() {
    super.initState();
    _pedirPermisos();
    _cargarPlaylists();
    _playerStateSub = _reproductor.playerStateStream.listen((estado) {
      if (estado.processingState == ProcessingState.completed) {
        _reproducirCancion(_indiceActual + 1);
      }
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _reproductor.dispose();
    _notificadorIndice.dispose();
    super.dispose();
  }

  // NUEVO: Cargar las playlists desde la memoria interna
  Future<void> _cargarPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Busca la lista guardada. Si no hay nada (es la primera vez), devuelve una lista vacía []
      _misPlaylists = prefs.getStringList('mis_playlists_guardadas') ?? [];
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
        // Poblar la lista de reproducción filtrada cuando la consulta termine,
        // así evitamos mutar el estado directamente dentro del builder de widgets.
        _cancionesFuture
            .then((songs) {
              final filtradas = songs.where((cancion) {
                final duracion = cancion.duration ?? 0;
                final esMusica = cancion.isMusic ?? true;
                final esAlarma = cancion.isAlarm ?? false;
                final esNotificacion = cancion.isNotification ?? false;
                return duracion >= 60000 &&
                    esMusica &&
                    !esAlarma &&
                    !esNotificacion;
              }).toList();
              setState(() {
                _listaCanciones = filtradas;
              });
            })
            .catchError((_) {});
      });
    }
  }

  // Nota: el formateo de tiempo se realiza en `BarraDeProgreso`.

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
        debugPrint("Error al reproducir: $e");
      }
    }
  }

  void _mostrarPantallaReproduccion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ValueListenableBuilder<int>(
          valueListenable: _notificadorIndice,
          builder: (context, indiceActualizado, child) {
            if (indiceActualizado == -1) return const SizedBox.shrink();

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
                          id: cancionMostrar.id,
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
                      cancionMostrar.title,
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
                      cancionMostrar.artist ?? "Artista desconocido",
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

  // --- NUEVA FUNCIÓN: MOSTRAR LAS CANCIONES DE UN ARTISTA ---
  void _mostrarCancionesArtista(BuildContext context, ArtistModel artista) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.7, // Ocupa el 70% de la pantalla
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // La rayita superior para deslizar hacia abajo
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Canciones de ${artista.artist}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 16),

              // Buscamos las canciones específicas de este ID de artista
              Expanded(
                child: FutureBuilder<List<SongModel>>(
                  future: _audioQuery.queryAudiosFrom(
                    AudiosFromType.ARTIST_ID,
                    artista.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay canciones 😅',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    var cancionesDelArtista = snapshot.data!;

                    return ListView.builder(
                      itemCount: cancionesDelArtista.length,
                      itemBuilder: (context, index) {
                        var cancion = cancionesDelArtista[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                          title: Text(
                            cancion.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            // MAGIA PURA: Reemplazamos la fila de reproducción global por la del artista
                            setState(() {
                              _listaCanciones = cancionesDelArtista;
                            });
                            // Reproducimos la canción que tocó
                            _reproducirCancion(index);

                            // Cerramos este menú y abrimos el reproductor gigante automáticamente
                            Navigator.pop(context);
                            _mostrarPantallaReproduccion(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNCIÓN PARA CREAR UN ÁLBUM NUEVO ---
  void _mostrarDialogoCrearAlbum(BuildContext context) {
    TextEditingController controladorNombre = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Nuevo Álbum",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controladorNombre,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Nombre de tu álbum (ej. Rock 90s)",
              hintStyle: TextStyle(color: Colors.grey[600]),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                // OJO: Agregamos "async" aquí
                String nombrePlaylist = controladorNombre.text.trim();
                if (nombrePlaylist.isNotEmpty &&
                    !_misPlaylists.contains(nombrePlaylist)) {
                  // 1. Lo agregamos a la pantalla
                  setState(() {
                    _misPlaylists.add(nombrePlaylist);
                  });

                  // 2. Lo guardamos en el disco duro del celular
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList(
                    'mis_playlists_guardadas',
                    _misPlaylists,
                  );

                  Navigator.pop(context); // Cerramos el diálogo
                }
              },
              child: const Text(
                "Crear",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // NUEVO: Envolvemos toda la pantalla en un controlador de 4 pestañas
    return DefaultTabController(
      length: 4, // El número exacto de pestañas que vamos a tener
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'MiBeat',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
          // --- AQUÍ EMPIEZA EL CARRUSEL SUPERIOR ---
          // --- AQUÍ EMPIEZA EL CARRUSEL SUPERIOR ---
          bottom: const TabBar(
            isScrollable: true,
            // NUEVO 1: Obliga a las pestañas a formarse desde la izquierda
            tabAlignment: TabAlignment.start,
            // NUEVO 2: Le da un pequeño margen de 8 píxeles para que no se estrelle contra el borde izquierdo
            padding: EdgeInsets.only(left: 8),
            indicatorColor: Colors.greenAccent,
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.grey,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Canciones'),
              Tab(text: 'Playlists'),
              Tab(text: 'Artistas'),
              Tab(text: 'Carpetas'),
            ],
          ),
        ),

        // --- AQUÍ ESTÁN LAS 4 PANTALLAS (Una para cada pestaña) ---
        body: TabBarView(
          children: [
            // PESTAÑA 1: TUS CANCIONES (Todo tu código original va aquí adentro)
            !_tienePermiso
                ? const Center(
                    child: Text('Necesito permisos para buscar música 😅'),
                  )
                : FutureBuilder<List<SongModel>>(
                    future: _cancionesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        );
                      }

                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No encontré canciones en tu celular 🎵'),
                        );
                      }

                      // Base de la lista: preferimos la lista ya poblada en estado
                      final listaBase = _listaCanciones.isNotEmpty
                          ? _listaCanciones
                          : snapshot.data!.where((cancion) {
                              final duracion = cancion.duration ?? 0;
                              final esMusica = cancion.isMusic ?? true;
                              final esAlarma = cancion.isAlarm ?? false;
                              final esNotificacion =
                                  cancion.isNotification ?? false;
                              return duracion >= 60000 &&
                                  esMusica &&
                                  !esAlarma &&
                                  !esNotificacion;
                            }).toList();

                      // Filtro de búsqueda (no mutamos el estado aquí)
                      var cancionesFiltradas = listaBase.where((cancion) {
                        return cancion.title.toLowerCase().contains(
                              _textoBusqueda.toLowerCase(),
                            ) ||
                            (cancion.artist?.toLowerCase().contains(
                                  _textoBusqueda.toLowerCase(),
                                ) ??
                                false);
                      }).toList();

                      // La lista de canciones
                      return ListView.builder(
                        itemCount: cancionesFiltradas.isEmpty
                            ? 1
                            : cancionesFiltradas.length + 1,
                        itemBuilder: (context, index) {
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

                          if (cancionesFiltradas.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 40.0),
                              child: Center(
                                child: Text('No encontré esa canción 🕵️‍♂️'),
                              ),
                            );
                          }

                          var cancion = cancionesFiltradas[index - 1];
                          // Buscamos el índice en la listaBase que representa la
                          // lista que se está mostrando/reproduciendo.
                          int indiceOriginal = listaBase.indexOf(cancion);

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: QueryArtworkWidget(
                                    id: cancion.id,
                                    type: ArtworkType.AUDIO,
                                    artworkBorder: BorderRadius.zero,
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
                              title: Text(
                                cancion.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 20,
                                ),
                              ),
                              onTap: () {
                                // Aseguramos que el estado tenga la misma lista
                                // que se muestra antes de reproducir.
                                setState(() {
                                  _listaCanciones = listaBase;
                                });
                                _reproducirCancion(indiceOriginal);
                                _mostrarPantallaReproduccion(context);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),

            // --- PESTAÑA 2: MIS ÁLBUMES PERSONALIZADOS (Playlists) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón para crear un nuevo álbum
                  InkWell(
                    onTap: () {
                      _mostrarDialogoCrearAlbum(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.greenAccent,
                            size: 30,
                          ),
                          SizedBox(width: 16),
                          Text(
                            "Crear nueva playlist",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Mi Colección",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Aquí irán los álbumes guardados (por ahora un mensaje vacío elegante)
                  // --- LA LISTA DE TUS PLAYLISTS ---
                  Expanded(
                    child: _misPlaylists.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.queue_music,
                                  size: 80,
                                  color: Colors.grey[800],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Aún no has creado ninguna playlist",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _misPlaylists.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  title: Text(
                                    _misPlaylists[index],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    // Aquí luego programaremos abrir la playlist para ver sus canciones
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // PESTAÑA 3: ARTISTAS (Espacio en construcción)
            // --- PESTAÑA 3: ARTISTAS (Con alfabeto inteligente) ---
            FutureBuilder<List<ArtistModel>>(
              future: _audioQuery
                  .queryArtists(), // Buscamos a los artistas en el celular
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No encontré artistas 🎤',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // 1. Aquí hacemos la magia de agruparlos
                Map<String, List<ArtistModel>> agrupados = {};
                List<ArtistModel> especiales = [];

                for (var artista in snapshot.data!) {
                  String nombre = artista.artist ?? "Desconocido";
                  if (nombre == "<unknown>") nombre = "Desconocido";

                  String primeraLetra = nombre[0].toUpperCase();

                  // Verificamos si la primera letra es de la A a la Z
                  if (RegExp(r'[A-Z]').hasMatch(primeraLetra)) {
                    // Si la letra no existe en el grupo, la creamos
                    if (!agrupados.containsKey(primeraLetra)) {
                      agrupados[primeraLetra] = [];
                    }
                    agrupados[primeraLetra]!.add(artista);
                  } else {
                    // Si es número o símbolo (ej. "50 Cent" o "$uicideboy$"), va a la lista especial
                    especiales.add(artista);
                  }
                }

                // 2. Extraemos las letras que sí tienen artistas y las ordenamos (A, B, C...)
                List<String> letras = agrupados.keys.toList()..sort();

                // 3. Añadimos el grupo de símbolos y números al final, bajo la etiqueta "#"
                if (especiales.isNotEmpty) {
                  agrupados['#'] = especiales;
                  letras.add('#');
                }

                // 4. Dibujamos la pantalla
                return ListView.builder(
                  itemCount: letras.length,
                  itemBuilder: (context, index) {
                    String letra = letras[index];
                    List<ArtistModel> artistasDeEstaLetra = agrupados[letra]!;

                    // Ordenamos a los artistas alfabéticamente dentro de su propia letra
                    artistasDeEstaLetra.sort(
                      (a, b) => (a.artist ?? "").compareTo(b.artist ?? ""),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- LA LETRA GIGANTE ---
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 24.0,
                            top: 20.0,
                            bottom: 10.0,
                          ),
                          child: Text(
                            letra,
                            style: const TextStyle(
                              fontSize: 32, // Letra muy grande
                              fontWeight: FontWeight.w900,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),

                        // --- LOS ARTISTAS DE ESA LETRA ---
                        ...artistasDeEstaLetra.map((artista) {
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                              left: 16,
                              right: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ), // Borde circular para que parezca "perfil"
                                child: SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: QueryArtworkWidget(
                                    id: artista.id,
                                    type: ArtworkType.ARTIST,
                                    artworkBorder: BorderRadius.zero,
                                    nullArtworkWidget: Container(
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                artista.artist ?? "Desconocido",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "${artista.numberOfTracks} canciones", // Muestra cuántas canciones tiene
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                              onTap: () {
                                // Aquí llamamos al menú de sus canciones (Paso 2)
                                _mostrarCancionesArtista(context, artista);
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),

            // PESTAÑA 4: CARPETAS (Espacio en construcción)
            const Center(
              child: Text(
                '📁 Pantalla de Carpetas\n(Próximamente)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ],
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
                    height: 72,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          // --- LA LÍNEA FINA DE PROGRESO ---
                          StreamBuilder<Duration>(
                            stream: _reproductor.positionStream,
                            builder: (context, snapshot) {
                              final posicion = snapshot.data ?? Duration.zero;
                              final duracion =
                                  _reproductor.duration ??
                                  const Duration(seconds: 1);

                              double progreso =
                                  posicion.inMilliseconds /
                                  duracion.inMilliseconds;
                              if (progreso.isNaN || progreso.isInfinite)
                                progreso = 0.0;
                              if (progreso > 1.0) progreso = 1.0;

                              return LinearProgressIndicator(
                                value: progreso,
                                minHeight: 3,
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

                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
      ),
    );
  }
}

class BarraDeProgreso extends StatefulWidget {
  final AudioPlayer reproductor;
  const BarraDeProgreso({super.key, required this.reproductor});

  @override
  State<BarraDeProgreso> createState() => _BarraDeProgresoState();
}

class _BarraDeProgresoState extends State<BarraDeProgreso> {
  double? _valorArrastre;
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
                _estabaReproduciendo = widget.reproductor.playing;
                widget.reproductor.pause();
                setState(() {
                  _valorArrastre = value;
                });
              },
              onChanged: (value) {
                setState(() {
                  _valorArrastre = value;
                });
              },
              onChangeEnd: (value) async {
                await widget.reproductor.seek(Duration(seconds: value.toInt()));
                if (_estabaReproduciendo) {
                  widget.reproductor.play();
                }
                setState(() {
                  _valorArrastre = null;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
