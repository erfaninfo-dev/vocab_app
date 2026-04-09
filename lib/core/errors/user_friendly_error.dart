import 'dart:io';

String userFriendlyErrorMessage(Object error) {
  // Network
  if (error is SocketException) {
    return 'اتصال اینترنت برقرار نیست. لطفاً اینترنت را بررسی کنید.';
  }

  // Common parsing / bad server payload
  if (error is FormatException) {
    return 'دریافت اطلاعات با مشکل مواجه شد. لطفاً دوباره تلاش کنید.';
  }

  final text = error.toString();

  // Avoid leaking raw HTTP codes / stack traces
  if (text.contains('HTTP ') || text.contains('Failed to fetch')) {
    return 'ارتباط با سرور با مشکل مواجه شد. لطفاً دوباره تلاش کنید.';
  }

  // Generic
  return 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.';
}

