class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// No Internet Connection
class OfflineException extends AppException {
  OfflineException([
    super.message = 'Tidak ada koneksi internet. Data disimpan lokal.',
  ]);
}

/// Server Errors (500s, Database failures)
class ServerException extends AppException {
  ServerException([
    super.message = 'Terjadi kesalahan pada server.',
    super.code,
  ]);
}

/// Authentication Errors (Login failed, Unauthorized)
class AppAuthException extends AppException {
  AppAuthException([super.message = 'Otentikasi gagal.', super.code]);
}

/// Validation Errors (Invalid Input, Rule Violation)
class ValidationException extends AppException {
  ValidationException([super.message = 'Data tidak valid.', super.code]);
}

/// Not Found Errors (404)
class NotFoundException extends AppException {
  NotFoundException([super.message = 'Data tidak ditemukan.', super.code]);
}
