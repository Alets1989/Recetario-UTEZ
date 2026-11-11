import 'package:flutter/material.dart';

import '../dominio/receta.dart';

class TarjetaReceta extends StatelessWidget {
  const TarjetaReceta({super.key, required this.receta});

  final Receta receta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(receta.nombre, style: tema.titleMedium),
            const SizedBox(height: 4),
            Text('${receta.cocina} · ${receta.dificultad.etiqueta}'),
            Text(
              'Tiempo: ${receta.tiempoTotal} min · '
              'Porciones: ${receta.porciones}',
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Calificación: ${receta.calificacion.toStringAsFixed(1)}'),
                if (receta.esRapida) ...[
                  const SizedBox(width: 8),
                  const Chip(label: Text('Rápida')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
