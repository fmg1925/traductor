import 'package:flutter/widgets.dart';
import 'package:traductor/l10n/app_localizations.dart';

class ErrorParser {
  static String parseError(String error, BuildContext ctx) {
    final t = AppLocalizations.of(ctx);
    int idx = error.indexOf(RegExp('\\d+'));
    if (error.toLowerCase().contains('future not completed')) return t.timeout;
    error = error.substring(idx, idx + 3);
    switch (error) {
      case '400':
        return t.bad_request;
      case '401':
        return t.unauthorized;
      case '403':
        return t.forbidden;
      case '404':
        return t.not_found; // Server offline / no encontrado
      case '405':
        return t.method_not_allowed;
      case '408':
        return t.timeout;
      case '409':
        return t.conflict;
      case '422':
        return t.unprocessable_entity;
      case '429':
        return t.too_many_requests;
      case '500':
        return t.server_error;
      case '502':
        return t.bad_gateway;
      case '503':
        return t.service_unavailable;
      case '504':
        return t.gateway_timeout;
      default:
        return "${t.unknown_error} $error";
    }
  }
}
