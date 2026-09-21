import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/imagen_producto.dart';
import '../models/producto.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final StorageService _storage = StorageService();
  final _searchController = TextEditingController();

  List<Producto> _productos = [];
  bool _cargando = true;
  String _selectedCategory = 'all';

  final Map<String, String> _categories = {
    'all': 'Todos',
    'alimentos': 'Alimentos',
    'electronica': 'Electrónica',
    'cosmetica': 'Cosmética',
    'limpieza': 'Limpieza',
    'farmacia': 'Farmacia',
    'otro': 'Otros',
  };

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    final productos = await _storage.obtenerProductos();
    if (!mounted) return;
    setState(() {
      _productos = productos;
      _cargando = false;
    });
  }

  // ────────────────────── FILTROS ──────────────────────
  List<Producto> get _filteredProducts {
    final query = _searchController.text.toLowerCase();
    return _productos.where((p) {
      final matchesSearch = query.isEmpty ||
          p.nombre.toLowerCase().contains(query) ||
          p.marca.toLowerCase().contains(query) ||
          p.codigo.contains(query);
      final matchesCategory =
          _selectedCategory == 'all' || p.categoria == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Agrupa por fecha
  Map<String, List<Producto>> get _agrupados {
    final hoy = <Producto>[];
    final ayer = <Producto>[];
    final estaSemana = <Producto>[];
    final masAntiguo = <Producto>[];

    final ahora = DateTime.now();
    final inicioHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioAyer = inicioHoy.subtract(const Duration(days: 1));
    final inicioSemana = inicioHoy.subtract(const Duration(days: 7));

    for (final p in _filteredProducts) {
      final fecha = p.fechaEscaneo;
      if (fecha.isAfter(inicioHoy)) {
        hoy.add(p);
      } else if (fecha.isAfter(inicioAyer)) {
        ayer.add(p);
      } else if (fecha.isAfter(inicioSemana)) {
        estaSemana.add(p);
      } else {
        masAntiguo.add(p);
      }
    }

    return {
      'Hoy': hoy,
      'Ayer': ayer,
      'Esta semana': estaSemana,
      'Más antiguo': masAntiguo,
    };
  }

  // ────────────────────── BUILD ──────────────────────
  @override
  Widget build(BuildContext context) {
    final grupos = _agrupados;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargarProductos,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        0,
                        AppSpacing.gutter,
                        100,
                      ),
                      children: [
                        _buildHudOverview(),
                        const SizedBox(height: AppSpacing.md),
                        _buildSearchAndTools(),
                        const SizedBox(height: AppSpacing.md),
                        _buildCategoryChips(),
                        const SizedBox(height: AppSpacing.lg),
                        if (_productos.isEmpty)
                          _buildEmptyState()
                        else ...[
                          for (final entry in grupos.entries)
                            if (entry.value.isNotEmpty) ...[
                              _buildTimeBlock(entry.key, entry.value),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── APP BAR ──────────────────────
  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.sm,
        ),
        child: Row(
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
            Text(
              'Historial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            const HudBadge(text: 'HUD'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye,
                    color: AppColors.secondary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_productos.length}',
                    style: AppMonoText.code.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────── HUD OVERVIEW ──────────────────────
  Widget _buildHudOverview() {
    final categorias = _productos.map((p) => p.categoria).toSet().length;
    final total = _productos.fold<double>(0, (s, p) => s + p.precio);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HUD REGISTRO ACTIVO',
                    style: AppMonoText.badge.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const HudBadge(
                text: '100% Sinc',
                bgColor: AppColors.secondaryContainer,
                textColor: AppColors.onSecondaryContainer,
                icon: Icons.cloud_done,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                _buildStat('${_productos.length}', 'Escaneos', AppColors.primary),
                _buildDivider(),
                _buildStat('$categorias', 'Categorías', AppColors.secondary),
                _buildDivider(),
                _buildStat(
                  '\$${total.toStringAsFixed(0)}',
                  'Valor',
                  AppColors.tertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.outlineVariant.withValues(alpha: 0.5),
    );
  }

  // ────────────────────── BÚSQUEDA Y HERRAMIENTAS ──────────────────────
  Widget _buildSearchAndTools() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar por producto, marca o código...',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.outline),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: AppColors.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Spacer(),
            GestureDetector(
              onTap: _confirmarLimpiar,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_sweep,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Limpiar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmarLimpiar() async {
    if (_productos.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: const Text('¿Limpiar historial?'),
        content: Text(
          'Se eliminarán ${_productos.length} productos. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _storage.limpiar();
      await _cargarProductos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial eliminado')),
        );
      }
    }
  }

  // ────────────────────── CHIPS ──────────────────────
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = _categories.keys.elementAt(index);
          final label = _categories[key]!;
          final selected = _selectedCategory == key;
          final count = key == 'all'
              ? _productos.length
              : _productos.where((p) => p.categoria == key).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                key == 'all' ? '$label ($count)' : label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ────────────────────── BLOQUES DE TIEMPO ──────────────────────
  Widget _buildTimeBlock(String label, List<Producto> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: label == 'Hoy'
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              HudBadge(text: '${items.length}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildHistoryCard(p),
          ),
        ),
      ],
    );
  }

  // ────────────────────── TARJETA ──────────────────────
  Widget _buildHistoryCard(Producto p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateNavy.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            clipBehavior: Clip.antiAlias,
            child: p.tieneImagenes
                ? _buildImagen(p.imagenPrincipal!)
                : const Icon(
                    Icons.inventory_2,
                    color: AppColors.outline,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.marca.isNotEmpty ? p.marca : 'Sin marca',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _eliminarProducto(p),
                      child: const Icon(
                        Icons.more_vert,
                        color: AppColors.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Text(
                  p.nombre,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _categories[p.categoria] ?? p.categoria,
                        style: AppMonoText.badge.copyWith(
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.codigo,
                        style: AppMonoText.code.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(p.fechaEscaneo),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: p.codigo));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.inverseSurface,
                            content: Text(
                              'Código copiado al portapapeles',
                              style: TextStyle(
                                color: AppColors.inverseOnSurface,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.content_copy,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Copiar',
                            style: AppMonoText.badge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Future<void> _eliminarProducto(Producto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        title: const Text('¿Eliminar producto?'),
        content: Text('Se eliminará "${p.nombre}" del historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _storage.eliminarProducto(p.codigo);
      await _cargarProductos();
    }
  }

  Widget _buildImagen(ImagenProducto img) {
    if (img.esBase64) {
      return Image.memory(
        base64Decode(img.ruta.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image,
          color: AppColors.outline,
          size: 28,
        ),
      );
    }
    return Image.network(
      img.ruta,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image,
        color: AppColors.outline,
        size: 28,
      ),
    );
  }

  // ────────────────────── EMPTY ──────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.history,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin historial todavía',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Los productos que escanees aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}