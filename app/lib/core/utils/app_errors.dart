import 'dart:io';

class AppErrors {
  AppErrors._();

  static String humanize(dynamic error) {
    if (error == null) return 'Something went wrong. Try again.';

    final s = error.toString().toLowerCase();

    // Network / connectivity
    if (error is SocketException ||
        s.contains('socketexception') ||
        s.contains('network_request_failed') ||
        s.contains('failed host lookup') ||
        s.contains('connection refused') ||
        s.contains('no route to host')) {
      return 'No internet connection. Check your network and try again.';
    }

    if (s.contains('timeout') || s.contains('timed out')) {
      return 'The request timed out. Check your connection and try again.';
    }

    // Auth
    if (s.contains('invalid login credentials') ||
        s.contains('invalid_credentials')) {
      return 'Incorrect phone number or password.';
    }
    if (s.contains('email not confirmed') ||
        s.contains('user not confirmed')) {
      return 'Account not verified. Contact support.';
    }
    if (s.contains('unauthorized') ||
        s.contains('401') ||
        s.contains('not authenticated')) {
      return 'You are not signed in. Please log in again.';
    }
    if (s.contains('403') || s.contains('permission denied') ||
        s.contains('forbidden')) {
      return 'You don\'t have permission to do that.';
    }

    // Conflict / duplicates
    if (s.contains('unique') || s.contains('duplicate') ||
        s.contains('already exists') || s.contains('23505')) {
      return 'This record already exists.';
    }

    // Not found
    if (s.contains('404') || s.contains('not found')) {
      return 'The requested item was not found.';
    }

    // Server errors
    if (s.contains('500') || s.contains('internal server')) {
      return 'A server error occurred. Try again in a moment.';
    }

    // Offline sync
    if (s.contains('offline') || s.contains('no connection')) {
      return 'You\'re offline. Your changes will sync when the internet returns.';
    }

    // Storage / upload
    if (s.contains('storage') || s.contains('upload') ||
        s.contains('file too large')) {
      return 'Image upload failed. Check your connection and try again.';
    }

    return 'Something went wrong. Try again.';
  }
}
