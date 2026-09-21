class ImagenProducto {
  final String ruta;      // URL remota, ruta local, o data:image/...;base64,...
  final bool esLocal;
  final String rol;

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

  // 👈 Helper: ¿es una imagen Base64?
  bool get esBase64 => ruta.startsWith('data:image');
}