// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import '../utils/open_url.dart';

// class StripeDonationService {
//   final String baseUrl;
//   StripeDonationService(this.baseUrl);

//   Future<String?> _token() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString("access_token");
//   }

//   /// ✅ (WEB) تأكيد الدفع بعد الرجوع من Stripe
//   Future<void> confirmCheckoutSession(String sessionId) async {
//     final token = await _token();
//     if (token == null) throw Exception("أعد تسجيل الدخول (لا يوجد توكن)");

//     final res = await http.post(
//       Uri.parse("$baseUrl/api/payments/confirm-checkout-session/"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({"session_id": sessionId}),
//     );

//     if (res.statusCode != 200 && res.statusCode != 201) {
//       throw Exception("فشل تأكيد Checkout: ${res.statusCode} - ${res.body}");
//     }
//   }

//   Future<void> donate({
//     required int campaignId,
//     required double amount,
//   }) async {
//     final token = await _token();
//     if (token == null) throw Exception("أعد تسجيل الدخول (لا يوجد توكن)");

//     // ✅ WEB: Checkout Redirect
//     if (kIsWeb) {
//       final res = await http.post(
//         Uri.parse("$baseUrl/api/payments/create-checkout-session/"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "campaign_id": campaignId,
//           "amount": amount,
//         }),
//       );

//       if (res.statusCode != 200 && res.statusCode != 201) {
//         throw Exception("فشل إنشاء Checkout Session: ${res.statusCode} - ${res.body}");
//       }

//       final data = jsonDecode(res.body);
//       final String url = data["url"];

//       openUrl(url); // يفتح صفحة الدفع في Stripe
//       return;
//     }

//     // ✅ MOBILE: PaymentSheet
//     final createRes = await http.post(
//       Uri.parse("$baseUrl/api/payments/create-intent/"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "campaign_id": campaignId,
//         "amount": amount,
//       }),
//     );

//     if (createRes.statusCode != 200 && createRes.statusCode != 201) {
//       throw Exception("فشل إنشاء PaymentIntent: ${createRes.statusCode} - ${createRes.body}");
//     }

//     final data = jsonDecode(createRes.body);
//     final String clientSecret = data["client_secret"];
//     final String paymentIntentId = data["payment_intent_id"];
//     final String publishableKey = data["publishable_key"];

//     if (Stripe.publishableKey != publishableKey) {
//       Stripe.publishableKey = publishableKey;
//       await Stripe.instance.applySettings();
//     }

//     await Stripe.instance.initPaymentSheet(
//       paymentSheetParameters: SetupPaymentSheetParameters(
//         paymentIntentClientSecret: clientSecret,
//         merchantDisplayName: "Sadaqa",
//       ),
//     );

//     try {
//       await Stripe.instance.presentPaymentSheet();
//     } on StripeException catch (e) {
//       throw Exception("تم إلغاء الدفع أو حدث خطأ: ${e.error.localizedMessage}");
//     }

//     final confirmRes = await http.post(
//       Uri.parse("$baseUrl/api/payments/confirm/"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode({
//         "payment_intent_id": paymentIntentId,
//         "campaign_id": campaignId,
//         "amount": amount,
//       }),
//     );

//     if (confirmRes.statusCode != 200 && confirmRes.statusCode != 201) {
//       throw Exception("تم الدفع لكن فشل الحفظ في السيرفر: ${confirmRes.statusCode} - ${confirmRes.body}");
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/open_url.dart';

class StripeDonationService {
  final String baseUrl;
  StripeDonationService(this.baseUrl);

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  // ✅ استخراج payment_intent_id من client_secret (pi_xxx_secret_yyy -> pi_xxx)
  String _extractPaymentIntentIdFromClientSecret(String clientSecret) {
    final parts = clientSecret.split("_secret_");
    return parts.isNotEmpty ? parts.first : clientSecret;
  }

  /// ✅ (WEB) تأكيد الدفع بعد الرجوع من Stripe
  Future<void> confirmCheckoutSession(String sessionId) async {
    final token = await _token();
    if (token == null) throw Exception("أعد تسجيل الدخول (لا يوجد توكن)");

    final res = await http.post(
      Uri.parse("$baseUrl/api/payments/confirm-checkout-session/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"session_id": sessionId}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("فشل تأكيد Checkout: ${res.statusCode} - ${res.body}");
    }
  }

  Future<void> donate({
    required int campaignId,
    required double amount,
  }) async {
    final token = await _token();
    if (token == null) throw Exception("أعد تسجيل الدخول (لا يوجد توكن)");

    // ✅ WEB: Checkout Redirect
    if (kIsWeb) {
      final res = await http.post(
        Uri.parse("$baseUrl/api/payments/create-checkout-session/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "campaign_id": campaignId,
          "amount": amount,
        }),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("فشل إنشاء Checkout Session: ${res.statusCode} - ${res.body}");
      }

      final data = jsonDecode(res.body);
      final url = (data["url"] ?? "").toString().trim();
      if (url.isEmpty) throw Exception("Stripe URL غير موجود. الرد: ${res.body}");

      openUrl(url);
      return;
    }

    // ✅ MOBILE: PaymentSheet (PaymentIntent)
    final createRes = await http.post(
      Uri.parse("$baseUrl/api/payments/create-intent/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "campaign_id": campaignId,
        "amount": amount,
      }),
    );

    // ✅ Logs للتشخيص
    debugPrint("Stripe create-intent STATUS = ${createRes.statusCode}");
    debugPrint("Stripe create-intent BODY = ${createRes.body}");

    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      throw Exception("فشل إنشاء PaymentIntent: ${createRes.statusCode} - ${createRes.body}");
    }

    final decoded = jsonDecode(createRes.body);
    if (decoded is! Map) {
      throw Exception("Réponse غير صالحة (ليست JSON Map): ${createRes.body}");
    }
    final data = decoded;

    // ✅ client_secret (إجباري)
    final clientSecret = (data["client_secret"] ?? "").toString().trim();
    if (clientSecret.isEmpty) {
      throw Exception("client_secret غير موجود. الرد: ${createRes.body}");
    }

    // ✅ payment_intent_id نستخرجه من client_secret
    final paymentIntentId = _extractPaymentIntentIdFromClientSecret(clientSecret);

    // ✅ publishableKey يجب أن يكون مضبوط مسبقًا في main.dart
    if (Stripe.publishableKey.isEmpty) {
      throw Exception("Stripe.publishableKey غير مضبوط. ضعه في main.dart (pk_test...).");
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: "Sadaqa",
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      throw Exception("تم إلغاء الدفع أو حدث خطأ: ${e.error.localizedMessage}");
    }

    // ✅ Confirm (حفظ التبرع في السيرفر)
    final confirmRes = await http.post(
      Uri.parse("$baseUrl/api/payments/confirm/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "payment_intent_id": paymentIntentId,
        "campaign_id": campaignId,
        "amount": amount,
      }),
    );

    debugPrint("Stripe confirm STATUS = ${confirmRes.statusCode}");
    debugPrint("Stripe confirm BODY = ${confirmRes.body}");

    if (confirmRes.statusCode != 200 && confirmRes.statusCode != 201) {
      throw Exception("تم الدفع لكن فشل الحفظ في السيرفر: ${confirmRes.statusCode} - ${confirmRes.body}");
    }
  }
}
