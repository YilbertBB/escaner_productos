// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// import '../services/openfoodfacts_service.dart';
// import '../theme/app_theme.dart';
// import '../widgets/shared_widgets.dart';
// import 'register_product_view.dart';

// class ScannerView extends StatefulWidget {
//   const ScannerView({super.key});

//   @override
//   State<ScannerView> createState() => _ScannerViewState();
// }

// class _ScannerViewState extends State<ScannerView>
//     with SingleTickerProviderStateMixin {
//   // 👈 Controlador real de mobile_scanner
//   final MobileScannerController _scannerController = MobileScannerController(
//     detectionSpeed: DetectionSpeed.noDuplicates,
//     formats: const [
//       BarcodeFormat.ean13,
//       BarcodeFormat.ean8,
//       BarcodeFormat.upcA,
//       BarcodeFormat.upcE,
//       BarcodeFormat.code128,
//       BarcodeFormat.code39,
//       BarcodeFormat.qrCode,
//       BarcodeFormat.dataMatrix,
//       BarcodeFormat.pdf417,
//       BarcodeFormat.aztec,
//     ],
//   );

//   late AnimationController _sweepController;
//   bool _torchOn = false;
//   bool _autoZoom = true;
//   bool _multiScan = false;
//   bool _isLocked = false; // evita múltiples detecciones
//   bool _procesando = false; // evita doble navegación

//   final OpenFoodFactsService _foodService = OpenFoodFactsService();

//   @override
//   void initState() {
//     super.initState();
//     _sweepController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _sweepController.dispose();
//     _scannerController.dispose(); // 👈 liberar la cámara
//     super.dispose();
//   }

//   // ────────────────────── LÓGICA DE ESCANEO ──────────────────────
//   Future<void> _onDetect(BarcodeCapture capture) async {
//     // Si ya estamos procesando o bloqueados, ignoramos
//     if (_procesando || _isLocked) return;

//     final barcode = capture.barcodes.firstOrNull;
//     final codigo = barcode?.rawValue;

//     if (codigo == null || codigo.isEmpty) return;

//     setState(() {
//       _isLocked = true;
//       _procesando = true;
//     });

//     // Vibración opcional
//     // HapticFeedback.mediumImpact();

//     // Buscar producto en Open Food Facts
//     final producto = await _foodService.buscarProducto(codigo);

//     if (!mounted) return;
//   print('Nombre: ${producto?.nombre}');
//   print('Imágenes: ${producto?.imagenes.length}');
//   if (producto != null && producto.imagenes.isNotEmpty) {
//     print('Primera imagen: ${producto.imagenes.first.ruta}');
//   }
//     // Navegar a RegisterProductView con los datos
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => RegisterProductView(
//           codigoEscaneado: codigo,
//           productoInicial: producto,
//         ),
//       ),
//     );

//     // Al volver, desbloqueamos para permitir otro escaneo
//     if (mounted) {
//       setState(() {
//         _isLocked = false;
//         _procesando = false;
//       });
//     }
//   }

//   Future<void> _toggleTorch() async {
//     await _scannerController.toggleTorch();
//     setState(() => _torchOn = !_torchOn);
//   }

//   // ────────────────────── BUILD ──────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.slateNavy,
//       body: Stack(
//         children: [
//           // 👈 Cámara real
//           Positioned.fill(
//             child: MobileScanner(
//               controller: _scannerController,
//               onDetect: _onDetect,
//               errorBuilder: (context, error) {
//                 return Container(
//                   color: AppColors.slateNavy,
//                   child: Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(24),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.error_outline,
//                             color: Colors.white70,
//                             size: 48,
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             'No se pudo iniciar la cámara.\n$error',
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(color: Colors.white70),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Oscurecer un poco el fondo para que resalte el visor
//           Positioned.fill(
//             child: IgnorePointer(
//               child: Container(
//                 color: const Color(0xFF020617).withValues(alpha: 0.35),
//               ),
//             ),
//           ),

//           // HUD viewfinder
//           Center(child: _buildViewfinder()),

//           // Top bar
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(AppSpacing.md),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [_buildTopStatus(), _buildTopControls()],
//               ),
//             ),
//           ),

//           // Bottom thumb zone
//           Positioned(bottom: 0, left: 0, right: 0, child: _buildThumbZone()),
//         ],
//       ),
//     );
//   }

//   // ────────────────────── VIEWFINDER ──────────────────────
//   Widget _buildViewfinder() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: MediaQuery.of(context).size.width * 0.75,
//       height: MediaQuery.of(context).size.width * 0.6,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Reticle frame
//           Container(
//             decoration: BoxDecoration(
//               border: Border.all(
//                 color: Colors.white.withValues(alpha: 0.4),
//                 width: 1,
//               ),
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),

//           // Corner brackets
//           ..._buildCorners(),

//           // Sweep laser
//           AnimatedBuilder(
//             animation: _sweepController,
//             builder: (context, child) {
//               final color = _isLocked
//                   ? AppColors.scanEmerald
//                   : AppColors.scanSapphire;

//               return Positioned(
//                 top:
//                     _sweepController.value *
//                     (MediaQuery.of(context).size.width * 0.6 - 4),
//                 left: 8,
//                 right: 8,
//                 child: Container(
//                   height: 2,
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         color.withValues(alpha: 0.1),
//                         color.withValues(alpha: 0.8),
//                         color.withValues(alpha: 0.1),
//                       ],
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: color.withValues(alpha: 0.6),
//                         blurRadius: 12,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),

//           // Indicador de procesando
//           if (_procesando)
//             Positioned(
//               bottom: 12,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.scanSapphire,
//                   borderRadius: BorderRadius.circular(AppRadius.full),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const SizedBox(
//                       width: 14,
//                       height: 14,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'BUSCANDO...',
//                       style: AppMonoText.badge.copyWith(color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//           // Lock indicator
//           if (_isLocked && !_procesando)
//             Positioned(
//               bottom: 12,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.scanEmerald,
//                   borderRadius: BorderRadius.circular(AppRadius.full),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.scanEmerald.withValues(alpha: 0.45),
//                       blurRadius: 12,
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(
//                       Icons.check_circle,
//                       color: Colors.white,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       'BLOQUEADO',
//                       style: AppMonoText.badge.copyWith(color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildCorners() {
//     final color = _isLocked ? AppColors.scanEmerald : AppColors.scanSapphire;
//     final glow = _isLocked
//         ? [
//             BoxShadow(
//               color: AppColors.scanEmerald.withValues(alpha: 0.45),
//               blurRadius: 12,
//             ),
//           ]
//         : <BoxShadow>[];

//     return [
//       Positioned(
//         top: 0,
//         left: 0,
//         child: Container(
//           width: 28,
//           height: 28,
//           decoration: BoxDecoration(
//             border: Border(
//               top: BorderSide(color: color, width: 3),
//               left: BorderSide(color: color, width: 3),
//             ),
//             boxShadow: glow,
//           ),
//         ),
//       ),
//       Positioned(
//         top: 0,
//         right: 0,
//         child: Container(
//           width: 28,
//           height: 28,
//           decoration: BoxDecoration(
//             border: Border(
//               top: BorderSide(color: color, width: 3),
//               right: BorderSide(color: color, width: 3),
//             ),
//             boxShadow: glow,
//           ),
//         ),
//       ),
//       Positioned(
//         bottom: 0,
//         left: 0,
//         child: Container(
//           width: 28,
//           height: 28,
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(color: color, width: 3),
//               left: BorderSide(color: color, width: 3),
//             ),
//             boxShadow: glow,
//           ),
//         ),
//       ),
//       Positioned(
//         bottom: 0,
//         right: 0,
//         child: Container(
//           width: 28,
//           height: 28,
//           decoration: BoxDecoration(
//             border: Border(
//               bottom: BorderSide(color: color, width: 3),
//               right: BorderSide(color: color, width: 3),
//             ),
//             boxShadow: glow,
//           ),
//         ),
//       ),
//     ];
//   }

//   // ────────────────────── TOP BAR ──────────────────────
//   Widget _buildTopStatus() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppColors.slateNavy.withValues(alpha: 0.7),
//         borderRadius: BorderRadius.circular(AppRadius.full),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: const BoxDecoration(
//               color: AppColors.scanEmerald,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             'DB SYNC',
//             style: AppMonoText.badge.copyWith(color: Colors.white),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopControls() {
//     return Row(
//       children: [
//         QuickToggleButton(
//           icon: Icons.flashlight_on,
//           isActive: _torchOn,
//           onTap: _toggleTorch, // 👈 ahora sí controla la linterna real
//         ),
//         const SizedBox(width: 8),
//         QuickToggleButton(
//           icon: Icons.center_focus_strong,
//           isActive: _autoZoom,
//           onTap: () => setState(() => _autoZoom = !_autoZoom),
//         ),
//         const SizedBox(width: 8),
//         QuickToggleButton(
//           icon: Icons.filter_none,
//           isActive: _multiScan,
//           onTap: () => setState(() => _multiScan = !_multiScan),
//         ),
//       ],
//     );
//   }

//   // ────────────────────── BOTTOM ──────────────────────
//   Widget _buildThumbZone() {
//     return Container(
//       padding: EdgeInsets.only(
//         left: AppSpacing.md,
//         right: AppSpacing.md,
//         top: AppSpacing.lg,
//         bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
//       ),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.transparent,
//             AppColors.slateNavy.withValues(alpha: 0.95),
//           ],
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Instrucción
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: AppColors.slateNavy.withValues(alpha: 0.7),
//               borderRadius: BorderRadius.circular(AppRadius.full),
//               border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(
//                   Icons.qr_code_scanner,
//                   color: Colors.white70,
//                   size: 16,
//                 ),
//                 const SizedBox(width: 6),
//                 Text(
//                   _procesando ? 'PROCESANDO...' : 'APUNTA AL CÓDIGO',
//                   style: AppMonoText.badge.copyWith(color: Colors.white70),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: AppSpacing.lg),

//           // Acciones
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildSideAction(
//                 Icons.arrow_back,
//                 'Volver',
//                 onTap: () => Navigator.pop(context),
//               ),
//               const SizedBox(width: 32),
//               ScanShutterButton(
//                 onPressed: () {
//                   // El shutter ahora solo alterna el bloqueo manual
//                   setState(() => _isLocked = !_isLocked);
//                 },
//               ),
//               const SizedBox(width: 32),
//               _buildSideAction(
//                 Icons.keyboard,
//                 'Manual',
//                 onTap: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Entrada manual próximamente'),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSideAction(IconData icon, String label, {VoidCallback? onTap}) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: AppColors.slateNavy.withValues(alpha: 0.5),
//               border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
//             ),
//             child: Icon(icon, color: Colors.white, size: 22),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 11, color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/product_lookup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'register_product_view.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
    ],
  );

  // 👈 Cambiamos al servicio agregador
  final ProductLookupService _lookupService = ProductLookupService();

  late AnimationController _sweepController;
  bool _torchOn = false;
  bool _autoZoom = true;
  bool _multiScan = false;
  bool _isLocked = false;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ────────────────────── LÓGICA DE ESCANEO ──────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_procesando || _isLocked) return;

    final barcode = capture.barcodes.firstOrNull;
    final codigo = barcode?.rawValue;
    if (codigo == null || codigo.isEmpty) return;

    setState(() {
      _isLocked = true;
      _procesando = true;
    });

    // 👈 Búsqueda en cascada (Food → Beauty → Products → UPCitemdb)
    final producto = await _lookupService.buscarProducto(codigo);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterProductView(
          codigoEscaneado: codigo,
          productoInicial: producto,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isLocked = false;
        _procesando = false;
      });
    }
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  // ────────────────────── BUILD ──────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slateNavy,
      body: Stack(
        children: [
          // Cámara real
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Container(
                  color: AppColors.slateNavy,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white70, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No se pudo iniciar la cámara.\n$error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Oscurecer el fondo para que resalte el visor
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: const Color(0xFF020617).withValues(alpha: 0.35),
              ),
            ),
          ),

          // HUD viewfinder
          Center(child: _buildViewfinder()),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildTopStatus(), _buildTopControls()],
              ),
            ),
          ),

          // Bottom thumb zone
          Positioned(bottom: 0, left: 0, right: 0, child: _buildThumbZone()),
        ],
      ),
    );
  }

  // ────────────────────── VIEWFINDER ──────────────────────
  Widget _buildViewfinder() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.width * 0.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          ..._buildCorners(),

          // Sweep laser
          AnimatedBuilder(
            animation: _sweepController,
            builder: (context, child) {
              final color = _isLocked
                  ? AppColors.scanEmerald
                  : AppColors.scanSapphire;

              return Positioned(
                top: _sweepController.value *
                    (MediaQuery.of(context).size.width * 0.6 - 4),
                left: 8,
                right: 8,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.8),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Indicador de procesando
          if (_procesando)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scanSapphire,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BUSCANDO...',
                      style: AppMonoText.badge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Lock indicator
          if (_isLocked && !_procesando)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.scanEmerald,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.scanEmerald.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BLOQUEADO',
                      style: AppMonoText.badge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    final color = _isLocked ? AppColors.scanEmerald : AppColors.scanSapphire;
    final glow = _isLocked
        ? [
            BoxShadow(
              color: AppColors.scanEmerald.withValues(alpha: 0.45),
              blurRadius: 12,
            ),
          ]
        : <BoxShadow>[];

    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: 3),
              left: BorderSide(color: color, width: 3),
            ),
            boxShadow: glow,
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: 3),
              right: BorderSide(color: color, width: 3),
            ),
            boxShadow: glow,
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: 3),
              left: BorderSide(color: color, width: 3),
            ),
            boxShadow: glow,
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: 3),
              right: BorderSide(color: color, width: 3),
            ),
            boxShadow: glow,
          ),
        ),
      ),
    ];
  }

  // ────────────────────── TOP BAR ──────────────────────
  Widget _buildTopStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slateNavy.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.scanEmerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'MULTI-DB',
            style: AppMonoText.badge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      children: [
        QuickToggleButton(
          icon: Icons.flashlight_on,
          isActive: _torchOn,
          onTap: _toggleTorch,
        ),
        const SizedBox(width: 8),
        QuickToggleButton(
          icon: Icons.center_focus_strong,
          isActive: _autoZoom,
          onTap: () => setState(() => _autoZoom = !_autoZoom),
        ),
        const SizedBox(width: 8),
        QuickToggleButton(
          icon: Icons.filter_none,
          isActive: _multiScan,
          onTap: () => setState(() => _multiScan = !_multiScan),
        ),
      ],
    );
  }

  // ────────────────────── BOTTOM ──────────────────────
  Widget _buildThumbZone() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.slateNavy.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slateNavy.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  _procesando ? 'PROCESANDO...' : 'APUNTA AL CÓDIGO',
                  style: AppMonoText.badge.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSideAction(
                Icons.arrow_back,
                'Volver',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 32),
              ScanShutterButton(
                onPressed: () {
                  setState(() => _isLocked = !_isLocked);
                },
              ),
              const SizedBox(width: 32),
              _buildSideAction(Icons.keyboard, 'Manual', onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entrada manual próximamente'),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.slateNavy.withValues(alpha: 0.5),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}