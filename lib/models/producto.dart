import 'imagen_producto.dart';

class Producto {
  final String codigo;
  final String nombre;
  final String marca;
  final List<ImagenProducto> imagenes;
  final String ingredientes;
  final String cantidad;
  final String categoria;
  final double precio;
  final String sku;
  final DateTime fechaEscaneo;

  Producto({
    required this.codigo,
    required this.nombre,
    required this.marca,
    this.imagenes = const [],
    this.ingredientes = '',
    this.cantidad = '',
    this.categoria = 'otro',
    this.precio = 0.0,
    this.sku = '',
    DateTime? fechaEscaneo,
  }) : fechaEscaneo = fechaEscaneo ?? DateTime.now();

  // Desde Open Food Facts (puede traer varias imágenes)
  factory Producto.fromOpenFoodFacts(String codigo, Map<String, dynamic> json) {
    final imagenes = <ImagenProducto>[];

    // Imagen frontal principal
    final frontal = json['image_front_url'] ?? json['image_url'];
    if (frontal != null && frontal.toString().isNotEmpty) {
      imagenes.add(
        ImagenProducto(ruta: frontal, esLocal: false, rol: 'frontal'),
      );
    }

    // Imagen trasera
    final reverso =
        json['image_ingredients_url'] ?? json['image_nutrition_url'];
    if (reverso != null && reverso.toString().isNotEmpty) {
      imagenes.add(
        ImagenProducto(ruta: reverso, esLocal: false, rol: 'reverso'),
      );
    }

    // Imágenes adicionales (Open Food Facts puede traer varias)
    final extra = json['images'] as Map<String, dynamic>?;
    if (extra != null) {
      extra.forEach((key, value) {
        if (value is Map && value['url'] != null) {
          imagenes.add(
            ImagenProducto(ruta: value['url'], esLocal: false, rol: 'extra'),
          );
        }
      });
    }

    return Producto(
      codigo: codigo,
      nombre: json['product_name'] ?? 'Sin nombre',
      marca: json['brands'] ?? 'Sin marca',
      imagenes: imagenes,
      ingredientes: json['ingredients_text'] ?? '',
      cantidad: json['quantity'] ?? '',
    );
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      marca: json['marca'] ?? '',
      imagenes: (json['imagenes'] as List<dynamic>? ?? [])
          .map((e) => ImagenProducto.fromJson(e as Map<String, dynamic>))
          .toList(),
      ingredientes: json['ingredientes'] ?? '',
      cantidad: json['cantidad'] ?? '',
      categoria: json['categoria'] ?? 'otro',
      precio: (json['precio'] ?? 0).toDouble(),
      sku: json['sku'] ?? '',
      fechaEscaneo: json['fecha_escaneo'] != null
          ? DateTime.parse(json['fecha_escaneo'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre': nombre,
    'marca': marca,
    'imagenes': imagenes.map((e) => e.toJson()).toList(),
    'ingredientes': ingredientes,
    'cantidad': cantidad,
    'categoria': categoria,
    'precio': precio,
    'sku': sku,
    'fecha_escaneo': fechaEscaneo.toIso8601String(),
  };

  bool get tieneImagenes => imagenes.isNotEmpty;

  // Devuelve la primera imagen (la frontal si existe)
  ImagenProducto? get imagenPrincipal {
    if (imagenes.isEmpty) return null;
    return imagenes.firstWhere(
      (i) => i.rol == 'frontal',
      orElse: () => imagenes.first,
    );
  }

  Producto copyWith({
    String? nombre,
    String? marca,
    List<ImagenProducto>? imagenes,
    String? ingredientes,
    String? cantidad,
    String? categoria,
    double? precio,
    String? sku,
  }) {
    return Producto(
      codigo: codigo,
      nombre: nombre ?? this.nombre,
      marca: marca ?? this.marca,
      imagenes: imagenes ?? this.imagenes,
      ingredientes: ingredientes ?? this.ingredientes,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      sku: sku ?? this.sku,
      fechaEscaneo: fechaEscaneo,
    );
  }
}
