import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../managers/order_manager.dart';

class RefundRequestScreen extends StatefulWidget {
  final int orderId;

  const RefundRequestScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final TextEditingController _reasonController = TextEditingController();
  File? _image1;
  File? _image2;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final OrderManager _orderManager = OrderManager();

  Future<void> _pickImage(int imageNumber) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (imageNumber == 1) {
          _image1 = File(pickedFile.path);
        } else {
          _image2 = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitRefund() async {
    if (_image1 == null || _image2 == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do và cung cấp đủ 2 ảnh minh chứng')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _orderManager.submitRefundRequest(
      context,
      widget.orderId,
      _reasonController.text.trim(),
      _image1!,
      _image2!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu cầu trả hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do trả hàng',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImage(1),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _image1 != null
                          ? Image.file(_image1!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickImage(2),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _image2 != null
                          ? Image.file(_image2!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRefund,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Gửi Yêu Cầu', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}