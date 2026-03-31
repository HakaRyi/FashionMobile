// lib/models/try_on_model_source.dart
class TryOnModelSource {
  final String? assetPath;
  final String? imageUrl;
  final String? displayName;

  const TryOnModelSource({
    this.assetPath,
    this.imageUrl,
    this.displayName,
  });

  bool get isAsset => assetPath != null && assetPath!.trim().isNotEmpty;
  bool get isNetwork => imageUrl != null && imageUrl!.trim().isNotEmpty;
}