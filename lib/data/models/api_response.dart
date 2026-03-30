class ApiResponse<T> {
  final int statusCode;
  final bool succeeded;
  final String _rawMessage;
  final List<String>? errors;
  final T? data;
  final String? meta;

  String get message => _parseErrorMessage(_rawMessage);

  ApiResponse({
    required this.statusCode,
    required this.succeeded,
    required String message,
    this.errors,
    this.data,
    this.meta,
  }) : _rawMessage = message;

  static String _parseErrorMessage(String msg) {
    if (msg.isEmpty) return msg;
    final lower = msg.toLowerCase();
    
    if (lower.contains('socketexception') || lower.contains('failed host lookup') || lower.contains('connection refused')) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مرة أخرى.';
    }
    if (lower.contains('timeoutexception') || lower.contains('connection timeout')) {
      return 'انتهى وقت الاتصال بالخادم. تأكد من جودة الإنترنت.';
    }
    if (lower.contains('clientexception') || lower.contains('httpexception') || lower.contains('connection reset')) {
      return 'فشل الاتصال بالخادم الرئيسي. يرجى المحاولة لاحقاً.';
    }
    if (lower.contains('formatexception')) {
      return 'حدث خطأ غير متوقع أثناء قراءة البيانات.';
    }
    
    // Default fallback pattern if the backend sends something we shouldn't show to user like raw sql error
    if (lower.contains('exception') || lower.contains('error')) {
       // if we want to be safe, we can just return a generic error or the message itself
       // Since the backend might send "Invalid password" which is fine to show.
       // So we keep it as it is if it's not a known ugly flutter networking error.
       return msg;
    }
    
    return msg;
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    // The API can return errors as:
    // - a List<String>: ["error1", "error2"]
    // - a Map<String, List>: {"field": ["error1"]}  (ASP.NET validation format)
    List<String>? parsedErrors;
    final rawErrors = json['errors'];
    if (rawErrors != null) {
      if (rawErrors is List) {
        parsedErrors = List<String>.from(rawErrors);
      } else if (rawErrors is Map) {
        // Flatten all error messages from the map values
        parsedErrors = rawErrors.values
            .expand((v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
            .toList();
      }
    }

    return ApiResponse<T>(
      statusCode: json['statusCode'] ?? json['status'] ?? 0,
      succeeded: json['succeeded'] ?? false,
      message: json['message'] ?? json['title'] ?? '',
      errors: parsedErrors,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      meta: json['meta']?.toString(),
    );
  }
}
