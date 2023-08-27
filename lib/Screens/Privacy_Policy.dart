import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class PrivacyPolicy extends StatefulWidget {
  final String? title;

  const PrivacyPolicy({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? privacy;
  String url = "";
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    getSetting();
    if (privacy != "" && privacy != null) {}

    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  void changeTextColor() {
    // Define the JavaScript code to change the text color
    String jsCode = '''
    var style = document.createElement('style');
    style.innerHTML = 'body { color: ${Theme.of(context).colorScheme.webFontColor}; }'; // Change color value as per your requirement
    document.head.appendChild(style);
  ''';

    // Execute the JavaScript code
    _controller.runJavaScript(jsCode);
  }

  webviewInitialized() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).colorScheme.lightWhite)
      ..loadHtmlString(privacy!)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageFinished: (String url) {
            // Apply custom CSS to change text color
            changeTextColor();
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      );

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled catch (_) {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, TRY_AGAIN_INT_LBL)!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(const Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget,
                        ),
                      );
                    } else {
                      await buttonController!.reverse();
                      setState(
                        () {},
                      );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getAppBar(widget.title!, context),
      body: _isNetworkAvail
          ? _isLoading
              ? getProgress()
              : privacy != "" && privacy != null
                  ? Padding(
                      padding: const EdgeInsets.all(
                        10.0,
                      ),
                      child: WebViewWidget(
                          controller:
                              _controller) /*WebView(
                        zoomEnabled: true,
                        javascriptMode: JavascriptMode.unrestricted,
                        initialUrl: 'about:blank',
                        onWebViewCreated:
                            (WebViewController webViewController) {
                          webViewController.loadHtmlString(
                            privacy!,
                          );
                        },
                      ),*/
                      )
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: Text(
                          getTranslated(context, NodataFound)!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                          ),
                        ),
                      ),
                    )
          : noInternet(context),
    );
  }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        String? type;
        if (widget.title == getTranslated(context, PRIVACY)!) {
          type = PRIVACY_POLLICY;
        } else if (widget.title == getTranslated(context, TERM)!) {
          type = TERM_COND;
        }

        var parameter = {TYPE: type};
        Response response = await post(
          getSettingApi,
          body: parameter,
          headers: headers,
        ).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );

        var getdata = json.decode(response.body);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          privacy = getdata["data"].toString();
          webviewInitialized();
        } else {
          setSnackbar(msg!);
        }
        setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, somethingMSg)!);
      }
    } else {
      setState(
        () {
          _isLoading = false;
          _isNetworkAvail = false;
        },
      );
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
        ),
        backgroundColor: Theme.of(context).colorScheme.white,
        elevation: 1.0,
      ),
    );
  }
}
