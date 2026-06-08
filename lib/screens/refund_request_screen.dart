import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    } catch (_) {
      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        'Cannot pick image.',
        isError: true,
      );
    }
  }

  void _showImageSourceSheet(int slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SELECT IMAGE SOURCE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSheetAction(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from gallery',
                  subtitle: 'Select an image from your device',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(
                      slot: slot,
                      source: ImageSource.gallery,
                    );
                  },
                ),
                _buildSheetAction(
                  icon: Icons.photo_camera_outlined,
                  title: 'Take a photo',
                  subtitle: 'Use your camera to capture proof',
                  onTap: () {
                    Navigator.pop(sheetContext);
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

  Widget _buildSheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.black45,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.black12,
        size: 14,
      ),
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

    if (_proofImage1 == null || _proofImage2 == null) {
      AppToast.show(context, 'Please select both proof images (2/2 required).');
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
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Proof image guide',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Please upload clear images that show the problem, such as a wrong item, damaged item, missing item, or mismatch with the description.',
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'GOT IT',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
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
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Colors.black45,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(
          color: Colors.black26,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.black,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.black,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Refunds can only be requested when the order is Delivered. After submission, the order will move to Refunding and wait for admin review.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                color: requiredImage ? Colors.black : Colors.black38,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requiredImage ? '$title *' : title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
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
              color: Colors.black45,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
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
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.black,
                      size: 34,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to select image',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                onPressed:
                _isSubmitting ? null : () => _showImageSourceSheet(slot),
                icon: const Icon(Icons.swap_horiz),
                label: const Text(
                  'CHANGE IMAGE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'REQUEST REFUND',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showProofGuide,
            icon: const Icon(
              Icons.help_outline,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 18),
          _sectionTitle(
            'REFUND REASON',
            Icons.description_outlined,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _reasonController,
            label: 'Reason',
            hint: 'Example: The item is damaged or not as described',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          _sectionTitle(
            'PROOF IMAGES',
            Icons.image_outlined,
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
            subtitle: 'Required. Add a second image showing closer details or package label.',
            image: _proofImage2,
            slot: 2,
            requiredImage: true,
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
                _isSubmitting ? 'SUBMITTING...' : 'SUBMIT REFUND REQUEST',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFEDEDED),
                disabledForegroundColor: Colors.black38,
                elevation: 0,
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

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.black,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Colors.black.withOpacity(0.05),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}