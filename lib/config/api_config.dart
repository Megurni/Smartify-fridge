/// Web builds use the page's own origin, with Nginx forwarding /api/.
/// An explicit SMARTIFY_API_URL still supports direct backend development.
String resolveApiBaseUrl({
  required bool isWeb,
  required String nativeDefaultUrl,
  String configuredUrl = '',
  Uri? pageUrl,
}) {
  if (isWeb) {
    return (pageUrl ?? Uri.base)
        .resolve(configuredUrl.isEmpty ? '/api/' : configuredUrl)
        .toString();
  }
  return configuredUrl.isEmpty ? nativeDefaultUrl : configuredUrl;
}
