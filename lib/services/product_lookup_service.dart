import '../models/producto.dart';
import 'openfoodfacts_service.dart';
import 'upcitemdb_service.dart';

class ProductLookupService {
  final OpenFoodFactsService _foodService = OpenFoodFactsService();
  final UpcItemDbService _upcService = UpcItemDbService();

  Future<Producto?> buscarProducto(String codigo) async {
    // 1. Open Food Facts (alimentos)
    final food = await _foodService.buscarProducto(codigo);
    if (food != null && food.nombre != 'Sin nombre') {
      print('✅ Encontrado en Open Food Facts');
      return food;
    }

    // 2. Open Beauty Facts (cosmética)
    final beauty = await _foodService.buscarProductoEnBeautyFacts(codigo);
    if (beauty != null && beauty.nombre != 'Sin nombre') {
      print('✅ Encontrado en Open Beauty Facts');
      return beauty;
    }

    // 3. Open Products Facts (limpieza, hogar)
    final products = await _foodService.buscarProductoEnProductsFacts(codigo);
    if (products != null && products.nombre != 'Sin nombre') {
      print('✅ Encontrado en Open Products Facts');
      return products;
    }

    // 4. UPCitemdb (cualquier otro producto)
    final upc = await _upcService.buscarProducto(codigo);
    if (upc != null) {
      print('✅ Encontrado en UPCitemdb');
      return upc;
    }

    print('❌ No encontrado en ninguna fuente');
    return null;
  }
}