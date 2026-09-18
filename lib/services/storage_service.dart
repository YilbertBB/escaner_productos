import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/producto.dart';

class StorageService {
  static const String _keyProductos = 'productos_guardados';

  /// Guarda la lista completa de productos (sobrescribe).
  Future<void> guardarProductos(List<Producto> productos) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = productos.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProductos, json.encode(jsonList));
  }

  /// Lee todos los productos guardados.
  Future<List<Producto>> obtenerProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProductos);

    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(raw);
      return jsonList
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al leer productos: $e');
      return [];
    }
  }

  /// Agrega un producto nuevo a la lista existente.
  /// Si ya existe uno con el mismo código, lo reemplaza.
  Future<void> agregarProducto(Producto producto) async {
    final productos = await obtenerProductos();

    final index = productos.indexWhere((p) => p.codigo == producto.codigo);
    if (index >= 0) {
      productos[index] = producto; // reemplaza
    } else {
      productos.insert(0, producto); // agrega al inicio
    }

    await guardarProductos(productos);
  }

  /// Elimina un producto por su código.
  Future<void> eliminarProducto(String codigo) async {
    final productos = await obtenerProductos();
    productos.removeWhere((p) => p.codigo == codigo);
    await guardarProductos(productos);
  }

  /// Borra todo (útil para pruebas).
  Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProductos);
  }
}
