import 'package:dio/dio.dart';

/// Fungsi murni: mengubah DioException menjadi pesan ramah pengguna.
/// UI hanya menerima pesan (String), bukan exception mentah.
String friendlyApiError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Sesi habis. Silakan login ulang.';
        if (code == 403) return 'Akses ditolak.';
        if (code == 404) return 'Data tidak ditemukan.';
        if (code == 500) return 'Server bermasalah. Coba lagi nanti.';
        return 'Terjadi kesalahan ($code). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga.';
}