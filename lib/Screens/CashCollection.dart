import 'dart:async';
import 'dart:convert';
import 'package:deliveryboy/Model/CashCollection_Model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import 'OrderDetail.dart';

class CashCollection extends StatefulWidget {
  const CashCollection({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateCash();
  }
}

int? total, offset;
List<CashColl_Model> cashList = [];
bool _isLoading = true;
bool isLoadingmore = true;
bool isRequest = false;

class StateCash extends State<CashCollection> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  List<CashColl_Model> tempList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  ScrollController controller = ScrollController();
  String? searchText;
  final TextEditingController _controller = TextEditingController();
  String _searchText = "", _lastsearch = "", currentCashCollectionBy = "";
  bool isLoadingmore = true, isGettingdata = false, isNodata = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    offset = 0;
    total = 0;
    cashList.clear();
    getOrder(
      "admin",
      "DESC",
    );
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
    controller.addListener(_scrollListener);
    _controller.addListener(
      () {
        if (_controller.text.isEmpty) {
          if (mounted) {
            setState(
              () {
                _searchText = "";
              },
            );
          }
        } else {
          if (mounted) {
            setState(
              () {
                _searchText = _controller.text;
              },
            );
          }
        }
      },
    );
    super.initState();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            isLoadingmore = true;

            if (offset! < total!) getOrder("delivery", "DESC");
          },
        );
      }
    }
  }

  Future<void> _refresh() {
    if (isRequest) {
      cashList.clear();
      offset = 0;
      total = 0;
      _controller.clear();
      setState(
        () {
          _isLoading = true;
          isLoadingmore = true;
        },
      );
      return getOrder("delivery", "DESC");
    } else {
      setState(() {
        _isLoading = true;
        isLoadingmore = true;
      });
      offset = 0;
      total = 0;
      _controller.clear();
      cashList.clear();
      return getOrder("admin", "DESC");
    }
  }

  Future<void> getOrder(String from, String order) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (isLoadingmore) {
          if (mounted) {
            setState(
              () {
                isLoadingmore = false;
                isGettingdata = true;
                if (offset == 0) {
                  cashList = [];
                }
              },
            );
          }

          if (CUR_USERID != null) {
            var parameter = {
              DELIVERY_BOY_ID: CUR_USERID,
              STATUS: from == "delivery"
                  ? DELIVERY_BOY_CASH
                  : DELIVERY_BOY_CASH_COLL,
              LIMIT: perPage.toString(),
              OFFSET: offset.toString(),
              ORDER_BY: order,
              SEARCH: _searchText.trim(),
            };
            print("cash collection param****$parameter");
            Response response =
                await post(getCashCollection, body: parameter, headers: headers)
                    .timeout(const Duration(seconds: timeOut));

            print("cash collection****${response.statusCode}");
            var getdata = json.decode(response.body);

            print("getdata cash collection****$getdata");
            bool error = getdata["error"];

            isGettingdata = false;
            if (offset == 0) isNodata = error;

            if (!error) {
              var data = getdata["data"];
              var dataDetails = getdata["data"][0]["order_details"];

              if (data.length != 0) {
                List<CashColl_Model> items = [];
                List<CashColl_Model> allitems = [];

                items.addAll((data as List)
                    .map((data) => CashColl_Model.fromJson(data))
                    .toList());

                allitems.addAll(items);

                for (CashColl_Model item in items) {
                  cashList.where((i) => i.id == item.id).map((obj) {
                    allitems.remove(item);
                    return obj;
                  }).toList();
                }
                cashList.addAll(allitems);

                isLoadingmore = true;
                offset = offset! + perPage;
              } else {
                isLoadingmore = false;
              }
            } else {
              isLoadingmore = false;
            }

            if (mounted) {
              setState(
                () {
                  _isLoading = false;
                  currentCashCollectionBy = from;
                },
              );
            }
          } else {
            if (mounted) {
              setState(
                () {
                  isLoadingmore = false;
                },
              );
            }
          }
        }
      } on TimeoutException catch (_) {
        if (mounted) {
          setState(
            () {
              _isLoading = false;
              isLoadingmore = false;
            },
          );
        }
        setSnackbar(somethingMSg);
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

  getAppBar(String title, BuildContext context) {
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
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: shadow(),
          child: Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                return orderSortDialog();
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.swap_vert,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 10,
          ),
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
        ),
      ],
    );
  }

  void orderSortDialog() {
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
                    padding: const EdgeInsets.only(
                      top: 19.0,
                      bottom: 16.0,
                    ),
                    child: Text(
                      getTranslated(context, ORDER_BY_TXT)!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightfontColor),
                    )),
                const Divider(),
                TextButton(
                  child: Text(
                    getTranslated(context, ASC_TXT)!,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                        ),
                  ),
                  onPressed: () {
                    cashList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                      },
                    );

                    getOrder(
                        currentCashCollectionBy == "admin"
                            ? "admin"
                            : "delivery",
                        "ASC");
                    Navigator.pop(context, 'option 1');
                  },
                ),
                const Divider(),
                TextButton(
                  child: Text(
                    getTranslated(context, DESC_TXT)!,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                        ),
                  ),
                  onPressed: () {
                    cashList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                      },
                    );
                    getOrder(
                        currentCashCollectionBy == "admin"
                            ? "admin"
                            : "delivery",
                        "DESC");
                    Navigator.pop(context, 'option 1');
                  },
                ),
                Divider(
                  color: Theme.of(context).colorScheme.white,
                )
              ],
            ),
          ),
        );
      },
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
            contentPadding: const EdgeInsets.all(
              0.0,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 19.0,
                    bottom: 16.0,
                  ),
                  child: Text(
                    getTranslated(context, FILTER_BY)!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightfontColor),
                  ),
                ),
                const Divider(),
                TextButton(
                  child: Text(
                    getTranslated(context, DELIVERY_BOY_CASH_TXT)!,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                        ),
                  ),
                  onPressed: () {
                    cashList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                        isLoadingmore = true;
                        isRequest = true;
                      },
                    );
                    getOrder("delivery", "DESC");
                    Navigator.pop(context, 'option 1');
                  },
                ),
                const Divider(),
                TextButton(
                  child: Text(
                    getTranslated(context, DELIVERY_BOY_CASH_COLL_TXT)!,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.lightfontColor,
                        ),
                  ),
                  onPressed: () {
                    cashList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                        isLoadingmore = true;
                        isRequest = false;
                      },
                    );
                    getOrder("admin", "DESC");
                    Navigator.pop(context, 'option 1');
                  },
                ),
                Divider(
                  color: Theme.of(context).colorScheme.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      appBar: getAppBar(
        getTranslated(context, CASH_COLL)!,
        context,
      ),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer(context)
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
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
                                        " ${getTranslated(context, TOTAL_AMT)!}",
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
                                  cashList.isNotEmpty
                                      ? Text(
                                          getPriceFormat(
                                            context,
                                            double.parse(
                                                cashList[0].cashReceived!),
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
                                        )
                                      : Text(
                                          getPriceFormat(
                                              context, double.parse(" 0"))!,
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
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsetsDirectional.only(
                                start: 5.0, end: 5.0, top: 10.0),
                            child: TextField(
                              controller: _controller,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor),
                              decoration: InputDecoration(
                                filled: true,
                                isDense: true,
                                fillColor: Theme.of(context).colorScheme.white,
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 40, maxHeight: 20),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      if (_lastsearch != _searchText &&
                                          ((_searchText.isNotEmpty))) {
                                        _lastsearch = _searchText;
                                        if (isRequest) {
                                          isLoadingmore = true;
                                          offset = 0;
                                          total = 0;
                                          cashList.clear();

                                          getOrder("delivery", "DESC");
                                        } else {
                                          isLoadingmore = true;
                                          offset = 0;
                                          total = 0;
                                          cashList.clear();
                                          getOrder("admin", "DESC");
                                        }
                                      }
                                    }),
                                hintText: FIND_ORDERS,
                                hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor
                                        .withOpacity(0.3),
                                    fontWeight: FontWeight.normal),
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          cashList.isEmpty
                              ? isGettingdata
                                  ? Container()
                                  : Center(
                                      child: Text(
                                        getTranslated(context, noItem)!,
                                      ),
                                    )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: (offset! < total!)
                                      ? cashList.length + 1
                                      : cashList.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return (index == cashList.length &&
                                            isLoadingmore)
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : orderItem(index);
                                  },
                                ),
                          isGettingdata
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                )
          : noInternet(context),
    );
  }

  orderItem(int index) {
    CashColl_Model model = cashList[index];
    Color back;
    if (model.type == "Collected") {
      back = Colors.green;
    } else {
      back = Theme.of(context).colorScheme.pink;
    }

    return Column(
      children: [
        InkWell(
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.all(5.0),
            child: ClipRRect(
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
                            double.parse(model.amount!),
                          )!}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(model.date!),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (model.orderId! != "" && model.orderId! != "")
                          Text(
                            "${getTranslated(context, ORDER_ID_LBL)!} : ${model.orderId!}",
                          )
                        else
                          Text(
                            "${getTranslated(context, ID_LBL)!} : ${model.id!}",
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
                            capitalize(model.type!),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.white),
                          ),
                        )
                      ],
                    ),
                    Text(
                      "${getTranslated(context, MSG_LBL)!} : ${model.message!}",
                    ),
                  ],
                ),
              ),
            ),
          ),
          onTap: () async {
            if (cashList[index].orderId != "" &&
                cashList[index].orderId != "" &&
                cashList[index].orderDetails!.isNotEmpty) {
              await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => OrderDetail(
                    model: cashList[index].orderDetails![0],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
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
                      getOrder("delivery", "DESC");
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
}
