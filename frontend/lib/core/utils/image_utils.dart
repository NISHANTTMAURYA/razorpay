/// Utility to upgrade CDN thumbnails (Amazon, Flipkart, Unsplash) into high-definition studio assets.
String getHighResImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) {
    return 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=1200&q=85&auto=format&fit=crop';
  }

  String url = rawUrl.trim();

  // 1. Amazon CDN HD Upgrade:
  // Strips thumbnail modifier (e.g. ._AC_UL320_., ._AC_UY218_., ._AC_SR38,50_., ._SL75_.)
  // and requests full 1500px HD resolution (._AC_SL1500_.)
  if (url.contains('media-amazon.com') ||
      url.contains('images-amazon.com') ||
      url.contains('ssl-images-amazon.com')) {
    return url.replaceAll(RegExp(r'\._[A-Za-z0-9_,-]+_\.'), '._AC_SL1500_.');
  }

  // 2. Flipkart CDN HD Upgrade:
  if (url.contains('rukminim') || url.contains('flipkart.com')) {
    return url.replaceAll(RegExp(r'/image/\d+/\d+/'), '/image/832/832/');
  }

  // 3. Unsplash HD Upgrade:
  if (url.contains('unsplash.com')) {
    final base = url.split('?').first;
    return '$base?w=1200&q=85&auto=format&fit=crop';
  }

  return url;
}
