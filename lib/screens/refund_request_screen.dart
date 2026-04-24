import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../services/order_service.dart';
import '../utils/app_toast.dart';

class RefundRequestScreen extends StatefulWidget {
  final int orderId;

  const RefundRequestScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final OrderService _orderService = OrderService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _reasonController = TextEditingController();

  File? _proofImage1;
  File? _proofImage2;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _normalizeError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }

    return text;
  }

  Future<void> _pickImage({
    required int slot,
    required ImageSource source,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        if (slot == 1) {
          _proofImage1 = File(pickedFile.path);
        } else {
          _proofImage2 = File(pickedFile.path);
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppToast.show(context, 'Cannot pick image.');
    }
  }

  void _showImageSourceSheet(int slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.textPink,
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(
                      slot: slot,
                      source: ImageSource.gallery,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.textPink,
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(color: AppColors.text),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(
                      slot: slot,
                      source: ImageSource.camera,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRefundRequest() async {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      AppToast.show(context, 'Please enter refund reason.');
      return;
    }

    if (reason.length < 5) {
      AppToast.show(context, 'Refund reason is too short.');
      return;
    }

    if (_proofImage1 == null) {
      AppToast.show(context, 'Please select at least one proof image.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _orderService.createRefundRequest(
        orderId: widget.orderId,
        reason: reason,
        proofImage1: _proofImage1!,
        proofImage2: _proofImage2,
      );

      if (!mounted) {
        return;
      }

      AppToast.show(context, 'Refund request submitted successfully.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_normalizeError(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showProofGuide() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Proof image guide',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please upload clear images that show the problem, such as wrong item, damaged item, missing item, or mismatch with the description.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(
          icon,
          color: AppColors.textPink,
        ),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.textPink),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textPink,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Refund can only be requested when the order is Delivered. After submitting, the order will move to Refunding and wait for admin review.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofPicker({
    required String title,
    required String subtitle,
    required File? image,
    required int slot,
    required bool requiredImage,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                color: requiredImage ? AppColors.textPink : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requiredImage ? '$title *' : title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (image != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (slot == 1) {
                        _proofImage1 = null;
                      } else {
                        _proofImage2 = null;
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                image,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
              ),
            )
          else
            InkWell(
              onTap: _isSubmitting ? null : () => _showImageSourceSheet(slot),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: 138,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.divider,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textPink,
                      size: 34,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to select image',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (image != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => _showImageSourceSheet(slot),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPink,
                  side: const BorderSide(color: AppColors.textPink),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.text),
        title: const Text(
          'Request Refund',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showProofGuide,
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.text,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 18),
          const Text(
            'Refund Reason',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _reasonController,
            label: 'Reason',
            hint: 'Example: Item is damaged or not as described',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          const Text(
            'Proof Images',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _buildProofPicker(
            title: 'Proof image 1',
            subtitle: 'Required. Upload the clearest image showing the problem.',
            image: _proofImage1,
            slot: 1,
            requiredImage: true,
          ),
          const SizedBox(height: 14),
          _buildProofPicker(
            title: 'Proof image 2',
            subtitle: 'Optional. Add another image if needed.',
            image: _proofImage2,
            slot: 2,
            requiredImage: false,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRefundRequest,
              icon: _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.assignment_return_outlined),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Refund Request',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}