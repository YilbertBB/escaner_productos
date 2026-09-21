import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart';
import '../models/imagen_producto.dart';

class UpcItemDbService {
  static const String _baseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';

  Future<Producto?> buscarProducto(String codigo) async {
    try {
      final url = Uri.parse('$_baseUrl?upc=$codigo');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return null;

      final item = items.first as Map<String, dynamic>;

      final imagenes = <ImagenProducto>[];
      final images = item['images'] as List<dynamic>?;
      if (images != null) {
        for (var i = 0; i < images.length && i < 3; i++) {
          imagenes.add(ImagenProducto(
            ruta: images[i].toString(),
            esLocal: false,
            rol: i == 0 ? 'frontal' : 'extra',
          ));
        }
      }

      return Producto(
        codigo: codigo,
        nombre: item['title'] ?? 'Sin nombre',
        marca: item['brand'] ?? 'Sin marca',
        imagenes: imagenes,
        ingredientes: item['description'] ?? '',
        categoria: _mapearCategoria(item['category']),
      );
    } catch (e) {
      print('Error en UPCitemdb: $e');
      return null;
    }
  }

  String _mapearCategoria(String? category) {
    if (category == null) return 'otro';
    final c = category.toLowerCase();
    if (c.contains('food') || c.contains('beverage')) return 'alimentos';
    if (c.contains('beauty') || c.contains('cosmetic')) return 'cosmetica';
    if (c.contains('electronic') || c.contains('computer')) return 'electronica';
    if (c.contains('clean')) return 'limpieza';
    if (c.contains('health') || c.contains('pharma')) return 'farmacia';
    return 'otro';
  }
}