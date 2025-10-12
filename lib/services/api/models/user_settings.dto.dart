class UpdateUserSettingsRequest {
  final String? weightUnit;

  UpdateUserSettingsRequest({this.weightUnit});

  Map<String, dynamic> toJson() {
    return [
      if (weightUnit != null) {'weightUnit': weightUnit},
    ].whereType<MapEntry>().fold({}, (acc, entry) {
      if (entry.key == 'weightUnit') {
        acc['weightUnit'] = entry.value;
      } else if (entry.key == 'age') {
        acc['age'] = entry.value;
      }
      return acc;
    });
  }
}
