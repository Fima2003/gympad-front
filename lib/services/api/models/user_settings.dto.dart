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
