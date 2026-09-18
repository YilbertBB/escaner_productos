import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryItem {
  final String id;
  final String title;
  final String brand;
  final String code;
  final String category;
  final String timeAgo;
  final String? imageUrl;
  final String codeType;

  HistoryItem({
    required this.id,
    required this.title,
    required this.brand,
    required this.code,
    required this.category,
    required this.timeAgo,
    this.imageUrl,
    this.codeType = 'EAN',
  });
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  // final bool _batchMode = false;

  final List<HistoryItem> _todayItems = [
    HistoryItem(
      id: '1',
      title: 'Granola Artesanal Crunch Almendra 500g',
      brand: 'NaturAlmendras S.L.',
      code: '8410293048123',
      category: 'alimentos',
      timeAgo: 'Hace 12 min',
    ),
    HistoryItem(
      id: '2',
      title: 'Auriculares Inalámbricos Pro ANC',
      brand: 'SonicAudio Pro',
      code: '019425203810',
      category: 'electronica',
      timeAgo: 'Hace 2 horas',
      codeType: 'UPC',
    ),
  ];

  final List<HistoryItem> _yesterdayItems = [
    HistoryItem(
      id: '3',
      title: 'Café Molido Arábica de Colombia 250g',
      brand: 'Andina Roasters',
      code: '7702004001234',
      category: 'bebidas',
      timeAgo: 'Ayer, 18:20',
    ),
    HistoryItem(
      id: '4',
      title: 'Crema Hidratante Facial Ácido Hialurónico',
      brand: 'Lumière Skincare',
      code: 'https://lumiere.care/p/ha-hydra',
      category: 'cuidado',
      timeAgo: 'Ayer, 11:15',
      codeType: 'QR',
    ),
  ];

  final Map<String, String> _categories = {
    'all': 'Todos',
    'alimentos': 'Alimentos',
    'electronica': 'Electrónica',
    'bebidas': 'Bebidas',
    'cuidado': 'Cuidado Personal',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryItem> _filteredItems(List<HistoryItem> items) {
    return items.where((item) {
      final matchesSearch =
          _searchController.text.isEmpty ||
          item.title.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          item.code.contains(_searchController.text);
      final matchesCategory =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
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
                _buildTimeBlock('Hoy', _filteredItems(_todayItems)),
                const SizedBox(height: AppSpacing.lg),
                _buildTimeBlock('Ayer', _filteredItems(_yesterdayItems)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              'ScanLens',
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
                    'Online',
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

  Widget _buildHudOverview() {
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
                _buildStat('28', 'Escaneos', AppColors.primary),
                _buildDivider(),
                _buildStat('4', 'Categorías', AppColors.secondary),
                _buildDivider(),
                _buildStat('14', 'Favoritos', AppColors.tertiary),
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
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.tune, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildToolChip(
              icon: Icons.file_download,
              label: 'Exportar CSV',
              filled: true,
            ),
            const SizedBox(width: 8),
            _buildToolChip(
              icon: Icons.checklist,
              label: 'Selección',
              filled: false,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
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

  Widget _buildToolChip({
    required IconData icon,
    required String label,
    required bool filled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: filled ? AppColors.onPrimary : AppColors.onSurface,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: filled ? AppColors.onPrimary : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = _categories.keys.elementAt(index);
          final label = _categories[key]!;
          final selected = _selectedCategory == key;
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
                key == 'all' ? '$label (28)' : label,
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

  Widget _buildTimeBlock(String label, List<HistoryItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

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
              HudBadge(text: '${items.length} Escaneos'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildHistoryCard(item),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
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
            child: const Icon(
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
                        item.brand,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.more_vert,
                      color: AppColors.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
                Text(
                  item.title,
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
                        _categories[item.category] ?? item.category,
                        style: AppMonoText.badge.copyWith(
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.code,
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
                      item.timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.code));
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
}
