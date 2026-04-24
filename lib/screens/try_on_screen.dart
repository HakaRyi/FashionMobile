import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:fashion_mobile/screens/deposit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import 'dart:typed_data';
import '../constants/notification_type.dart';
import '../services/item_service.dart';
import '../utils/app_notification.dart';
import '../utils/global_event_bus.dart';
import '../utils/model_manager.dart';
import '../widgets/price_info_widget.dart';
import '../utils/try_on_manager.dart';
import './create_post_screens.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/save_outfit_dialog.dart';
import 'package:path_provider/path_provider.dart';
import '../models/try_on_source_item.dart';
import '../models/try_on_model_source.dart';
import '../widgets/try_on/wardrobe_bottom_sheet.dart';
import '../widgets/try_on/model_outfit_bottom_sheet.dart';
import '../widgets/try_on/cloth_selection_row.dart';
import '../widgets/try_on/try_on_history_list.dart';
import '../widgets/try_on/try_on_image_preview.dart';
import '../services/wallet_service.dart';

class TryOnScreen extends StatefulWidget {
  final TryOnSourceItem? sourceItem;

  const TryOnScreen({
    super.key,
    this.sourceItem,
  });

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  File? selectedClothFile;
  final ImagePicker _picker = ImagePicker();
  String? _selectedNetworkClothUrl;
  String? _selectedClothName;
  bool _isPreparingNetworkCloth = false;
  int? _selectedCategoryId;

  List<dynamic> _myWardrobeItems = [];
  bool _isLoadingWardrobe = true;
  List<dynamic> _myOutfits = [];
  bool _isLoadingOutfits = true;

  final WalletService _walletService = WalletService();
  double _currentBalance = 0;
  final double _tryOnCost = 5000;
  bool _isLoadingBalance = true;
  final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

  TryOnModelSource _selectedModel = const TryOnModelSource(
    assetPath: "assets/images/human1.jpg",
    displayName: "Default Model",
  );

  @override
  void initState() {
    super.initState();
    modelManager.fetchMyModels();
    tryOnManager.fetchHistory();
    _fetchWardrobeItems();
    _fetchMyOutfits();
    _fetchWalletBalance();

    if (widget.sourceItem != null) {
      _selectedNetworkClothUrl = widget.sourceItem!.imageUrl;
      _selectedClothName = widget.sourceItem!.itemName;
      _selectedCategoryId = _mapCategoryToInt(widget.sourceItem!.category ?? '');
    }
  }

  int _mapCategoryToInt(String category) {
    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('lower') || lowerCat.contains('pants') || lowerCat.contains('shorts') || lowerCat.contains('skirt') || lowerCat.contains('lower_body')) return 1;
    if (lowerCat.contains('full') || lowerCat.contains('dress') || lowerCat.contains('full_body')) return 2;
    return 0;
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final balance = await _walletService.getMyWalletBalance();
      if (mounted) setState(() { _currentBalance = balance; _isLoadingBalance = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _fetchMyOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Outfit/my-outfits'), headers: {"Content-Type": "application/json", "Authorization": "Bearer $token", "ngrok-skip-browser-warning": "69420"});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() { _myOutfits = data['data'] ?? []; _isLoadingOutfits = false; });
      } else if (mounted) setState(() => _isLoadingOutfits = false);
    } catch (e) { if (mounted) setState(() => _isLoadingOutfits = false); }
  }

  Future<void> _fetchWardrobeItems() async {
    try {
      final response = await ItemService().getMyItemsPaginated(1, 50);
      if (mounted) {
        setState(() {
          _myWardrobeItems = response['items'] ?? [];
          _isLoadingWardrobe = false;
        });
      }
    } catch (e) { if (mounted) setState(() => _isLoadingWardrobe = false); }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) setState(() { selectedClothFile = File(pickedFile.path); _selectedNetworkClothUrl = null; _selectedClothName = null; _selectedCategoryId = null; });
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<File?> _downloadNetworkImageToTempFile(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/public_item_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) { return null; }
  }

  Future<void> _handleStartTryOn() async {
    if (tryOnManager.isProcessing) return;
    String? clothPath;
    if (selectedClothFile != null) {
      clothPath = selectedClothFile!.path;
    } else if (_selectedNetworkClothUrl != null && _selectedNetworkClothUrl!.trim().isNotEmpty) {
      setState(() => _isPreparingNetworkCloth = true);
      final downloadedFile = await _downloadNetworkImageToTempFile(_selectedNetworkClothUrl!);
      setState(() => _isPreparingNetworkCloth = false);
      if (downloadedFile == null) {
        if (!mounted) return;
        NotificationService.show(context, title: "Error", message: "Failed to download the item.", type: NotificationType.error);
        return;
      }
      clothPath = downloadedFile.path;
    }

    if (clothPath == null || clothPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an item before trying on.'), backgroundColor: Colors.orange));
      return;
    }

    if (mounted) NotificationService.show(context, title: "Success", message: "Processing in background. You can continue browsing.", type: NotificationType.success);

    await tryOnManager.startTryOn(context, modelAssetPath: _selectedModel.isAsset ? _selectedModel.assetPath : null, modelImageUrl: _selectedModel.isNetwork ? _selectedModel.imageUrl : null, clothFilePath: clothPath, category: _selectedCategoryId);
    await _fetchWalletBalance();
  }

  void _showFullWardrobeBottomSheet() {
    showModalBottomSheet(context: context, backgroundColor: AppColors.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return WardrobeBottomSheet(wardrobeItems: _myWardrobeItems, onSelect: (url, name, category) {
        setState(() { selectedClothFile = null; _selectedNetworkClothUrl = url; _selectedClothName = name; _selectedCategoryId = _mapCategoryToInt(category); });
      });
    });
  }

  void _showModelSelectionBottomSheet() {
    showModalBottomSheet(context: context, backgroundColor: AppColors.background, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) {
      return ModelOutfitBottomSheet(outfits: _myOutfits, isLoadingOutfits: _isLoadingOutfits, onSelectModel: (model) {
        setState(() => _selectedModel = model);
        HapticFeedback.lightImpact();
      });
    });
  }

  void _clearTryOnResult() {
    tryOnManager.resetResult();
    setState(() { selectedClothFile = null; _selectedNetworkClothUrl = null; _selectedClothName = null; _selectedCategoryId = null; });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelectedCloth = selectedClothFile != null || (_selectedNetworkClothUrl != null && _selectedNetworkClothUrl!.trim().isNotEmpty);
    bool isNotEnoughBalance = !_isLoadingBalance && _currentBalance < _tryOnCost;
    bool canProceed = hasSelectedCloth && !isNotEnoughBalance && !_isPreparingNetworkCloth;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VIRTUAL STUDIO",
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0),
        ),
      ),
      body: ListenableBuilder(
        listenable: tryOnManager,
        builder: (context, child) {
          final isProcessing = tryOnManager.isProcessing;
          final resultBytes = tryOnManager.resultImageBytes;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // PREVIEW SECTION
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 16),
                        child: TryOnImagePreview(
                          resultBytes: resultBytes,
                          isProcessing: isProcessing,
                          selectedModel: _selectedModel,
                          hasSelectedCloth: hasSelectedCloth,
                          selectedClothFile: selectedClothFile,
                          selectedNetworkClothUrl: _selectedNetworkClothUrl,
                          onRemoveCloth: () {
                            setState(() { selectedClothFile = null; _selectedNetworkClothUrl = null; _selectedClothName = null; _selectedCategoryId = null; });
                          },
                          onEditModel: _showModelSelectionBottomSheet,
                        ),
                      ),
                    ),

                    // ACTIONS (After processing)
                    if (resultBytes != null && !isProcessing)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _actionIconBtn(Icons.refresh_rounded, "Clear", Colors.black87, _clearTryOnResult),
                                _actionIconBtn(Icons.download_rounded, "Download", Colors.black87, () async { await _saveImageToGallery(resultBytes); _clearTryOnResult(); }),
                                _actionIconBtn(Icons.bookmark_outline_rounded, "Save", Colors.black87, () async {
                                  final result = await showGeneralDialog<bool>(context: context, barrierDismissible: true, barrierLabel: "Save", pageBuilder: (ctx, a1, a2) => Container(), transitionBuilder: (ctx, a1, a2, child) => Transform.scale(scale: a1.value, child: SaveOutfitDialog(imageBytes: resultBytes)), transitionDuration: const Duration(milliseconds: 300));
                                  if (result == true && context.mounted) { NotificationService.show(context, title: "Success", message: "Saved to wardrobe", type: NotificationType.success); _clearTryOnResult(); }
                                }),
                                _actionIconBtn(Icons.ios_share_rounded, "Share", Colors.black87, () { Navigator.push(context, MaterialPageRoute(builder: (context) => CreatePostScreen(imageBytes: resultBytes))).then((_) => _clearTryOnResult()); }),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // CLOTH SELECTION AND HISTORY
                    if (resultBytes == null && !isProcessing)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("SELECT CLOTHING", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0)),
                                    GestureDetector(
                                      onTap: _showModelSelectionBottomSheet,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.face_retouching_natural, size: 14, color: Colors.black87),
                                            const SizedBox(width: 4),
                                            Text(_selectedModel.displayName ?? 'Default Model', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              ClothSelectionRow(
                                wardrobeItems: _myWardrobeItems,
                                isLoading: _isLoadingWardrobe,
                                onPickImage: _pickImage,
                                onShowFullWardrobe: _showFullWardrobeBottomSheet,
                                onSelectCloth: (url, name, category) {
                                  setState(() { selectedClothFile = null; _selectedNetworkClothUrl = url; _selectedClothName = name; _selectedCategoryId = _mapCategoryToInt(category); });
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                                child: Text("TRY-ON HISTORY", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0)),
                              ),
                              const TryOnHistoryList(),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // BOTTOM ACTION BAR
              if (resultBytes == null && !isProcessing)
                _buildStickyBottomBar(isNotEnoughBalance, canProceed, isProcessing),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStickyBottomBar(bool isNotEnoughBalance, bool canProceed, bool isProcessing) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, -5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL COST", style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0)),
                const SizedBox(height: 2),
                Text(
                  "${currencyFormatter.format(_tryOnCost)} ₫",
                  style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 12, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      "Balance: ${_isLoadingBalance ? "..." : "${currencyFormatter.format(_currentBalance)} ₫"}",
                      style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildMainButton(
            isNotEnoughBalance: isNotEnoughBalance,
            canProceed: canProceed,
            isProcessing: isProcessing,
            onPressed: isNotEnoughBalance
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => DepositScreen())).then((_) => _fetchWalletBalance())
                : (canProceed && !isProcessing ? _handleStartTryOn : null),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton({
    required bool isNotEnoughBalance,
    required bool canProceed,
    required bool isProcessing,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: !canProceed || isProcessing ? Colors.black12 : Colors.black,
          boxShadow: !canProceed || isProcessing ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNotEnoughBalance ? "DEPOSIT" : (_isPreparingNetworkCloth ? "PREPARING" : (isProcessing ? "PROCESSING" : "TRY IT ON")),
              style: TextStyle(
                color: !canProceed || isProcessing ? Colors.black45 : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            if (canProceed && !isProcessing && !isNotEnoughBalance) ...[
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ]
          ],
        ),
      ),
    );
  }

  Widget _actionIconBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveImageToGallery(Uint8List bytes) async {
    try {
      if (!await Permission.storage.request().isGranted && !await Permission.photos.request().isGranted && !await Permission.manageExternalStorage.request().isGranted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Please grant photo access permissions in Settings."), action: SnackBarAction(label: "Open Settings", onPressed: openAppSettings)));
        return;
      }
      await Gal.putImageBytes(bytes, name: "outfit_${DateTime.now().millisecondsSinceEpoch}");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to gallery successfully!"), backgroundColor: Colors.black, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    }
  }
}