class UrlParsingService {
  static Map<String, String>? parseGympadUrl(String url) {
    // Expected format: https://gympad-e44fc.web.app/gymId="gymID"&equipmentId="equipmentId"
    // Also handles localhost for development: http://localhost:8080/#/gymId="gymID"&equipmentId="equipmentId"
    
    try {
      final uri = Uri.parse(url);
      
      // Check if it's a GymPad URL (production or localhost)
      if (!uri.host.contains('gympad-e44fc.web.app') && 
          !uri.host.contains('localhost')) {
        return null;
      }

      // For localhost, check the fragment for parameters
      String pathToCheck = '';
      if (uri.host.contains('localhost') && uri.fragment.isNotEmpty) {
        pathToCheck = Uri.decodeComponent(uri.fragment);
      } else {
        // Decode the path to handle URL encoding
        pathToCheck = Uri.decodeComponent(uri.path);
      }
      
      // Parse with quotes (URL encoded)
      final RegExp gymIdRegex = RegExp(r'gymId="([^"]+)"');
      final RegExp equipmentIdRegex = RegExp(r'equipmentId="([^"]+)"');
      
      final gymIdMatch = gymIdRegex.firstMatch(pathToCheck);
      final equipmentIdMatch = equipmentIdRegex.firstMatch(pathToCheck);
      
      if (gymIdMatch != null && equipmentIdMatch != null) {
        return {
          'gymId': gymIdMatch.group(1)!,
          'equipmentId': equipmentIdMatch.group(1)!,
        };
      }
      
      // Alternative parsing if query parameters are used
      if (uri.queryParameters.isNotEmpty) {
        final gymId = uri.queryParameters['gymId'];
        final equipmentId = uri.queryParameters['equipmentId'];
        
        if (gymId != null && equipmentId != null) {
          return {
            'gymId': gymId,
            'equipmentId': equipmentId,
          };
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}
