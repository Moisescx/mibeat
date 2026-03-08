import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../motor_audio.dart';
import '../main.dart';

class PantallaEcualizador extends StatefulWidget {
  const PantallaEcualizador({super.key});

  @override
  State<PantallaEcualizador> createState() => _PantallaEcualizadorState();
}

class _PantallaEcualizadorState extends State<PantallaEcualizador> {
  bool _activado = false;

  late final AndroidEqualizer _ecualizador;

  @override
  void initState() {
    super.initState();
    _ecualizador = (motorAudioGlobal as MotorAudio).ecualizador;
    _activado = _ecualizador.enabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        title: const Text(
          'Ecualizador',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Switch(
              value: _activado,
              activeColor: Colors.greenAccent,
              onChanged: (valor) async {
                await _ecualizador.setEnabled(valor);
                setState(() {
                  _activado = valor;
                });
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<AndroidEqualizerParameters>(
        future: _ecualizador.parameters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "Tu dispositivo no soporta este ecualizador",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final parametros = snapshot.data!;

          return Column(
            children: [
              const SizedBox(height: 20),
              Text(
                _activado ? "Modificando frecuencias" : "Ecualizador apagado",
                style: TextStyle(
                  color: _activado ? Colors.greenAccent : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // --- DIBUJAMOS LAS BANDAS VERTICALES ---
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: parametros.bands.map((banda) {
                    return _BandaEcualizador(
                      banda: banda,
                      minDb: parametros.minDecibels,
                      maxDb: parametros.maxDecibels,
                      activado: _activado,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- WIDGET SECUNDARIO PARA CADA BARRA ---
class _BandaEcualizador extends StatefulWidget {
  final AndroidEqualizerBand banda;
  final double minDb;
  final double maxDb;
  final bool activado;

  const _BandaEcualizador({
    required this.banda,
    required this.minDb,
    required this.maxDb,
    required this.activado,
  });

  @override
  State<_BandaEcualizador> createState() => _BandaEcualizadorState();
}

class _BandaEcualizadorState extends State<_BandaEcualizador> {
  late double _valorActual;

  @override
  void initState() {
    super.initState();
    _valorActual = widget.banda.gain;
  }

  // Función sencilla para traducir los Hz a palabras humanas
  String _obtenerCategoria(double freq) {
    if (freq < 150) return "Bajos"; // Ej: 60 Hz (El retumbar profundo)
    if (freq < 500) return "M. Bajos"; // Ej: 230 Hz (El golpe de la batería)
    if (freq < 2000) return "Medios"; // Ej: 910 Hz (Las voces y guitarras)
    if (freq < 6000) return "Agudos"; // Ej: 3.6 kHz (La claridad y platillos)
    return "Brillo"; // Ej: 14.0 kHz (El aire o siseo final)
  }

  @override
  Widget build(BuildContext context) {
    double freq = widget.banda.centerFrequency;
    String nombreFrecuencia = freq >= 1000
        ? "${(freq / 1000).toStringAsFixed(1)}k"
        : "${freq.toInt()}";

    String categoria = _obtenerCategoria(freq);

    return Column(
      children: [
        // --- TEXTO AMIGABLE (Ej. "Bajos") ---
        Text(
          categoria,
          style: TextStyle(
            color: widget.activado ? Colors.greenAccent : Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0,
                ),
                activeTrackColor: widget.activado
                    ? Colors.greenAccent
                    : Colors.grey[700],
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: widget.activado ? Colors.white : Colors.grey,
              ),
              child: Slider(
                min: widget.minDb,
                max: widget.maxDb,
                value: _valorActual,
                onChanged: widget.activado
                    ? (valor) {
                        setState(() => _valorActual = valor);
                        widget.banda.setGain(valor);
                      }
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        // --- TEXTO TÉCNICO SUTIL (Ej. "60 Hz") ---
        Text(
          nombreFrecuencia,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10, // Más pequeño para que no robe atención
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
