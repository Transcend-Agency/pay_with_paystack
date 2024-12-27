// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pay_with_paystack/src/widgets/app_loader.dart';
import 'package:pay_with_paystack/src/widgets/custom_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'utils/error.dart';

class PaystackPayNow extends StatefulWidget {
  final String secretKey;
  final String reference;
  final String callbackUrl;
  final String currency;
  final String email;
  final double amount;
  final String? plan;
  final metadata;
  final paymentChannel;
  final void Function(Map<String, dynamic> decodedRespBody)
      transactionCompleted;
  final void Function(TransactionErrorType errorType, String reason)
      transactionNotCompleted;

  const PaystackPayNow({
    Key? key,
    required this.secretKey,
    required this.email,
    required this.reference,
    required this.currency,
    required this.amount,
    required this.callbackUrl,
    required this.transactionCompleted,
    required this.transactionNotCompleted,
    this.metadata,
    this.plan,
    this.paymentChannel,
  }) : super(key: key);

  @override
  State<PaystackPayNow> createState() => _PaystackPayNowState();
}

class _PaystackPayNowState extends State<PaystackPayNow> {
  Future<PaystackRequestResponse> _makePaymentRequest() async {
    http.Response? response;
    final amount = widget.amount * 100;

    try {
      // Sending data to Paystack.
      response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },
        body: jsonEncode({
          "email": widget.email,
          "amount": amount.toString(),
          "reference": widget.reference,
          "currency": widget.currency,
          "plan": widget.plan,
          "metadata": widget.metadata,
          "callback_url": widget.callbackUrl,
          "channels": widget.paymentChannel
        }),
      );
    } on Exception catch (e) {
      var errorType = TransactionErrorType.unexpectedError;

      if (e is SocketException || e is HttpException) {
        errorType = TransactionErrorType.noInternetConnection;
      }

      if (context.mounted) {
        Navigator.pop(context);
        widget.transactionNotCompleted(errorType, e.toString());
      }
    }

    if (response != null && response.statusCode == 200) {
      return PaystackRequestResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          "Response Code: ${response?.statusCode}, Response Body${response?.body}");
    }
  }

  /// Checks for transaction status of current transaction before view closes.
  Future _checkTransactionStatus(String ref) async {
    http.Response? response;
    try {
      /// Getting data, passing [ref] as a value to the URL that is being requested.
      response = await http.get(
        Uri.parse('https://api.paystack.co/transaction/verify/$ref'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.secretKey}',
        },
      );
    } on Exception catch (e) {
      var errorType = TransactionErrorType.unexpectedError;

      if (e is SocketException || e is HttpException) {
        errorType = TransactionErrorType.noInternetConnection;
      }

      if (context.mounted) {
        Navigator.pop(context);
        widget.transactionNotCompleted(errorType, e.toString());
      }
    }
    if (response!.statusCode == 200) {
      var decodedRespBody = jsonDecode(response.body);
      // print(decodedRespBody.toString());
      if (decodedRespBody["data"]["status"] == "success") {
        widget.transactionCompleted(decodedRespBody);
      } else {
        widget.transactionNotCompleted(
          TransactionErrorType.transactionFailed,
          decodedRespBody["data"]["status"].toString(),
        );
      }
    } else {
      /// Anything else means there is an issue
      throw Exception(
          "Response Code: ${response.statusCode}, Response Body${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back gesture
      child: FutureBuilder<PaystackRequestResponse>(
          future: _makePaymentRequest(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.status == true) {
              final controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                // ..setUserAgent("Flutter;Webview")
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onNavigationRequest: (request) async {
                      if (request.url
                          .contains(' https://your-cancel-url.com')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url
                          .contains('https://cancelurl.com')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url
                          .contains('https://standard.paystack.co/close')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url
                          .contains('https://paystack.co/close')) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else if (request.url.contains(widget.callbackUrl)) {
                        await _checkTransactionStatus(snapshot.data!.reference)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      }
                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(Uri.parse(snapshot.data!.authUrl));

              return Scaffold(
                appBar: CustomAppBar(
                  onCloseTap: () async {
                    await _checkTransactionStatus(snapshot.data!.reference)
                        .then((value) {
                      Navigator.of(context).pop();
                    });
                  },
                ),
                body: WebViewWidget(controller: controller),
              );
            }

            if (snapshot.hasError) {
              log('The error is ${snapshot.error}');
              return Material(
                child: Center(
                  child: Text('${snapshot.error}'),
                ),
              );
            }

            return const Material(
              child: Center(
                child: AppLoader(
                  color: Color(0xffF0174B),
                  size: 24,
                ),
              ),
            );
          }),
    );
  }
}

class PaystackRequestResponse {
  final bool status;
  final String authUrl;
  final String reference;

  const PaystackRequestResponse(
      {required this.authUrl, required this.status, required this.reference});

  factory PaystackRequestResponse.fromJson(Map<String, dynamic> json) {
    return PaystackRequestResponse(
      status: json['status'],
      authUrl: json['data']["authorization_url"],
      reference: json['data']["reference"],
    );
  }
}
