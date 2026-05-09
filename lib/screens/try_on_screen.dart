import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import 'dart:async';

import 'package:fashion_mobile/screens/deposit_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../constants/notification_type.dart';
import '../utils/app_notification.dart';
import '../utils/app_toast.dart';
import '../utils/global_event_bus.dart';
import '../utils/model_manager.dart';
import '../utils/try_on_manager.dart';
import './create_post_screens.dart';
import '../widgets/save_outfit_dialog.dart';
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

class _TryOnScreenState extends State<TryOnScreen> with TickerProviderStateMixin {
  File? selectedClothFile;
  final int currentBalance = 0;
  final int tryOnCost = 0;
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

  TryOnModelSource _selectedModel = const TryOnModelSource(
    assetPath: "assets/images/human1.jpg",
    displayName: "Default Model",
  );

  late AnimationController _curtainController;
  late Animation<double> _curtainAnimation;
  late AnimationController _magicController;
  late AnimationController _progressController;
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;
  bool _wasProcessing = false;

  @override
  void initState() {
    super.initState();

    _curtainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _curtainAnimation = CurvedAnimation(
      parent: _curtainController,
      curve: Curves.easeInOutCubic,
    );

    _magicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _sweepAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: _sweepController,
        curve: Curves.easeInOutSine,
      ),
    );

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _sweepController.forward(from: 0.0);
      }
    });

    modelManager.fetchMyModels();
    tryOnManager.fetchHistory();
    tryOnManager.addListener(_onTryOnStateChanged);

    _fetchWardrobeItems();
    _fetchMyOutfits();
    _fetchWalletBalance();

    if (widget.sourceItem != null) {
      _selectedNetworkClothUrl = widget.sourceItem!.imageUrl;
      _selectedClothName = widget.sourceItem!.itemName;
      _selectedCategoryId = _mapCategoryToInt(
        widget.sourceItem!.category ?? '',
      );
    }

    if (tryOnManager.isProcessing) {
      _curtainController.value = 1.0;
      _magicController.repeat();
      _progressController.forward();
      _wasProcessing = true;
    }
  }

  @override
  void dispose() {
    tryOnManager.removeListener(_onTryOnStateChanged);
    _curtainController.dispose();
    _magicController.dispose();
    _progressController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  void _onTryOnStateChanged() {
    final isProcessing = tryOnManager.isProcessing;

    if (isProcessing && !_wasProcessing) {
      _curtainController.forward();
      _magicController.repeat();
      _progressController.forward(from: 0.0);
    } else if (!isProcessing && _wasProcessing) {
      _magicController.stop();
      _progressController.stop();
      _curtainController.reverse();
    }

    _wasProcessing = isProcessing;
  }

  int _mapCategoryToInt(String category) {
    final lowerCat = category.toLowerCase();

    if (lowerCat.contains('lower') ||
        lowerCat.contains('pants') ||
        lowerCat.contains('shorts') ||
        lowerCat.contains('skirt') ||
        lowerCat.contains('lower_body')) {
      return 1;
    }

    if (lowerCat.contains('full') ||
        lowerCat.contains('dress') ||
        lowerCat.contains('full_body')) {
      return 2;
    }

    return 0;
  }

  String _mapTryOnBackendError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('spending limit') ||
        message.contains('monthly limit') ||
        message.contains('limit exceeded')) {
      return 'You have reached your monthly spending limit.';
    }

    if (message.contains('insufficient') ||
        message.contains('not enough') ||
        message.contains('balance')) {
      return 'Your wallet balance is not enough. Please top up and try again.';
    }

    if (message.contains('unauthorized') || message.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }

    if (message.contains('forbidden') || message.contains('403')) {
      return 'You do not have permission to use this feature.';
    }

    if (message.contains('timeout')) {
      return 'Try-on request timed out. Please try again.';
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    return 'Try-on failed. Please try again later.';
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final balance = await _walletService.getMyWalletBalance();

      if (mounted) {
        setState(() {
          _currentBalance = balance;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  Future<void> _fetchMyOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Outfit/my-outfits'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "69420",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _myOutfits = data['data'] ?? [];
            _isLoadingOutfits = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingOutfits = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOutfits = false);
      }
    }
  }

  Future<void> _fetchWardrobeItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllMyItemsEndpoint}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "ngrok-skip-browser-warning": "69420",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _myWardrobeItems = data['data'] ?? [];
            _isLoadingWardrobe = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingWardrobe = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWardrobe = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          selectedClothFile = File(pickedFile.path);
          _selectedNetworkClothUrl = null;
          _selectedClothName = null;
          _selectedCategoryId = null;
        });
      }
    } catch (e) {}
  }

  Future<File?> _downloadNetworkImageToTempFile(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/public_item_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleStartTryOn() async {
    if (tryOnManager.isProcessing) {
      return;
    }

    String? clothPath;

    if (selectedClothFile != null) {
      clothPath = selectedClothFile!.path;
    } else if (_selectedNetworkClothUrl != null &&
        _selectedNetworkClothUrl!.trim().isNotEmpty) {
      setState(() => _isPreparingNetworkCloth = true);

      final downloadedFile = await _downloadNetworkImageToTempFile(
        _selectedNetworkClothUrl!,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isPreparingNetworkCloth = false);

      if (downloadedFile == null) {
        NotificationService.show(
          context,
          title: "Error",
          message: "Failed to load item for try-on",
          type: NotificationType.error,
        );
        return;
      }

      clothPath = downloadedFile.path;
    }

    if (clothPath == null || clothPath.trim().isEmpty) {
      NotificationService.show(
        context,
        title: "Notification",
        message: "Please select an item before trying on",
        type: NotificationType.info,
      );
      return;
    }

    try {
      await tryOnManager.startTryOn(
        context,
        modelAssetPath: _selectedModel.isAsset ? _selectedModel.assetPath : null,
        modelImageUrl: _selectedModel.isNetwork ? _selectedModel.imageUrl : null,
        clothFilePath: clothPath,
        category: _selectedCategoryId,
      );

      if (mounted) {
        NotificationService.show(
          context,
          title: "Success",
          message: "Processing in the background. You can browse other items!",
          type: NotificationType.success,
        );
      }

      await _fetchWalletBalance();
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.showError(
        context,
        _mapTryOnBackendError(e),
      );
    }
  }

  void _showFullWardrobeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return WardrobeBottomSheet(
          wardrobeItems: _myWardrobeItems,
          onSelect: (url, name, category) {
            setState(() {
              selectedClothFile = null;
              _selectedNetworkClothUrl = url;
              _selectedClothName = name;
              _selectedCategoryId = _mapCategoryToInt(category);
            });
          },
        );
      },
    );
  }

  void _showModelSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ModelOutfitBottomSheet(
          outfits: _myOutfits,
          isLoadingOutfits: _isLoadingOutfits,
          onSelectModel: (model) {
            setState(() => _selectedModel = model);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Selected ${_selectedModel.displayName}",
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.black,
              ),
            );
          },
        );
      },
    );
  }

  void _clearTryOnResult() {
    tryOnManager.resetResult();

    setState(() {
      selectedClothFile = null;
      _selectedNetworkClothUrl = null;
      _selectedClothName = null;
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelectedCloth = selectedClothFile != null ||
        (_selectedNetworkClothUrl != null &&
            _selectedNetworkClothUrl!.trim().isNotEmpty);

    bool isNotEnoughBalance = !_isLoadingBalance && _currentBalance < _tryOnCost;
    bool canProceed =
        hasSelectedCloth && !isNotEnoughBalance && !_isPreparingNetworkCloth;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VIRTUAL TRY-ON",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: Colors.black),
            onPressed: () {
              if (_curtainController.status == AnimationStatus.completed ||
                  _curtainController.status == AnimationStatus.forward) {
                _magicController.stop();
                _progressController.stop();
                _curtainController.reverse();
              } else {
                _curtainController.forward();
                _magicController.repeat();
                _progressController.forward(from: 0.0);
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: tryOnManager,
        builder: (context, child) {
          final isProcessing = tryOnManager.isProcessing;
          final resultBytes = tryOnManager.resultImageBytes;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          TryOnImagePreview(
                            resultBytes: resultBytes,
                            isProcessing: isProcessing,
                            selectedModel: _selectedModel,
                            hasSelectedCloth: hasSelectedCloth,
                            selectedClothFile: selectedClothFile,
                            selectedNetworkClothUrl: _selectedNetworkClothUrl,
                            onRemoveCloth: () {
                              setState(() {
                                selectedClothFile = null;
                                _selectedNetworkClothUrl = null;
                                _selectedClothName = null;
                                _selectedCategoryId = null;
                              });
                            },
                            onEditModel: _showModelSelectionBottomSheet,
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _curtainAnimation,
                                builder: (context, child) {
                                  final val = _curtainAnimation.value;

                                  if (val == 0.0) {
                                    return const SizedBox.shrink();
                                  }

                                  final width =
                                      MediaQuery.of(context).size.width / 2;

                                  return Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: width * val,
                                        child: ClipRect(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 12,
                                              sigmaY: 12,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.black.withOpacity(0.9),
                                                    Colors.black.withOpacity(0.6),
                                                  ],
                                                ),
                                                border: Border(
                                                  right: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.15),
                                                    width: 1,
                                                  ),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: const Offset(10, 0),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: width * val,
                                        child: ClipRect(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 12,
                                              sigmaY: 12,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.black.withOpacity(0.6),
                                                    Colors.black.withOpacity(0.9),
                                                  ],
                                                ),
                                                border: Border(
                                                  left: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.15),
                                                    width: 1,
                                                  ),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.4),
                                                    blurRadius: 20,
                                                    offset: const Offset(-10, 0),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (val > 0.8)
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _magicController,
                                            builder: (context, child) {
                                              return CustomPaint(
                                                painter: StageMagicPainter(
                                                  _magicController.value,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      if (val > 0.8)
                                        Positioned(
                                          left: 40,
                                          right: 40,
                                          bottom: 40,
                                          child: AnimatedBuilder(
                                            animation: _progressController,
                                            builder: (context, child) {
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRect(
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                        sigmaX: 2,
                                                        sigmaY: 2,
                                                      ),
                                                      child: const Text(
                                                        "AI IS FITTING YOUR OUTFIT...",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                          FontWeight.w900,
                                                          letterSpacing: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  ClipRRect(
                                                    borderRadius:
                                                    BorderRadius.circular(10),
                                                    child: LinearProgressIndicator(
                                                      value:
                                                      _progressController.value,
                                                      backgroundColor: Colors.white
                                                          .withOpacity(0.2),
                                                      valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(
                                                        Colors.white,
                                                      ),
                                                      minHeight: 4,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "${(_progressController.value * 100).toInt()}%",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      if (val > 0.8)
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _sweepAnimation,
                                            builder: (context, child) {
                                              return CustomPaint(
                                                painter: MirrorSweepPainter(
                                                  _sweepAnimation.value,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (resultBytes != null && !isProcessing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _actionButton(
                                Icons.delete_outline,
                                "DELETE",
                                Colors.black,
                                _clearTryOnResult,
                              ),
                              _actionButton(
                                Icons.file_download_outlined,
                                "DOWNLOAD",
                                Colors.black,
                                    () async {
                                  await _saveImageToGallery(resultBytes);
                                  _clearTryOnResult();
                                },
                              ),
                              _actionButton(
                                Icons.save_alt_outlined,
                                "SAVE",
                                Colors.black,
                                    () async {
                                  final result = await showGeneralDialog<bool>(
                                    context: context,
                                    barrierDismissible: true,
                                    barrierLabel: "Save",
                                    pageBuilder: (ctx, a1, a2) => Container(),
                                    transitionBuilder: (ctx, a1, a2, child) {
                                      return Transform.scale(
                                        scale: a1.value,
                                        child: SaveOutfitDialog(
                                          imageBytes: resultBytes,
                                        ),
                                      );
                                    },
                                    transitionDuration:
                                    const Duration(milliseconds: 300),
                                  );

                                  if (result == true && context.mounted) {
                                    NotificationService.show(
                                      context,
                                      title: "Success",
                                      message: "Saved to wardrobe successfully",
                                      type: NotificationType.success,
                                    );
                                    _clearTryOnResult();
                                  }
                                },
                              ),
                              _actionButton(
                                Icons.share_outlined,
                                "SHARE",
                                Colors.black,
                                    () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreatePostScreen(
                                        imageBytes: resultBytes,
                                      ),
                                    ),
                                  ).then((_) => _clearTryOnResult());
                                },
                              ),
                            ],
                          ),
                        ),
                      if (resultBytes == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.black,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Model: ${_selectedModel.displayName ?? 'Default Model'}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (resultBytes == null) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            "SELECT ITEM",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        ClothSelectionRow(
                          wardrobeItems: _myWardrobeItems,
                          isLoading: _isLoadingWardrobe,
                          onPickImage: _pickImage,
                          onShowFullWardrobe: _showFullWardrobeBottomSheet,
                          onSelectCloth: (url, name, category) {
                            setState(() {
                              selectedClothFile = null;
                              _selectedNetworkClothUrl = url;
                              _selectedClothName = name;
                              _selectedCategoryId = _mapCategoryToInt(category);
                            });
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            "TRY-ON HISTORY",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const TryOnHistoryList(),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              if (resultBytes == null)
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "BALANCE",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLoadingBalance
                                  ? "..."
                                  : "${_currentBalance.toInt()} VND",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "COST",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${_tryOnCost.toInt()} VND",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 54,
                        width: MediaQuery.of(context).size.width * 0.45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isNotEnoughBalance
                              ? Colors.black54
                              : (canProceed && !isProcessing
                              ? Colors.black
                              : Colors.black12),
                        ),
                        child: ElevatedButton(
                          onPressed: isNotEnoughBalance
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DepositScreen(),
                              ),
                            ).then((_) => _fetchWalletBalance());
                          }
                              : (canProceed && !isProcessing
                              ? _handleStartTryOn
                              : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isNotEnoughBalance
                                ? "TOP UP"
                                : (_isPreparingNetworkCloth
                                ? "PREPARING..."
                                : "TRY IT ON"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionButton(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.1),
              ),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
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
          !await Permission.photos.request().isGranted &&
          !await Permission.manageExternalStorage.request().isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Storage permission required.",
                style: TextStyle(color: Colors.white),
              ),
              action: SnackBarAction(
                label: "Settings",
                onPressed: openAppSettings,
                textColor: Colors.white,
              ),
              backgroundColor: Colors.black,
            ),
          );
        }
        return;
      }

      await Gal.putImageBytes(
        bytes,
        name: "outfit_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Image saved to gallery successfully!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error saving image: ${e.type.message}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unknown error: $e",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }
}

class StageMagicPainter extends CustomPainter {
  final double animationValue;

  StageMagicPainter(this.animationValue);

  void drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    Path path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final centerX = size.width / 2;
    final wandX = centerX;
    final wandY = size.height / 2 + math.sin(animationValue * 2 * math.pi) * 10;

    const Color paleYellowWhite = Color(0xFFFFFDE7);
    const Color pureWhite = Colors.white;

    final double gradientRadius = 50.0;
    final Paint shaderPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFDF2B7).withOpacity(0.8),
          pureWhite.withOpacity(0.7),
          pureWhite.withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(wandX, wandY),
          radius: gradientRadius,
        ),
      );

    canvas.drawCircle(
      Offset(wandX, wandY),
      gradientRadius,
      shaderPaint,
    );

    final Paint starPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: const [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.red,
        ],
        transform: GradientRotation(animationValue * 2 * math.pi),
      ).createShader(
        Rect.fromCircle(
          center: Offset(wandX, wandY),
          radius: 15,
        ),
      );

    drawDiamond(
      canvas,
      Offset(wandX, wandY),
      15,
      starPaint,
    );

    final Paint dustPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      double speed = 0.5 + random.nextDouble() * 1.5;
      double yProgress = (animationValue * speed + random.nextDouble()) % 1.0;

      double angle = random.nextDouble() * 2 * math.pi;
      double radius = 40 + (size.width / 2 - 40) * math.pow(yProgress, 1.2);

      double dropX = wandX + radius * math.cos(angle);
      double dropY = wandY + radius * math.sin(angle);

      double diamondSize = random.nextDouble() * 5 + 2.0;

      final opacity = (1.0 - yProgress) *
          (0.5 + 0.5 * math.sin((animationValue * 10 + i) * math.pi));

      Color dustColor = random.nextDouble() < 0.2 ? paleYellowWhite : pureWhite;
      dustPaint.color = dustColor.withOpacity(
        opacity.clamp(0.0, 1.0),
      );

      drawDiamond(
        canvas,
        Offset(dropX, dropY),
        diamondSize,
        dustPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StageMagicPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class MirrorSweepPainter extends CustomPainter {
  final double sweepProgress;

  MirrorSweepPainter(this.sweepProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        25,
      );

    canvas.save();
    canvas.translate(size.width * sweepProgress, 0);
    canvas.drawRect(
      Rect.fromLTWH(
        -size.width,
        0,
        size.width * 2,
        size.height,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MirrorSweepPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress;
  }
}