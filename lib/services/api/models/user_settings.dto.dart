class UpdateUserSettingsRequest {
  final String? weightUnit;

  UpdateUserSettingsRequest({this.weightUnit});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> body = {};
    if (weightUnit != null) {
      body['weightUnit'] = weightUnit;
    }
    return body;
  }
}

class UpdateUserSettingsResponse {
  final String etag;

  UpdateUserSettingsResponse({required this.etag});

  factory UpdateUserSettingsResponse.fromJson(Map<String, dynamic> json) =>
      UpdateUserSettingsResponse(etag: json['etag'] as String);
}
