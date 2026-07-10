/// The TripleCheck dataset stores code snippets and references as HTML
/// fragments. Nothing here renders HTML — these helpers recover the plain text
/// and the one piece of structure that matters, the anchor's target.
library;

const Map<String, String> _entities = <String, String>{
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};

final RegExp _entityPattern = RegExp(r'&(#x?[0-9a-fA-F]+|\w+);');
final RegExp _tagPattern = RegExp(r'<[^>]*>');
final RegExp _hrefPattern = RegExp(r'''href\s*=\s*["']([^"']+)["']''');

String unescapeHtml(String value) {
  return value.replaceAllMapped(_entityPattern, (match) {
    final body = match.group(1)!;
    if (body.startsWith('#x') || body.startsWith('#X')) {
      final code = int.tryParse(body.substring(2), radix: 16);
      return code == null ? match.group(0)! : String.fromCharCode(code);
    }
    if (body.startsWith('#')) {
      final code = int.tryParse(body.substring(1));
      return code == null ? match.group(0)! : String.fromCharCode(code);
    }
    return _entities[body.toLowerCase()] ?? match.group(0)!;
  });
}

/// Plain text of an HTML fragment, tags removed and entities resolved.
String stripHtml(String value) =>
    unescapeHtml(value.replaceAll(_tagPattern, '')).trim();

/// The `href` of the first anchor, if there is one.
String? hrefOf(String value) => _hrefPattern.firstMatch(value)?.group(1);

/// A reference as it should be displayed: its label, and the URL behind it.
({String label, String? url}) parseReference(String value) =>
    (label: stripHtml(value), url: hrefOf(value));
