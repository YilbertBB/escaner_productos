class ImagenProducto {
  final String ruta; // URL remota o ruta local
  final bool esLocal; // true = archivo en el dispositivo, false = URL
  final String rol; // 'frontal', 'reverso', 'etiqueta', 'extra'

  ImagenProducto({
    required this.ruta,
    required this.esLocal,
    this.rol = 'extra',
  });

  factory ImagenProducto.fromJson(Map<String, dynamic> json) {
    return ImagenProducto(
      ruta: json['ruta'] ?? '',
      esLocal: json['es_local'] ?? false,
      rol: json['rol'] ?? 'extra',
    );
  }

  Map<String, dynamic> toJson() => {
    'ruta': ruta,
    'es_local': esLocal,
    'rol': rol,
  };
}
