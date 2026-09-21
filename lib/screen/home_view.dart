import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/imagen_producto.dart';
import '../models/producto.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'history_view.dart';
import 'scanner_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final StorageService _storage = StorageService();
  final TextEditingController _manualController = TextEditingController();

  List<Producto> _productos = [];
  bool _cargando = true;
  bool _showManualInput = false;
  bool _torchActive = false;
  String _selectedCategory = 'all';

  // ────────────────────── CARGA DE DATOS ──────────────────────
  @override
  void initState() {
    super.initState();
    _cargarProductos();
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

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  // ────────────────────── MÉTRICAS ──────────────────────
  bool get _hasData => _productos.isNotEmpty;

  int get _scans => _productos.length;

  int get _active => _productos.length; // por ahora todos cuentan como activos

  int get _categories => _productos.map((p) => p.categoria).toSet().length;

  double get _inventory => _productos.fold(0.0, (sum, p) => sum + p.precio);

  List<Producto> get _filteredProducts {
    if (_selectedCategory == 'all') return _productos;
    return _productos.where((p) => p.categoria == _selectedCategory).toList();
  }

  // ────────────────────── BUILD ──────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarProductos,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildAppBar()),
                    SliverToBoxAdapter(child: _buildGreeting()),
                    SliverToBoxAdapter(child: _buildScannerBanner()),
                    SliverToBoxAdapter(child: _buildMetricTiles()),
                    SliverToBoxAdapter(child: _buildFilterChips()),
                    if (_hasData) ...[
                      SliverToBoxAdapter(child: _buildRecentHeader()),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                              left: AppSpacing.gutter,
                              right: AppSpacing.gutter,
                            ),
                            child: _ProductCard(
                              product: _filteredProducts[i],
                              onCopy: _copyBarcode,
                              onOpen: _openFicha,
                              onMore: _showOptions,
                            ),
                          ),
                          childCount: _filteredProducts.length,
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildAdvancedActions()),
                    ] else ...[
                      SliverToBoxAdapter(child: _buildEmptyState()),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  // ────────────────────── APP BAR ──────────────────────
  Widget _buildAppBar() {
    return Padding(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DB SYNC ACTIVE',
                    style: AppMonoText.badge.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
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
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryView()),
                );
                _cargarProductos(); // recarga al volver
              },
              icon: Icon(Icons.history, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── GREETING ──────────────────────
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hola, Usuario',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TERM-01 • Catálogo sincronizado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showManualInput = !_showManualInput),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.search,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── SCANNER BANNER ──────────────────────
  Widget _buildScannerBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showManualInput
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.barcode_reader,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        style: AppMonoText.code,
                        decoration: InputDecoration(
                          hintText: 'Ingresa EAN, UPC o nombre...',
                          hintStyle: AppMonoText.code.copyWith(
                            color: AppColors.outline,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showManualInput = false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'BUSCAR',
                        style: AppMonoText.badge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryContainer,
                  AppColors.surfaceTint,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.center_focus_strong,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HUD ACTIVE',
                          style: AppMonoText.badge.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SENSOR LÁSER v2.4',
                      style: AppMonoText.badge.copyWith(
                        color: AppColors.secondaryContainer,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Listo para escanear',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detección ultrarrápida de códigos 1D, 2D, EAN-13 y DataMatrix con IA de lote.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScannerView(),
                                ),
                              );
                              _cargarProductos(); // recarga al volver
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 22),
                            label: const Text('Escanear Producto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerLowest,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(0, 48),
                              elevation: 4,
                              shadowColor: Colors.black.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              textStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _torchActive = !_torchActive);
                            _showToast('Torch calibrado');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _torchActive
                                  ? AppColors.secondary
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.flashlight_on,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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

  // ────────────────────── METRIC TILES ──────────────────────
  Widget _buildMetricTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              icon: Icons.qr_code_2,
              value: '$_scans',
              label: 'Escaneos',
              iconBg: AppColors.surfaceContainerHigh,
              iconColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              icon: Icons.check_circle,
              value: '$_active',
              label: 'Activos',
              iconBg: AppColors.secondaryContainer.withValues(alpha: 0.5),
              iconColor: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              icon: Icons.category,
              value: '$_categories',
              label: 'Rubros',
              iconBg: AppColors.tertiaryFixed,
              iconColor: AppColors.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              icon: Icons.payments,
              value: '\$${_inventory.toStringAsFixed(0)}',
              label: 'Inventario',
              iconBg: AppColors.surfaceContainerHigh,
              iconColor: AppColors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── FILTER CHIPS ──────────────────────
  Widget _buildFilterChips() {
    final chips = [
      _FilterChipData(
        key: 'all',
        label: 'Todos',
        icon: Icons.dashboard,
        count: _scans,
      ),
      _FilterChipData(
        key: 'alimentos',
        label: 'Alimentos',
        icon: Icons.eco,
        iconColor: AppColors.secondary,
      ),
      _FilterChipData(
        key: 'electronica',
        label: 'Electrónica',
        icon: Icons.headphones,
        iconColor: AppColors.primary,
      ),
      _FilterChipData(
        key: 'cosmetica',
        label: 'Cosméticos',
        icon: Icons.spa,
        iconColor: AppColors.tertiary,
      ),
      _FilterChipData(
        key: 'limpieza',
        label: 'Limpieza',
        icon: Icons.cleaning_services,
        iconColor: AppColors.primaryContainer,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final chip = chips[i];
            final selected = _selectedCategory == chip.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = chip.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: 16,
                      color: selected
                          ? AppColors.onPrimary
                          : (chip.iconColor ?? AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.onPrimary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (chip.count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.25)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${chip.count}',
                          style: AppMonoText.badge.copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ────────────────────── RECENT HEADER ──────────────────────
  Widget _buildRecentHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            'Productos Recientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryView()),
              );
              _cargarProductos();
            },
            icon: const SizedBox.shrink(),
            label: Row(
              children: [
                Text(
                  'Ver todos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────── ADVANCED ACTIONS ──────────────────────
  Widget _buildAdvancedActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ACCIONES AVANZADAS',
                  style: AppMonoText.badge.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  'MODO RÁPIDO',
                  style: AppMonoText.badge.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAdvancedAction(
                    icon: Icons.filter_center_focus,
                    label: 'Escaneo en Lote',
                    sub: 'Captura múltiple',
                    iconBg: AppColors.surfaceContainerHigh,
                    iconColor: AppColors.primary,
                    onTap: () => _showToast('Modo ráfaga activado'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAdvancedAction(
                    icon: Icons.file_download,
                    label: 'Exportar JSON',
                    sub: '$_scans registros',
                    iconBg: AppColors.secondaryContainer.withValues(alpha: 0.4),
                    iconColor: AppColors.secondary,
                    onTap: _exportarJson,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedAction({
    required IconData icon,
    required String label,
    required String sub,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.slateNavy.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────── EMPTY STATE ──────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildZeroMetric('Escaneos', '0', 'Total histórico'),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildZeroMetric('Catálogo', '0', 'Categorías')),
              const SizedBox(width: 8),
              Expanded(
                child: _buildZeroMetric('Guardados', '0', 'En favoritos'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slateNavy.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHudReticle(),
                const SizedBox(height: 20),
                Text(
                  'Aún no has escaneado ningún producto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apunta la cámara a cualquier código de barras o código QR para sincronizar fotos oficiales, fichas técnicas y precios al instante.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScannerView(),
                      ),
                    );
                    _cargarProductos();
                  },
                  icon: const Icon(Icons.center_focus_strong, size: 20),
                  label: const Text('Iniciar Primer Escaneo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    textStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildStepsGuide(),
        ],
      ),
    );
  }

  Widget _buildHudReticle() {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: _cornerBracket(top: true, left: true),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _cornerBracket(top: true, left: false),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: _cornerBracket(top: false, left: true),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: _cornerBracket(top: false, left: false),
          ),
          Positioned.fill(child: _AnimatedSweepLaser()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'EAN · UPC · QR',
                    style: AppMonoText.badge.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerBracket({required bool top, required bool left}) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZeroMetric(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateNavy.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppMonoText.code.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            sub,
            style: AppMonoText.badge.copyWith(
              color: AppColors.tertiary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepsGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                '¿CÓMO FUNCIONA?',
                style: AppMonoText.code.copyWith(
                  color: AppColors.tertiary,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '3 PASOS SIMPLES',
                style: AppMonoText.badge.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildStep(
          number: '01',
          title: 'Apunta al código',
          subtitle: 'Encuadra cualquier caja, etiqueta o embalaje.',
          icon: Icons.photo_camera,
        ),
        const SizedBox(height: 8),
        _buildStep(
          number: '02',
          title: 'Reconocimiento IA',
          subtitle: 'Sincronización óptica en menos de 100ms.',
          icon: Icons.bolt,
        ),
        const SizedBox(height: 8),
        _buildStep(
          number: '03',
          title: 'Ficha y Guardado',
          subtitle: 'Obtén ficha técnica, variantes y registro local.',
          icon: Icons.assignment_turned_in,
        ),
      ],
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateNavy.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: AppMonoText.code.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
        ],
      ),
    );
  }

  // ────────────────────── ACCIONES ──────────────────────
  void _copyBarcode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _showToast('Código $code copiado');
  }

  void _openFicha(Producto p) {
    _showToast('Abriendo ficha de ${p.nombre}...');
  }

  void _showOptions(Producto p) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar producto'),
              onTap: () async {
                Navigator.pop(context);
                await _storage.eliminarProducto(p.codigo);
                _cargarProductos();
                _showToast('Producto eliminado');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar código'),
              onTap: () {
                Navigator.pop(context);
                _copyBarcode(p.codigo);
              },
            ),
          ],
        ),
      ),
    );
  }

Future<void> _exportarJson() async {
  if (_productos.isEmpty) {
    _showToast('No hay productos para exportar');
    return;
  }

  _showToast('Generando JSON...');

  final export = ExportService();
  final ok = await export.exportarProductos();

  if (!mounted) return;

  if (ok) {
    _showToast('JSON exportado correctamente');
  } else {
    _showToast('Error al exportar');
  }
}

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverseSurface,
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        duration: const Duration(milliseconds: 2000),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.secondaryContainer,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  fontSize: 13,
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

// ────────────────────── HELPERS ──────────────────────
class _FilterChipData {
  final String key;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final int? count;

  _FilterChipData({
    required this.key,
    required this.label,
    required this.icon,
    this.iconColor,
    this.count,
  });
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconBg;
  final Color iconColor;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateNavy.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AnimatedSweepLaser extends StatefulWidget {
  @override
  State<_AnimatedSweepLaser> createState() => _AnimatedSweepLaserState();
}

class _AnimatedSweepLaserState extends State<_AnimatedSweepLaser>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment(0, _controller.value * 2 - 1),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primaryContainer.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────── PRODUCT CARD ──────────────────────
class _ProductCard extends StatelessWidget {
  final Producto product;
  final Function(String) onCopy;
  final Function(Producto) onOpen;
  final Function(Producto) onMore;

  const _ProductCard({
    required this.product,
    required this.onCopy,
    required this.onOpen,
    required this.onMore,
  });

  Color _categoryBg() {
    switch (product.categoria) {
      case 'alimentos':
        return AppColors.secondaryContainer;
      case 'electronica':
        return AppColors.surfaceContainerHigh;
      case 'cosmetica':
        return AppColors.surfaceContainerHigh;
      case 'limpieza':
        return AppColors.tertiaryFixed;
      default:
        return AppColors.surfaceContainer;
    }
  }

  Color _categoryFg() {
    switch (product.categoria) {
      case 'alimentos':
        return AppColors.onSecondaryFixedVariant;
      case 'electronica':
      case 'cosmetica':
        return AppColors.primary;
      case 'limpieza':
        return AppColors.onTertiaryFixedVariant;
      default:
        return AppColors.onSurface;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(product.fechaEscaneo);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.slateNavy.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: product.tieneImagenes
                          ? _buildImagen(product.imagenPrincipal!)
                          : const Icon(
                              Icons.inventory_2,
                              color: AppColors.outline,
                              size: 28,
                            ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withValues(
                            alpha: 0.9,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'EAN-13',
                          style: AppMonoText.badge.copyWith(fontSize: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _categoryBg(),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              product.categoria.toUpperCase(),
                              style: AppMonoText.badge.copyWith(
                                color: _categoryFg(),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.codigo,
                                style: AppMonoText.code.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onCopy(product.codigo),
                            child: const Icon(
                              Icons.content_copy,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRECIO',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.outline,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '\$${product.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product.marca.isNotEmpty
                                ? product.marca
                                : 'Sin marca',
                            style: AppMonoText.badge.copyWith(
                              color: AppColors.onSecondaryFixedVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onOpen(product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ficha',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onMore(product),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.more_vert,
                      color: AppColors.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildImagen(ImagenProducto img) {
    print('🏠 HOME RENDER IMAGEN:');
  print('   - ruta: ${img.ruta}');
  print('   - esLocal: ${img.esLocal}');
  print('   - esBase64: ${img.esBase64}');
  print('   - kIsWeb: $kIsWeb');
  // 👈 Base64 (web)
  if (img.esBase64) {
    final base64String = img.ruta.split(',').last;
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceContainer,
        child: const Icon(Icons.broken_image, color: AppColors.outline, size: 28),
      ),
    );
  }

  // 👈 Imagen local (móvil)
  if (img.esLocal) {
    if (kIsWeb) {
      return Container(
        color: AppColors.surfaceContainer,
        child: const Icon(Icons.photo, color: AppColors.outline, size: 28),
      );
    }
    final file = File(img.ruta);
    if (!file.existsSync()) {
      return Container(
        color: AppColors.surfaceContainer,
        child: const Icon(Icons.broken_image, color: AppColors.outline, size: 28),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceContainer,
        child: const Icon(Icons.broken_image, color: AppColors.outline, size: 28),
      ),
    );
  }

  // 👈 Imagen remota
  return Image.network(
    img.ruta,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return Container(
        color: AppColors.surfaceContainer,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    },
    errorBuilder: (_, __, ___) => Container(
      color: AppColors.surfaceContainer,
      child: const Icon(Icons.broken_image, color: AppColors.outline, size: 28),
    ),
  );
}
}
