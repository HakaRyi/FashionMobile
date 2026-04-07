// lib/widgets/report_post_sheet.dart
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../core/api_exception.dart';
import '../managers/report_manager.dart';
import '../models/report_type_model.dart';

class ReportPostSheet extends StatefulWidget {
  final int postId;

  const ReportPostSheet({
    super.key,
    required this.postId,
  });

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  final TextEditingController _reasonController = TextEditingController();

  int? _selectedReportTypeId;
  String? _errorText;
  bool _didLoad = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() {
      _errorText = null;
    });

    try {
      await reportManager.loadReportTypes();
    } catch (e) {
      if (!mounted) return;

      final message = _extractErrorMessage(e);

      setState(() {
        _errorText = message;
      });

      _showErrorSnackBar(message);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_selectedReportTypeId == null || _selectedReportTypeId! <= 0) {
      setState(() {
        _errorText = 'Vui lòng chọn loại báo cáo.';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    try {
      final result = await reportManager.submitReport(
        postId: widget.postId,
        reportTypeId: _selectedReportTypeId!,
        reason: _reasonController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) return;

      final message = _extractErrorMessage(e);

      setState(() {
        _errorText = message;
      });

      _showErrorSnackBar(message);
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '').trim().isEmpty
        ? 'Có lỗi xảy ra, vui lòng thử lại.'
        : raw.replaceFirst('Exception: ', '').trim();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reportManager,
      builder: (context, _) {
        final types = reportManager.reportTypes;
        final isLoading = reportManager.isLoadingTypes;
        final isSubmitting = reportManager.isSubmitting;

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    'Báo cáo bài viết',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hãy cho chúng tôi biết lý do bạn thấy bài viết này có vấn đề.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPink,
                        ),
                      ),
                    )
                  else ...[
                    if (types.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: const Text(
                          'Hiện chưa có loại báo cáo nào khả dụng.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      ...types.map(_buildTypeTile),

                    const SizedBox(height: 14),
                    TextField(
                      controller: _reasonController,
                      maxLines: 4,
                      maxLength: 1000,
                      enabled: !isSubmitting,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Mô tả thêm (không bắt buộc)',
                        hintStyle: const TextStyle(color: Colors.white38),
                        counterStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.textPink,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                    ),
                  ],

                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white12,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Gửi báo cáo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeTile(ReportTypeModel type) {
    final selected = _selectedReportTypeId == type.reportTypeId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.textPink.withOpacity(0.12)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.textPink
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: RadioListTile<int>(
        value: type.reportTypeId,
        groupValue: _selectedReportTypeId,
        activeColor: AppColors.textPink,
        onChanged: reportManager.isSubmitting
            ? null
            : (value) {
          setState(() {
            _selectedReportTypeId = value;
            _errorText = null;
          });
        },
        title: Text(
          type.typeName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: (type.description != null &&
            type.description!.trim().isNotEmpty)
            ? Text(
          type.description!,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}