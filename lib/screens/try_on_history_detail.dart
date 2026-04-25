import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/save_outfit_dialog.dart';
import 'create_post_screens.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String imageUrl;

  const HistoryDetailScreen({super.key, required this.imageUrl});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImageBytes();
  }

  Future<void> _fetchImageBytes() async {
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.black),
      )
          : Stack(
        fit: StackFit.expand,
        children: [
          if (_imageBytes != null)
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
              child: Container(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "FITTING RESULT",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Hero(
                        tag: widget.imageUrl,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black12, width: 0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "REF: VF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black45,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Text(
                        "AI GENERATED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black45,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.black12, width: 1.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.delete_outline, "DELETE", () {
                        Navigator.pop(context);
                      }),
                      _buildActionButton(Icons.file_download_outlined, "DOWNLOAD", () async {
                        await _saveImageToGallery(_imageBytes!);
                      }),
                      _buildActionButton(Icons.bookmark_border, "SAVE", () async {
                        final result = await showGeneralDialog<bool>(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "Save",
                          pageBuilder: (ctx, a1, a2) => Container(),
                          transitionBuilder: (ctx, a1, a2, child) {
                            return Transform.scale(
                              scale: a1.value,
                              child: SaveOutfitDialog(imageBytes: _imageBytes!),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        );

                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Saved to Wardrobe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.black,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }),
                      _buildActionButton(Icons.ios_share, "SHARE", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreatePostScreen(imageBytes: _imageBytes!),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      if (!await Permission.storage.request().isGranted &&
          !await Permission.photos.request().isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Storage permission required.", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.black,
              action: SnackBarAction(label: "Settings", onPressed: openAppSettings, textColor: Colors.white),
            ),
          );
        }
        return;
      }

      await Gal.putImageBytes(bytes, name: "outfit_${DateTime.now().millisecondsSinceEpoch}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image saved to gallery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save image", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}