import 'dart:async';
import 'dart:convert';

import 'package:deliveryboy/Model/Transaction_Model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/SimBtn.dart';
import '../Helper/String.dart';

class WalletHistory extends StatefulWidget {
  const WalletHistory({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateWallet();
  }
}

List<TransactionModel> tranList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class StateWallet extends State<WalletHistory> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  List<TransactionModel> tempList = [];
  TextEditingController? amtC, acc_num, ifsc_code, acc_name;
  bool isRequest = false;

  @override
  void initState() {
    super.initState();
    getTransaction();
    controller.addListener(_scrollListener);
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
    amtC = TextEditingController();
    // bankDetailC = TextEditingController();
    acc_num = TextEditingController();
    ifsc_code = TextEditingController();
    acc_name = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      key: _scaffoldKey,
      appBar: getAppBar(
        getTranslated(context, WALLET)!,
        context,
      ),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer(context)
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: controller,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                      ),
                                      Text(
                                        " ${getTranslated(context, CURBAL_LBL)!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    getPriceFormat(
                                      context,
                                      double.parse(
                                        CUR_BALANCE,
                                      ),
                                    )!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  SimBtn(
                                    size: 0.8,
                                    title: WITHDRAW_MONEY,
                                    onBtnSelected: () {
                                      _showDialog();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        tranList.isEmpty
                            ? Center(
                                child: Text(
                                  getTranslated(context, noItem)!,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: (offset < total)
                                    ? tranList.length + 1
                                    : tranList.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return (index == tranList.length &&
                                          isLoadingmore)
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : listItem(index);
                                },
                              ),
                      ],
                    ),
                  ),
                )
          : noInternet(context),
    );
  }

  Future<void> sendRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          AMOUNT: amtC!.text.toString(),
          PAYMENT_ADD:
              "${acc_num!.text.toString()}\n${ifsc_code!.text.toString()}\n${acc_name!.text.toString()}",
        };

        Response response = await post(
          sendWithReqApi,
          body: parameter,
          headers: headers,
        ).timeout(
          const Duration(
            seconds: timeOut,
          ),
        );

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          CUR_BALANCE = double.parse(getdata["data"]).toStringAsFixed(2);
          setState(() {
            _isLoading = true;
          });
          offset = 0;
          total = 0;

          tranList.clear();
          getRequest();
        }
        if (mounted) setState(() {});
        setSnackbar(msg);
      } on TimeoutException catch (_) {
        setSnackbar(
          getTranslated(context, somethingMSg)!,
        );
        setState(
          () {
            _isLoading = false;
          },
        );
      }
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
            _isLoading = false;
          },
        );
      }
    }

    return;
  }

  getAppBar(
    String title,
    BuildContext context,
  ) {
    return AppBar(
      leading: Builder(
        builder: (BuildContext context) {
          return Container(
            margin: const EdgeInsets.all(10),
            decoration: shadow(),
            child: Card(
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fontColor,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                return filterDialog();
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  void filterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ButtonBarTheme(
          data: const ButtonBarThemeData(
            alignment: MainAxisAlignment.center,
          ),
          child: AlertDialog(
            elevation: 2.0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  5.0,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.all(0.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 19.0, bottom: 16.0),
                  child: Text(
                    getTranslated(context, FILTER_BY)!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightfontColor),
                  ),
                ),
                const Divider(),
                TextButton(
                  child: Text(
                    SHOW_TRANS,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                        ),
                  ),
                  onPressed: () {
                    tranList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                        isRequest = false;
                      },
                    );
                    getTransaction();
                    Navigator.pop(context, 'option 1');
                  },
                ),
                const Divider(),
                TextButton(
                  child: Text(
                    getTranslated(context, SHOW_REQ)!,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                        ),
                  ),
                  onPressed: () {
                    tranList.clear();
                    offset = 0;
                    total = 0;
                    setState(() {
                      _isLoading = true;
                      isRequest = true;
                    });
                    getRequest();
                    Navigator.pop(context, 'option 1');
                  },
                ),
                const Divider()
              ],
            ),
          ),
        );
      },
    );
  }

  _showDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    5.0,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20.0,
                        20.0,
                        0,
                        2.0,
                      ),
                      child: Text(
                        getTranslated(context, SEND_REQUEST)!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.fontColor),
                      ),
                    ),
                    const Divider(),
                    Form(
                      key: _formkey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20.0,
                              0,
                              20.0,
                              0,
                            ),
                            child: TextFormField(
                              cursorColor:
                                  Theme.of(context).colorScheme.fontColor,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  validateField(value, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText:
                                    getTranslated(context, WITHDRWAL_AMT)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: amtC,
                            ),
                          ),
                          /*  Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20.0,
                              0,
                              20.0,
                              0,
                            ),
                            child: TextFormField(
                              cursorColor:
                                  Theme.of(context).colorScheme.fontColor,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              validator: (value) =>
                                  validateField(value, context),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: BANK_DETAIL,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: bankDetailC,
                            ),
                          ), */

                          Padding(
                            padding: const EdgeInsets.only(top: 20, left: 20),
                            child: Text(getTranslated(context, BANK_DETAIL)!,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor)),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20.0,
                              0,
                              20.0,
                              0,
                            ),
                            child: TextFormField(
                              cursorColor:
                                  Theme.of(context).colorScheme.fontColor,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              validator: (value) =>
                                  validateField(value, context),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, Acc_num),
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: acc_num,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20.0,
                              0,
                              20.0,
                              0,
                            ),
                            child: TextFormField(
                              cursorColor:
                                  Theme.of(context).colorScheme.fontColor,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              validator: (value) =>
                                  validateField(value, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, IFSC),
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: ifsc_code,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20.0,
                              0,
                              20.0,
                              0,
                            ),
                            child: TextFormField(
                              cursorColor:
                                  Theme.of(context).colorScheme.fontColor,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              validator: (value) =>
                                  validateField(value, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, BK_Name),
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: acc_name,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, CANCEL)!,
                    style: Theme.of(this.context)
                        .textTheme
                        .titleSmall!
                        .copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                    child: Text(
                      getTranslated(context, SEND_LBL)!,
                      style:
                          Theme.of(this.context).textTheme.titleSmall!.copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    onPressed: () {
                      final form = _formkey.currentState!;
                      if (form.validate()) {
                        form.save();
                        setState(
                          () {
                            Navigator.pop(context);
                          },
                        );
                        sendRequest();
                      }
                    })
              ],
            );
          },
        );
      },
    );
  }

  listItem(int index) {
    Color back;
    if (tranList[index].status == "success" ||
        tranList[index].status == ACCEPTED) {
      back = Colors.green;
    } else if (tranList[index].status == PENDING) {
      back = Colors.orange;
    } else {
      back = Colors.red;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "${getTranslated(context, AMT_LBL)!} : ${getPriceFormat(
                      context,
                      double.parse(
                        tranList[index].amt!,
                      ),
                    )!}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.fontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tranList[index].date!,
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "${getTranslated(context, ID_LBL)!} : ${tranList[index].id!}",
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: back,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(
                          4.0,
                        ),
                      ),
                    ),
                    child: Text(
                      capitalize(tranList[index].status!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.white,
                      ),
                    ),
                  )
                ],
              ),
              tranList[index].opnBal != "" &&
                      tranList[index].opnBal != null &&
                      tranList[index].opnBal!.isNotEmpty
                  ? Text(
                      "${getTranslated(context, OPNBL_LBL)!} : ${tranList[index].opnBal!}",
                    )
                  : Container(),
              tranList[index].clsBal != "" &&
                      tranList[index].clsBal != null &&
                      tranList[index].clsBal!.isNotEmpty
                  ? Text(
                      "${getTranslated(context, CLBL_LBL)!} : ${tranList[index].clsBal!}",
                    )
                  : Container(),
              tranList[index].msg != "" && tranList[index].msg!.isNotEmpty
                  ? Text(
                      "${getTranslated(context, MSG_LBL)!} : ${tranList[index].msg!}",
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
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
                      getTransaction();
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

  Future<void> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
            await post(getFundTransferApi, headers: headers, body: parameter)
                .timeout(const Duration(seconds: timeOut));
        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(
          getTranslated(context, somethingMSg)!,
        );
        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }

    return;
  }

  Future<void> getRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };
        print("request parameter: $parameter");
        Response response =
            await post(getWithReqApi, headers: headers, body: parameter)
                .timeout(const Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromReqJson(data))
                  .toList();

              tranList.addAll(tempList.reversed);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(
          getTranslated(context, somethingMSg)!,
        );
        setState(
          () {
            _isLoading = false;
            isLoadingmore = false;
          },
        );
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }

    return;
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

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    if (isRequest) {
      setState(() {
        _isLoading = true;
      });
      offset = 0;
      total = 0;

      tranList.clear();
      return getRequest();
    } else {
      setState(
        () {
          _isLoading = true;
        },
      );
      offset = 0;
      total = 0;
      tranList.clear();
      return getTransaction();
    }
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            isLoadingmore = true;

            if (offset < total) getTransaction();
          },
        );
      }
    }
  }
}
