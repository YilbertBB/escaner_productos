import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart';

class OpenFoodFactsService {
  static const String _baseUrl =
      'https://world.openfoodfacts.org/api/v0/product';

  /// Busca un producto por su código de barras.
  /// Devuelve null si no existe o si hay error de red.
  Future<Producto?> buscarProducto(String codigo) async {
    try {
      final url = Uri.parse('$_baseUrl/$codigo.json');
      final response = await http.get(
        url,
        headers: {
          // Open Food Facts pide un User-Agent identificable
          'User-Agent': 'ScanLens/1.0 (contacto@tudominio.com)',
        },
      );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      // status == 1 significa que el producto existe
      if (data['status'] == 1 && data['product'] != null) {
        return Producto.fromOpenFoodFacts(codigo, data['product']);
      }

      return null;
    } catch (e) {
      print('Error al buscar producto $codigo: $e');
      return null;
    }
  }

  // En tu OpenFoodFactsService existente, agrega:

Future<Producto?> buscarProductoEnBeautyFacts(String codigo) async {
  return _buscarEnOpenFacts(
    codigo, 
    'https://world.openbeautyfacts.org/api/v0/product'
  );
}

Future<Producto?> buscarProductoEnProductsFacts(String codigo) async {
  return _buscarEnOpenFacts(
    codigo, 
    'https://world.openproductsfacts.org/api/v0/product'
  );
}

// Método genérico interno
Future<Producto?> _buscarEnOpenFacts(String codigo, String baseUrl) async {
  try {
    final url = Uri.parse('$baseUrl/$codigo.json');
    final response = await http.get(url, headers: {
      'User-Agent': 'ScanLens/1.0 (contacto@tudominio.com)',
    });
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body);
    if (data['status'] == 1 && data['product'] != null) {
      return Producto.fromOpenFoodFacts(codigo, data['product']);
    }
    return null;
  } catch (e) {
    return null;
  }
}
}
