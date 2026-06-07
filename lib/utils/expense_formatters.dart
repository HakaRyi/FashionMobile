// lib/utils/expense_formatters.dart

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat('#,###', 'vi_VN');

String formatMoney(double value) {
  return '${_moneyFormat.format(value)} VND';
}

String formatCompactMoney(double value) {
  final abs = value.abs();
  if (abs >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return _moneyFormat.format(value);
}

String formatShortMoney(double value) {
  final abs = value.abs();
  if (abs >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return '${_moneyFormat.format(value)} VND';
}

String formatAdaptiveMoney(double value, {bool compact = false}) {
  return compact ? formatShortMoney(value) : formatMoney(value);
}

DateTime toVietnamTime(DateTime dateTime) {
  if (dateTime.isUtc) return dateTime.add(const Duration(hours: 7));
  return dateTime;
}

String formatVietnamTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm').format(toVietnamTime(dateTime));
}

String mapReferenceType(String value) {
  switch (value.trim()) {
    case 'TopUp':          return 'Top up';
    case 'OrderPayment':   return 'Order payment';
    case 'OrderRefund':    return 'Order refund';
    case 'TryOn':          return 'AI try-on';
    case 'AIRecommendation': return 'Smart recommendation';
    case 'Event':          return 'Event';
    case 'EventReward':    return 'Event reward';
    case 'Event_Reject':   return 'Event reject';
    default: return value.trim().isEmpty ? 'Other' : value;
  }
}

String mapTransactionType(String value) {
  switch (value.trim()) {
    case 'Credit':                   return 'Income';
    case 'Debit':                    return 'Expense';
    case 'TopUp':                    return 'Wallet top up';
    case 'OrderPayment':             return 'Order payment';
    case 'OrderRefund':              return 'Order refund';
    case 'TryOn':                    return 'AI try-on payment';
    case 'AIRecommendation':         return 'Smart recommendation payment';
    case 'Event_Entry_Fee_Paid':     return 'Event entry fee';
    case 'Event_Revenue_Locked':     return 'Event revenue locked';
    case 'Event_Revenue_Released':   return 'Event revenue released';
    case 'System_Fee_Payment':       return 'Event system fee';
    case 'System_Fee_Revenue':       return 'System fee revenue';
    case 'Escrow_Hold':              return 'Event prize escrow';
    case 'Prize_Reward':             return 'Event prize reward';
    case 'Event_Refund':             return 'Event refund';
    case 'Event_Cancel_Refund':      return 'Event cancellation refund';
    case 'Event_Reject_Refund':      return 'Rejected event refund';
    default: return value.trim().isEmpty ? 'Transaction' : value;
  }
}

String mapStatus(String value) {
  switch (value.trim().toLowerCase()) {
    case 'pending':               return 'Pending';
    case 'success':
    case 'completed':             return 'Success';
    case 'failed':                return 'Failed';
    case 'cancelled':
    case 'canceled':              return 'Cancelled';
    default:                      return value;
  }
}

String resolveDisplayType(String type, double amount) {
  final rawType = type.trim().toLowerCase();

  const debitTypes = {
    'debit', 'orderpayment', 'tryon', 'airecommendation',
    'packagepurchase', 'withdraw', 'event_entry_fee_paid',
    'system_fee_payment', 'escrow_hold',
  };
  const creditTypes = {
    'credit', 'topup', 'orderrefund', 'refund', 'prize_reward',
    'event_refund', 'event_cancel_refund', 'event_reject_refund',
    'event_revenue_locked', 'event_revenue_released',
    'system_fee_revenue',
  };

  if (debitTypes.contains(rawType)) return 'Debit';
  if (creditTypes.contains(rawType)) return 'Credit';
  if (amount < 0) return 'Debit';
  if (amount > 0) return 'Credit';
  return 'Debit';
}

Color typeColor(String type) {
  if (type.toLowerCase() == 'credit') return const Color(0xFF10B981);
  if (type.toLowerCase() == 'debit')  return const Color(0xFFEF4444);
  return const Color(0xFF6B7280);
}

IconData typeIcon(String type) {
  if (type.toLowerCase() == 'credit') return Icons.arrow_downward_rounded;
  return Icons.arrow_upward_rounded;
}

Color statusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'success':
    case 'completed': return const Color(0xFF10B981);
    case 'pending':   return const Color(0xFFF59E0B);
    case 'failed':    return const Color(0xFFEF4444);
    default:          return const Color(0xFF6B7280);
  }
}