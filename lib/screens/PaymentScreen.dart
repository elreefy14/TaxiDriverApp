import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter_braintree_betc/flutter_braintree_betc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
// import 'package:flutter_paystack/flutter_paystack.dart';
// import 'package:flutter_paytabs_bridge/BaseBillingShippingInfo.dart' as payTab;
// import 'package:flutter_paytabs_bridge/IOSThemeConfiguration.dart';
// import 'package:flutter_paytabs_bridge/PaymentSdkApms.dart';
// import 'package:flutter_paytabs_bridge/PaymentSdkConfigurationDetails.dart';
// import 'package:flutter_paytabs_bridge/flutter_paytabs_bridge.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutterwave_standard_smart/flutterwave.dart';
import 'package:http/http.dart' as http;
// import 'package:my_fatoorah/my_fatoorah.dart';
// import 'package:paytm/paytm.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';
import '../../network/NetworkUtils.dart';
import '../../network/RestApis.dart';
import '../../utils/Colors.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../model/PaymentListModel.dart';
import '../model/StripePayModel.dart';
import '../utils/Images.dart';

class PaymentScreen extends StatefulWidget {
  final num? amount;

  PaymentScreen({this.amount});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  List<PaymentModel> paymentList = [];

  String? selectedPaymentType,
      stripPaymentKey,
      stripPaymentPublishKey,
      payStackPublicKey,
      payPalTokenizationKey,
      flutterWavePublicKey,
      flutterWaveSecretKey,
      flutterWaveEncryptionKey,
      payTabsProfileId,
      payTabsServerKey,
      payTabsClientKey,
      mercadoPagoPublicKey,
      mercadoPagoAccessToken,
      myFatoorahToken,
      paytmMerchantId,
      paytmMerchantKey;

  String? razorKey;
  bool isTestType = true;
  bool loading = false;
  // final plugin = PaystackPlugin();
  // late Razorpay _razorpay;
  // CheckoutMethod method = CheckoutMethod.card;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await paymentListApiCall();
    /*
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_STRIPE)) {
      Stripe.publishableKey = stripPaymentPublishKey.validate();
      Stripe.merchantIdentifier = mStripeIdentifier;
      await Stripe.instance.applySettings().catchError((e) {
        log("${e.toString()}");
      });
    }
    */
    /*
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_PAYSTACK)) {
      plugin.initialize(publicKey: payStackPublicKey.validate());
    }
    if (paymentList.any((element) => element.type == PAYMENT_TYPE_RAZORPAY)) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
    */
  }

  /// Get Payment Gateway Api Call
  Future<void> paymentListApiCall() async {
    appStore.setLoading(true);
    await getPaymentList().then((value) {
      appStore.setLoading(false);
      paymentList.addAll(value.data!);
      if (paymentList.isNotEmpty) {
        paymentList.forEach((element) {
          if (element.type == PAYMENT_TYPE_STRIPE) {
            stripPaymentKey = element.isTest == 1
                ? element.testValue!.secretKey
                : element.liveValue!.secretKey;
            stripPaymentPublishKey = element.isTest == 1
                ? element.testValue!.publishableKey
                : element.liveValue!.publishableKey;
          } else if (element.type == PAYMENT_TYPE_PAYSTACK) {
            payStackPublicKey = element.isTest == 1
                ? element.testValue!.publicKey
                : element.liveValue!.publicKey;
            // plugin.initialize(publicKey: payStackPublicKey.validate());
          } else if (element.type == PAYMENT_TYPE_RAZORPAY) {
            razorKey = element.isTest == 1
                ? element.testValue!.keyId.validate()
                : element.liveValue!.keyId.validate();
          } else if (element.type == PAYMENT_TYPE_PAYPAL) {
            payPalTokenizationKey = element.isTest == 1
                ? element.testValue!.tokenizationKey
                : element.liveValue!.tokenizationKey;
          } else if (element.type == PAYMENT_TYPE_FLUTTERWAVE) {
            flutterWavePublicKey = element.isTest == 1
                ? element.testValue!.publicKey
                : element.liveValue!.publicKey;
            flutterWaveSecretKey = element.isTest == 1
                ? element.testValue!.secretKey
                : element.liveValue!.secretKey;
            flutterWaveEncryptionKey = element.isTest == 1
                ? element.testValue!.encryptionKey
                : element.liveValue!.encryptionKey;
          } else if (element.type == PAYMENT_TYPE_PAYTABS) {
            payTabsProfileId = element.isTest == 1
                ? element.testValue!.profileId
                : element.liveValue!.profileId;
            payTabsClientKey = element.isTest == 1
                ? element.testValue!.clientKey
                : element.liveValue!.clientKey;
            payTabsServerKey = element.isTest == 1
                ? element.testValue!.serverKey
                : element.liveValue!.serverKey;
          } else if (element.type == PAYMENT_TYPE_MERCADOPAGO) {
            mercadoPagoPublicKey = element.isTest == 1
                ? element.testValue!.publicKey
                : element.liveValue!.publicKey;
            mercadoPagoAccessToken = element.isTest == 1
                ? element.testValue!.accessToken
                : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_MYFATOORAH) {
            myFatoorahToken = element.isTest == 1
                ? element.testValue!.accessToken
                : element.liveValue!.accessToken;
          } else if (element.type == PAYMENT_TYPE_PAYTM) {
            paytmMerchantId = element.isTest == 1
                ? element.testValue!.merchantId
                : element.liveValue!.merchantId;
            paytmMerchantKey = element.isTest == 1
                ? element.testValue!.merchantKey
                : element.liveValue!.merchantKey;
          }
        });
      }
      selectedPaymentType = paymentList.first.type;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log('${error.toString()}');
    });
  }

  /// Razor Pay
  void razorPayPayment() {
    toast("Payment functionality has been disabled");
    paymentConfirm();
    /*
    var options = {
      'key': razorKey.validate(),
      'amount': (widget.amount! * 100),
      'name': mAppName,
      'description': mRazorDescription,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': sharedPref.getString(CONTACT_NUMBER),
        'email': sharedPref.getString(USER_EMAIL),
      },
      'external': {
        'wallets': ['paytm']
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      log(e.toString());
      debugPrint('Error: e');
    }
    */
  }

  /// Comments out payment handlers that have undefined classes
  /*
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    toast(language.transactionSuccessful);
    paymentConfirm();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    toast("${language.error}: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(
        msg: "EXTERNAL_WALLET: " + response.walletName!,
        toastLength: Toast.LENGTH_SHORT);
  }
  */

  /// StripPayment
  void stripePay() async {
    // Stripe payment temporarily disabled
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  /// PayStack Payment
  Future<void> payStackPayment(BuildContext context) async {
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  /// Paypal Payment
  void payPalPayment() async {
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  /// FlutterWave Payment
  void flutterWaveCheckout() async {
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  /// PayTabs Payment
  void payTabsPayment() {
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  /*
  PaymentSdkConfigurationDetails generateConfig() {
    // Implementation commented out
  }
  */

  /// MyFatoorah Payment
  void myFatoorahPayment() async {
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  /// PayTm Payment
  void paytmPayment() async {
    toast("Payment functionality is disabled");
    paymentConfirm();
  }

  // Payment Confirmation
  void paymentConfirm() async {
    appStore.setLoading(true);
    setState(() {});

    Map req = {
      "amount": widget.amount.toString(),
      "payment_type": selectedPaymentType,
      "transaction_id":
          '#PAY${(DateTime.now().millisecondsSinceEpoch / 1000).floor()}',
    };

    await savePayment(req).then((value) {
      toast(language.success);
      appStore.setLoading(false);

      Navigator.pop(context);
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.payment,
            style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paymentList.map((e) {
                return inkWellWidget(
                  onTap: () {
                    selectedPaymentType = e.type;
                    setState(() {});
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 48) / 2,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      //backgroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(defaultRadius),
                      border: Border.all(
                          width: selectedPaymentType == e.type ? 1.5 : 1,
                          color: selectedPaymentType == e.type
                              ? primaryColor
                              : dividerColor),
                    ),
                    child: Row(
                      children: [
                        Image.network(e.gatewayLogo!, width: 40, height: 40),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(e.title.validate(),
                              style: primaryTextStyle(), maxLines: 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Observer(builder: (context) {
            if (!appStore.isLoading && paymentList.isEmpty) {
              return emptyWidget();
            }
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Visibility(
          visible: paymentList.isNotEmpty,
          child: AppButtonWidget(
            text: language.pay,
            onTap: () {
              if (selectedPaymentType == PAYMENT_TYPE_RAZORPAY) {
                razorPayPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_STRIPE) {
                stripePay();
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYSTACK) {
                payStackPayment(context);
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYPAL) {
                payPalPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_FLUTTERWAVE) {
                flutterWaveCheckout();
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYTABS) {
                payTabsPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_MERCADOPAGO) {
                // mercadoPagoPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_MYFATOORAH) {
                myFatoorahPayment();
              } else if (selectedPaymentType == PAYMENT_TYPE_PAYTM) {
                paytmPayment();
              }
            },
          ),
        ),
      ),
    );
  }
}
