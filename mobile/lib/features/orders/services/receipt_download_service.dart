import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';

class ReceiptDownloadResult {
  final bool isSuccess;
  final String message;
  final bool isPermissionDenied;

  const ReceiptDownloadResult({
    required this.isSuccess,
    required this.message,
    this.isPermissionDenied = false,
  });
}

typedef GalSaverFn = Future<void> Function(Uint8List bytes, {String? name});

class ReceiptDownloadService {
  ReceiptDownloadService._();
  static final ReceiptDownloadService instance = ReceiptDownloadService._();

  /// Optional override for testing environments
  @visibleForTesting
  GalSaverFn? testSaverOverride;

  /// Optional override for testing capture in headless test environments
  @visibleForTesting
  Uint8List? testPngBytesOverride;

  /// Captures widget marked with [boundaryKey] as PNG bytes with high resolution (3.0x pixel ratio)
  Future<Uint8List?> captureReceiptPng(GlobalKey boundaryKey) async {
    if (testPngBytesOverride != null) {
      return testPngBytesOverride;
    }

    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('ReceiptDownloadService: RenderRepaintBoundary not found for key');
        return null;
      }

      // If boundary needs painting, wait a frame
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 50));
        return await captureReceiptPng(boundaryKey);
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      debugPrint('ReceiptDownloadService.captureReceiptPng error: $e\n$stack');
      return null;
    }
  }

  /// Saves PNG image bytes directly to the device's native photo gallery
  Future<ReceiptDownloadResult> saveReceiptToGallery({
    required Uint8List imageBytes,
    required String orderNumber,
  }) async {
    if (imageBytes.isEmpty) {
      return const ReceiptDownloadResult(
        isSuccess: false,
        message: 'Gagal memproses gambar e-receipt: Data gambar kosong.',
      );
    }

    try {
      final cleanOrderNum =
          orderNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'BunAtelier_Receipt_$cleanOrderNum';

      if (testSaverOverride != null) {
        await testSaverOverride!(imageBytes, name: fileName);
      } else {
        await Gal.putImageBytes(imageBytes, name: fileName);
      }

      return const ReceiptDownloadResult(
        isSuccess: true,
        message: 'E-Receipt berhasil disimpan ke galeri foto!',
      );
    } on GalException catch (e) {
      debugPrint(
          'ReceiptDownloadService.saveReceiptToGallery GalException: ${e.type.message}');
      if (e.type == GalExceptionType.accessDenied) {
        return const ReceiptDownloadResult(
          isSuccess: false,
          isPermissionDenied: true,
          message:
              'Izin galeri ditolak. Mohon aktifkan izin akses foto di Pengaturan perangkat Anda.',
        );
      } else if (e.type == GalExceptionType.notEnoughSpace) {
        return const ReceiptDownloadResult(
          isSuccess: false,
          message: 'Penyimpanan galeri di perangkat tidak mencukupi.',
        );
      } else {
        return ReceiptDownloadResult(
          isSuccess: false,
          message:
              'Gagal menyimpan e-receipt (${e.type.message}). Silakan coba lagi.',
        );
      }
    } catch (e) {
      debugPrint('ReceiptDownloadService.saveReceiptToGallery generic error: $e');
      return ReceiptDownloadResult(
        isSuccess: false,
        message: 'Gagal menyimpan e-receipt: $e. Silakan coba lagi.',
      );
    }
  }
}
