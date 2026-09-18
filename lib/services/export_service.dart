import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';

class ExportService {
  final StorageService _storage = StorageService();

  /// Exporta todos los productos como JSON y abre el diálogo de compartir.
  /// Devuelve true si se exportó correctamente.
  Future<bool> exportarProductos() async {
    try {
      final productos = await _storage.obtenerProductos();

      if (productos.isEmpty) {
        return false;
      }

      final jsonList = productos.map((p) => p.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

      // Nombre con fecha para que no se sobrescriba
      final fecha = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final nombreArchivo = 'productos_$fecha.json';

      if (kIsWeb) {
        // En web usamos share_plus directamente con texto
        await Share.share(jsonString, subject: nombreArchivo);
      } else {
        // En móvil guardamos el archivo y lo compartimos
        final dir = await getTemporaryDirectory();
        final archivo = File('${dir.path}/$nombreArchivo');
        await archivo.writeAsString(jsonString);

        await Share.shareXFiles([
          XFile(archivo.path, mimeType: 'application/json'),
        ], subject: 'Exportar productos ScanLens');
      }

      return true;
    } catch (e) {
      print('Error al exportar: $e');
      return false;
    }
  }

  /// Devuelve el JSON como string (útil si luego quieres enviarlo a tu web).
  Future<String> obtenerJsonString() async {
    final productos = await _storage.obtenerProductos();
    final jsonList = productos.map((p) => p.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }
}
