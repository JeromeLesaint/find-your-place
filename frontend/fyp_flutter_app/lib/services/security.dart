import 'dart:convert'; // For utf8.encode
import 'package:crypto/crypto.dart'; // Add in pubspec.yaml: crypto: ^3.0.3

/// Generates a unique identifier from a secret phrase.
/// - Uses SHA-256 for cryptographic hashing.
/// - Returns a hex string (64 chars) or shortened version if needed.
String generateUniqueId(String secretPhrase, {int length = 64}) {
  if (secretPhrase.trim().isEmpty) {
    throw ArgumentError('Secret phrase cannot be empty.');
  }
  if (length <= 0 || length > 64) {
    throw ArgumentError('Length must be between 1 and 64.');
  }

  // Hash the secret phrase
  final bytes = utf8.encode(secretPhrase);
  final digest = sha256.convert(bytes);

  // Convert to hex string
  final hexString = digest.toString();

  // Return shortened version if requested
  return hexString.substring(0, length);
}