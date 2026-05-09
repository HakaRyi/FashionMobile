import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../managers/report_manager.dart';
import '../models/report_type_model.dart';
import '../utils/app_notification.dart';
import '../utils/app_toast.dart';

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

    if (_didLoad) {
      return;
    }

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
      if (!mounted) {
        return;
      }

      final message = _extractErrorMessage(e);

      setState(() {
        _errorText = message;
      });

      AppToast.show(context, message, isError: true);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_selectedReportTypeId == null || _selectedReportTypeId! <= 0) {
      setState(() {
        _errorText = 'Please select a report reason.';
      });

      AppToast.show(
        context,
        'Please select a report reason.',
        isError: true,
      );
      return;
    }

    setState(() {
      _errorText = null;
    });

    try {
      final result = await reportManager.submitReport(
        postId: widget.postId,
        reportTypeId: _selectedReportTypeId!,
        reason: _reasonController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      AppToast.show(
        context,
        result.message,
        isError: false,
      );

      Navigator.pop(context, result.message);
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = _extractErrorMessage(e);

      setState(() {
        _errorText = message;
      });

      AppToast.show(context, message, isError: true);
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();

    if (raw.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return raw;
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 34),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      ),
                    )
                  else ...[
                    if (types.isEmpty)
                      _buildEmptyTypesCard()
                    else ...[
                      const Text(
                        'Choose a reason',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...types.map(_buildTypeTile),
                    ],
                    const SizedBox(height: 14),
                    const Text(
                      'Additional description',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildReasonField(isSubmitting),
                  ],
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    _buildErrorBox(_errorText!),
                  ],
                  const SizedBox(height: 16),
                  _buildActionButtons(
                    isLoading: isLoading,
                    isSubmitting: isSubmitting,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _softCardDecoration(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.report_gmailerrorred_rounded,
            color: Colors.redAccent,
            size: 26,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPORT POST',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tell us why this post may violate community rules. Your report will be reviewed by the admin team.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTypesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _softCardDecoration(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.black38,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No report types are currently available.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField(bool isSubmitting) {
    return TextField(
      controller: _reasonController,
      maxLines: 4,
      maxLength: 1000,
      enabled: !isSubmitting,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Add more details if needed...',
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontWeight: FontWeight.w500,
        ),
        counterStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.all(14),
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
            width: 1.2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.black.withOpacity(0.05),
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
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline,
              size: 16,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required bool isLoading,
    required bool isSubmitting,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: BorderSide(
                color: Colors.black.withOpacity(0.12),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading || isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFEDEDED),
              disabledForegroundColor: Colors.black38,
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
              'SUBMIT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTile(ReportTypeModel type) {
    final selected = _selectedReportTypeId == type.reportTypeId;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: reportManager.isSubmitting
          ? null
          : () {
        setState(() {
          _selectedReportTypeId = type.reportTypeId;
          _errorText = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.redAccent.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.redAccent
                : Colors.black.withOpacity(0.06),
            width: selected ? 1.3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.redAccent : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.redAccent : Colors.black26,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.typeName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  if (type.description != null &&
                      type.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      type.description!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _softCardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.black.withOpacity(0.05),
      ),
    );
  }
}