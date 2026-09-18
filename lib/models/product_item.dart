class ProductItem {
  final String id;
  final String name;
  final String brand;
  final String barcode;
  final String category;
  final String categoryLabel;
  final String codeType; // EAN-13, UPC-A, QR-CODE
  final double price;
  final String stockLabel;
  final String timeAgo;
  final String? imageUrl;
  final ProductStatus status;

  const ProductItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.category,
    required this.categoryLabel,
    required this.codeType,
    required this.price,
    required this.stockLabel,
    required this.timeAgo,
    this.imageUrl,
    this.status = ProductStatus.inStock,
  });
}

enum ProductStatus { inStock, lowStock, outOfStock, warranty, nutriscore }

// Datos de ejemplo - cambia esta lista para vaciarla
class DemoData {
  static const List<ProductItem> products = [
    ProductItem(
      id: '1',
      name: 'Jabón Botánico de Lavanda & Oliva',
      brand: 'PureNature Labs',
      barcode: '7791234567890',
      category: 'cosmeticos',
      categoryLabel: 'Cosméticos',
      codeType: 'EAN-13',
      price: 8.50,
      stockLabel: 'En Stock (42 un.)',
      timeAgo: 'Hace 5m',
      status: ProductStatus.inStock,
    ),
    ProductItem(
      id: '2',
      name: 'Granola Crunchy Almendra & Chía 500g',
      brand: 'NaturAlmendras S.L.',
      barcode: '012000045892',
      category: 'alimentos',
      categoryLabel: 'Alimentos',
      codeType: 'UPC-A',
      price: 6.20,
      stockLabel: 'Nutriscore A',
      timeAgo: 'Hoy 10:24',
      status: ProductStatus.nutriscore,
    ),
    ProductItem(
      id: '3',
      name: 'AuraSound Pro ANC Auriculares',
      brand: 'SonicAudio Pro',
      barcode: '8414532098411',
      category: 'electronica',
      categoryLabel: 'Electrónica',
      codeType: 'EAN-13',
      price: 149.00,
      stockLabel: 'Garantía 2 Años',
      timeAgo: 'Ayer 18:40',
      status: ProductStatus.warranty,
    ),
    ProductItem(
      id: '4',
      name: 'Café Origen Huila Geisha 250g',
      brand: 'Andina Roasters',
      barcode: 'SCAN-COF-8842',
      category: 'bebidas',
      categoryLabel: 'Bebidas',
      codeType: 'QR-CODE',
      price: 18.90,
      stockLabel: 'En Stock (18 un.)',
      timeAgo: 'Ayer 11:15',
      status: ProductStatus.inStock,
    ),
  ];

  // MÉTRICAS HUD - pone todo en 0 para el empty state
  static const int totalScans = 34;
  static const int activeProducts = 28;
  static const int totalCategories = 6;
  static const double inventoryValue = 394.00;
  static const String userName = 'Laura';
  static const String terminalId = 'Terminal Óptico #04';
}
