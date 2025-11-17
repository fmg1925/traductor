import 'package:flutter/widgets.dart';
import 'package:traductor/l10n/app_localizations.dart';

class ErrorParser {
  static String parseError(String error, BuildContext ctx) {
    final t = AppLocalizations.of(ctx);
    final lower = error.toLowerCase();

    // Timeouts de tu propio código
    if (lower.contains('future not completed')) {
      return t.timeout;
    }

    // 🛜 Errores de red / servidor apagado / CORS / ngrok muerto
    if (lower.contains('xmlhttprequest error') ||       // Web
        lower.contains('net::err_failed') ||            // Web
        lower.contains('failed host lookup') ||         // Android
        lower.contains('connection refused') ||         // genérico
        lower.contains('network is unreachable') ||
        lower.contains('failed to fetch')) {     // genérico
      return t.service_unavailable; // o t.not_found si prefieres
    }

    // Buscar un código HTTP de 3 dígitos en el texto
    final match = RegExp(r'\b(\d{3})\b').firstMatch(error);
    if (match == null) {
      // No hay código HTTP, devolvemos error genérico sin reventar
      return "${t.unknown_error} $error";
    }

    final code = match.group(1)!;

    switch (code) {
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
        return "${t.unknown_error} $code";
    }
  }
}
