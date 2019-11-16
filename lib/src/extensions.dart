import 'package:version/version.dart';

/// Checks if a String is null or empty after trimming whitespace characters
bool isNullOrBlank(String str) {
  return str == null || str.isBlank;
}

extension VersionCopyWith on Version {
  /// Copy Version with properties overwritten by parameters
  Version copyWith({int major, int minor, int patch, List<String> preRelease, String build}) {
    return Version(major ?? this.major, minor ?? this.minor, patch ?? this.patch,
        preRelease: preRelease ?? this.preRelease, build: build ?? this.build);
  }
}

extension StringIsBlank on String {
  /// Whether this String is empty with whitespace characters trimmed
  bool get isBlank => trim().isEmpty;
}
