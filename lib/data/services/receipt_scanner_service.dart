import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:money_manajemen/app/constants/api_url.dart';
import 'package:money_manajemen/data/datasources/auth_local_data_source.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';

class ReceiptItem {
  final String name;
  final int qty;
  final int price;
  final int totalPrice;

  ReceiptItem({
    required this.name,
    required this.qty,
    required this.price,
    int? totalPrice,
  }) : totalPrice = totalPrice ?? (qty * price);

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    int qty = 1;
    if (json['qty'] is num) {
      qty = (json['qty'] as num).toInt();
    } else if (json['qty'] != null) {
      qty = int.tryParse(json['qty'].toString()) ?? 1;
    }

    int price = 0;
    final rawPrice = json['price'] ?? json['unit_price'] ?? json['total_price'];
    if (rawPrice is num) {
      price = rawPrice.toInt();
    } else if (rawPrice != null) {
      final str = rawPrice.toString().replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').trim();
      price = int.tryParse(str) ?? 0;
    }

    int totPrice = qty * price;
    if (json['total_price'] != null) {
      if (json['total_price'] is num) {
        totPrice = (json['total_price'] as num).toInt();
      } else {
        final str = json['total_price'].toString().replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').trim();
        totPrice = int.tryParse(str) ?? totPrice;
      }
    }

    return ReceiptItem(
      name: json['name']?.toString() ?? json['item_name']?.toString() ?? 'Item Struk',
      qty: qty,
      price: price,
      totalPrice: totPrice,
    );
  }
}

class ReceiptDiscountItem {
  final String name;
  final int amount;

  ReceiptDiscountItem({
    required this.name,
    required this.amount,
  });

  factory ReceiptDiscountItem.fromJson(Map<String, dynamic> json) {
    int amt = 0;
    final rawAmt = json['amount'] ?? json['price'] ?? json['total'] ?? json['value'];
    if (rawAmt is num) {
      amt = rawAmt.toInt();
    } else if (rawAmt != null) {
      final str = rawAmt.toString().replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').replaceAll('(', '').replaceAll(')', '').trim();
      amt = int.tryParse(str) ?? 0;
    }

    return ReceiptDiscountItem(
      name: json['name']?.toString() ?? json['title']?.toString() ?? json['label']?.toString() ?? 'Voucher / Diskon',
      amount: amt,
    );
  }
}

class ScannedReceiptResult {
  final String title;
  final int amount;
  final int discount;
  final String? discountTitle;
  final List<ReceiptDiscountItem> discounts;
  final String category;
  final TransactionType type;
  final List<ReceiptItem> items;

  ScannedReceiptResult({
    required this.title,
    required this.amount,
    this.discount = 0,
    this.discountTitle,
    this.discounts = const [],
    required this.category,
    this.type = TransactionType.expense,
    this.items = const [],
  });
}

class ReceiptScannerService {
  static Future<ScannedReceiptResult?> scanReceipt(XFile imageFile) async {
    final token = await AuthLocalDataSourceImpl().getToken();
    final uri = Uri.parse(ApiUrl.scanReceipt);

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer ${token ?? ''}',
        'X-App-Key': ApiUrl.appKey,
        'x-api-key': ApiUrl.appKey,
        'Accept': 'application/json',
      });

      final multipartFile = await http.MultipartFile.fromPath(
        'receipt',
        imageFile.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final data = json['data'] ?? json;

        String rawTitle = data['merchant_name']?.toString() ??
            data['merchant']?.toString() ??
            data['store_name']?.toString() ??
            data['title']?.toString() ??
            data['name']?.toString() ??
            '';

        String title = rawTitle.trim();
        if (title.isEmpty ||
            title.toLowerCase() == 'unknown' ||
            title.toLowerCase() == 'unknown merchant' ||
            title.toLowerCase() == 'null' ||
            title.toLowerCase() == 'n/a') {
          title = 'Struk Belanja';
        }

        int amount = 0;
        final rawAmount = data['total_amount'] ?? data['amount'] ?? data['total'] ?? data['grand_total'];
        if (rawAmount is num) {
          amount = rawAmount.toInt();
        } else if (rawAmount != null) {
          final str = rawAmount.toString().replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').trim();
          amount = int.tryParse(str) ?? 0;
        }

        int discount = 0;
        final rawDiscount = data['discount'] ?? data['total_discount'] ?? data['diskon'];
        if (rawDiscount is num) {
          discount = rawDiscount.toInt();
        } else if (rawDiscount != null) {
          final str = rawDiscount.toString().replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').replaceAll('(', '').replaceAll(')', '').trim();
          discount = int.tryParse(str) ?? 0;
        }

        String category = data['suggested_category']?.toString() ?? data['category']?.toString() ?? 'Food & Dining';

        List<ReceiptItem> items = [];
        if (data['items'] != null && data['items'] is List) {
          items = (data['items'] as List)
              .map((i) => ReceiptItem.fromJson(i as Map<String, dynamic>))
              .toList();
        }

        if (amount == 0 && items.isNotEmpty) {
          final subtotal = items.fold(0, (sum, item) => sum + item.totalPrice);
          amount = subtotal - discount;
        }

        List<ReceiptDiscountItem> discounts = [];
        if (data['discounts'] != null && data['discounts'] is List) {
          discounts = (data['discounts'] as List)
              .map((d) => ReceiptDiscountItem.fromJson(d as Map<String, dynamic>))
              .toList();
        }

        String? discountTitle = data['discount_title']?.toString() ?? data['discount_name']?.toString() ?? data['discount_label']?.toString();

        return ScannedReceiptResult(
          title: title,
          amount: amount,
          discount: discount,
          discountTitle: discountTitle,
          discounts: discounts,
          category: category,
          type: TransactionType.expense,
          items: items,
        );
      } else {
        String errorMessage = 'Gagal membaca struk (${response.statusCode})';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'].toString();
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}
