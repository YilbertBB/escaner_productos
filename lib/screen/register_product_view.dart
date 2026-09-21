import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../models/imagen_producto.dart';
import '../models/producto.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RegisterProductView extends StatefulWidget {
  // 👈 Ahora recibe el código escaneado y el producto pre-cargado (puede ser null)
  final String codigoEscaneado;
  final Producto? productoInicial;

  const RegisterProductView({
    super.key,
    required this.codigoEscaneado,
    this.productoInicial,
  });

  @override
  State<RegisterProductView> createState() => _RegisterProductViewState();
}

class _RegisterProductViewState extends State<RegisterProductView> {
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // 👈 Lista de imágenes (remotas de Open Food Facts + locales del usuario)
  List<ImagenProducto> _imagenes = [];

  String _selectedCategory = 'otro';

  @override
  void initState() {
    super.initState();

    // 👈 Pre-rellenar con datos de Open Food Facts si existen
    final inicial = widget.productoInicial;
    if (inicial != null) {
      _nameController.text = inicial.nombre;
      _brandController.text = inicial.marca;
      _descController.text = inicial.ingredientes;
      _priceController.text = inicial.precio > 0
          ? inicial.precio.toStringAsFixed(2)
          : '';
      _skuController.text = inicial.sku;
      _selectedCategory = inicial.categoria;
      _imagenes = List.from(inicial.imagenes);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ────────────────────── GUARDAR ──────────────────────
Future<void> _guardarProducto() async {
  // 👈 VALIDACIÓN: nombre obligatorio
  final nombre = _nameController.text.trim();
  if (nombre.isEmpty) {
    _mostrarErrorValidacion('El nombre del producto es obligatorio');
    return;
  }

  // 👈 VALIDACIÓN: precio válido (opcional pero útil)
  final precioTexto = _priceController.text.trim();
  double precio = 0.0;
  if (precioTexto.isNotEmpty) {
    final parsed = double.tryParse(precioTexto);
    if (parsed == null || parsed < 0) {
      _mostrarErrorValidacion('El precio debe ser un número válido');
      return;
    }
    precio = parsed;
  }

  final storage = StorageService();
  final export = ExportService();

  final producto = Producto(
    codigo: widget.codigoEscaneado,
    nombre: nombre,
    marca: _brandController.text.trim(),
    ingredientes: _descController.text.trim(),
    categoria: _selectedCategory,
    precio: precio,
    sku: _skuController.text.trim(),
    imagenes: _imagenes,
  );

  await storage.agregarProducto(producto);

  if (!mounted) return;

  final exportar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      title: const Text('Producto guardado'),
      content: const Text(
        '¿Quieres exportar todos los productos a JSON ahora?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Después'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Exportar'),
        ),
      ],
    ),
  );

  if (exportar == true) {
    final ok = await export.exportarProductos();
    if (mounted) {
      _showSuccessToast(
        ok ? 'JSON exportado correctamente' : 'No hay productos para exportar',
      );
    }
  }

  if (mounted) {
    Navigator.pop(context);
  }
}

// 👈 Nuevo método para mostrar errores de validación
void _mostrarErrorValidacion(String mensaje) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF7F1D1D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ────────────────────── FOTOS ──────────────────────
  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (foto != null) {
      await _agregarImagen(foto.path);
    }
  }

  Future<void> _elegirDeGaleria() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (foto != null) {
      await _agregarImagen(foto.path);
    }
  }

  Future<void> _agregarImagen(String rutaOriginal) async {
    // En web no podemos copiar archivos, guardamos la ruta tal cual
    String rutaFinal = rutaOriginal;

    if (!kIsWeb) {
      // 👈 Copiamos la imagen a una carpeta permanente de la app
      try {
        final dir = await getApplicationDocumentsDirectory();
        final nombre = 'producto_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final nuevo = File('${dir.path}/$nombre');
        await File(rutaOriginal).copy(nuevo.path);
        rutaFinal = nuevo.path;
      } catch (e) {
        print('Error al copiar imagen: $e');
      }
    }

    setState(() {
      _imagenes.add(
        ImagenProducto(
          ruta: rutaFinal,
          esLocal: true,
          rol: _imagenes.isEmpty ? 'frontal' : 'extra',
        ),
      );
    });
  }

  void _eliminarImagen(int index) {
    setState(() => _imagenes.removeAt(index));
  }

  // ────────────────────── BUILD ──────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          _buildNewItemBanner(),
          const SizedBox(height: AppSpacing.md),
          _buildLockedBarcode(),
          const SizedBox(height: AppSpacing.md),
          _buildPhotoStudio(),
          const SizedBox(height: AppSpacing.md),
          _buildEssentialData(),
          const SizedBox(height: AppSpacing.lg),
          _buildPrimaryActions(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface.withValues(alpha: 0.8),
      elevation: 0,
      titleSpacing: AppSpacing.gutter,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.center_focus_strong,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Text(
                'ScanLens',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              const HudBadge(text: 'HUD'),
            ],
          ),
        ],
      ),
      actions: const [SizedBox(width: 8)],
    );
  }

  Widget _buildNewItemBanner() {
    final esNuevo = widget.productoInicial == null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(
              esNuevo ? Icons.new_releases : Icons.cloud_done,
              color: AppColors.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        esNuevo ? 'Nuevo Ítem Detectado' : 'Datos Encontrados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    HudBadge(
                      text: esNuevo ? 'Nuevo' : 'Sincronizado',
                      bgColor: AppColors.secondaryContainer,
                      textColor: AppColors.onSecondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  esNuevo
                      ? 'Código no reconocido en la base central. Completa los datos para archivarlo.'
                      : 'Datos precargados desde Open Food Facts. Revisa y ajusta si es necesario.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBarcode() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LECTURA HUD BLOQUEADA', style: AppMonoText.badge),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.flip_camera_android, size: 16),
                label: const Text('Reescanear'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.barcode_reader,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const HudBadge(text: 'EAN-13'),
                          const SizedBox(width: 6),
                          Text(
                            'VALIDADO',
                            style: AppMonoText.badge.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.codigoEscaneado, // 👈 código real
                        style: AppMonoText.code.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppColors.outline,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStudio() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tomas del Producto',
            subtitle: 'La frontal se usará como portada',
            trailing: HudBadge(text: '${_imagenes.length}'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_imagenes.isEmpty)
            Row(
              children: [
                Expanded(
                  child: _buildPhotoSlotEmpty(
                    icon: Icons.image,
                    label: 'Frontal',
                    hint: 'Requerida',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildPhotoSlotEmpty(
                    icon: Icons.receipt_long,
                    label: 'Reverso',
                    hint: 'Opcional',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildPhotoSlotEmpty(
                    icon: Icons.center_focus_strong,
                    label: 'Etiqueta',
                    hint: 'Macro',
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagenes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _buildImagenThumb(_imagenes[i], i),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.photo_camera,
                  label: 'Tomar Foto',
                  filled: true,
                  onPressed: _tomarFoto, // 👈 conectado
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSecondaryButton(
                  icon: Icons.add_photo_alternate,
                  label: 'Galería',
                  onPressed: _elegirDeGaleria, // 👈 conectado
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlotEmpty({IconData? icon, String? label, String? hint}) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.add_a_photo,
              color: AppColors.tertiary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label ?? '',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            if (hint != null)
              Text(
                hint,
                style: const TextStyle(fontSize: 10, color: AppColors.outline),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenThumb(ImagenProducto img, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            width: 100,
            height: 100,
            child: img.esLocal && !kIsWeb
                ? Image.file(File(img.ruta), fit: BoxFit.cover)
                : Image.network(
                    img.ruta,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceContainer,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.outline,
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _eliminarImagen(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              img.rol.toUpperCase(),
              style: AppMonoText.badge.copyWith(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    bool filled = false,
    required VoidCallback onPressed, // 👈 nuevo parámetro
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: filled
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceContainerLow,
        foregroundColor: filled ? AppColors.primary : AppColors.onSurface,
        minimumSize: const Size(double.infinity, 44),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEssentialData() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Datos Esenciales',
            subtitle: 'Especificaciones mínimas de trazabilidad',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInputField(
            label: 'Nombre del Producto *',
            controller: _nameController,
            hint: 'Ej. Barra de Cereal Orgánica 45g',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInputField(
            label: 'Marca o Fabricante',
            controller: _brandController,
            hint: 'Ej. Nestlé, Unilever',
            prefixIcon: Icons.verified,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCategoryDropdown(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'SKU / Lote',
                  controller: _skuController,
                  hint: 'LOTE-001',
                  isMono: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildPriceField()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInputField(
            label: 'Descripción / Ingredientes',
            controller: _descController,
            hint: 'Ingredientes: agua, azúcar...',
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? prefixIcon,
    bool isMono = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: isMono
              ? AppMonoText.code.copyWith(fontSize: 14)
              : TextStyle(fontSize: 14, color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.outline),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: AppColors.tertiary)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría de Catálogo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.tertiary),
              style: TextStyle(fontSize: 14, color: AppColors.onSurface),
              items: const [
                DropdownMenuItem(
                  value: 'cosmetica',
                  child: Text('Cosmética & Cuidado Personal'),
                ),
                DropdownMenuItem(
                  value: 'alimentos',
                  child: Text('Alimentos & Bebidas'),
                ),
                DropdownMenuItem(
                  value: 'limpieza',
                  child: Text('Limpieza & Hogar'),
                ),
                DropdownMenuItem(
                  value: 'electronica',
                  child: Text('Electrónica & Gadgets'),
                ),
                DropdownMenuItem(
                  value: 'farmacia',
                  child: Text('Salud & Farmacia'),
                ),
                DropdownMenuItem(
                  value: 'otro',
                  child: Text('Otro / No catalogado'),
                ),
              ],
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precio PVP',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Text(
                '\$',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    filled: false,
                  ),
                ),
              ),
              const HudBadge(text: 'USD'),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActions() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _guardarProducto,
          icon: const Icon(Icons.save, size: 24),
          label: const Text('Guardar y Generar Ficha'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 56),
            elevation: 4,
            shadowColor: AppColors.primary.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.tertiary,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text(
            'Descartar y Volver',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showSuccessToast(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.inverseSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.done_all,
                color: AppColors.onSecondaryContainer,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.inverseOnSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
