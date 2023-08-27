import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../Helper/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/dashedRect.dart';
//import 'package:mime/mime.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateProfile();
}

String? lat, long;

class StateProfile extends State<Profile> with TickerProviderStateMixin {
  String name = "",
      email = "",
      mobile = "",
      address = "",
      curPass = "",
      newPass = "",
      confPass = "",
      loaction = "";

  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController? nameC,
      emailC,
      mobileC,
      addressC,
      curPassC,
      newPassC,
      confPassC;
  bool isSelected = false, isArea = true;
  bool _isNetworkAvail = true;
  bool _showCurPassword = false, _showPassword = false, _showCmPassword = false;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  List<File> licenseImages = [];
  List<String> licenseGetImages = [];

  @override
  void initState() {
    super.initState();

    mobileC = TextEditingController();
    nameC = TextEditingController();
    emailC = TextEditingController();

    addressC = TextEditingController();
    getUserDetails();

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

  @override
  void dispose() {
    buttonController!.dispose();
    mobileC?.dispose();
    nameC?.dispose();
    addressC!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled catch (_) {}
  }

  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID) ?? "";
    mobile = await getPrefrence(MOBILE) ?? "";
    name = await getPrefrence(USERNAME) ?? "";
    email = await getPrefrence(EMAIL) ?? "";
    licenseGetImages = await getListPrefrence(DRIVING_LICENSE) ?? [];

    address = await getPrefrence(ADDRESS) ?? "";
    //image = await getPrefrence(IMAGE) ?? "";
    mobileC!.text = mobile;
    nameC!.text = name;
    emailC!.text = email;

    addressC!.text = address;

    setState(
      () {},
    );
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

  void validateAndSubmit() async {
    if (validateAndSave()) {
      checkNetwork(1);
    }
  }

  Future<void> checkNetwork(int from) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setUpdateUser(from);
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }
  }

  bool validateAndSave() {
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Future<void> setDrivingLicense(List<File> image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      try {
        var request = http.MultipartRequest("POST", getUpdateUserApi);
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID!;
        if (licenseImages.isNotEmpty) {
          for (var i = 0; i < licenseImages.length; i++) {
            var pic = await http.MultipartFile.fromPath(
              DRIVING_LICENSE_OTHER,
              licenseImages[i].path,
            );

            request.files.add(pic);
          }
        }
        print("request field****${request.fields}****${request.files}");

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);

        var getdata = json.decode(responseString);
        print("getdata******$getdata*******${response.statusCode}");
        bool error = getdata["error"];
        String? msg = getdata['message'];
        if (!error) {
          CUR_DRIVING_LICENSE = getdata[DRIVING_LICENSE];
          setListPrefrence(DRIVING_LICENSE, CUR_DRIVING_LICENSE);
        }
        setSnackbar(msg!);

        setState(() {
          _isLoading = false;
        });
      } on TimeoutException catch (_) {
        setSnackbar(somethingMSg);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Future<void> setUpdateUser(int from) async {
    setState(() {
      _isLoading = true;
    });
    var data = {USER_ID: CUR_USERID, USERNAME: name, EMAIL: email};
    if (newPass != "" && newPass != "") {
      data[NEWPASS] = newPass;
    }
    if (curPass != "" && curPass != "") {
      data[OLDPASS] = curPass;
    }

    if (address != "" && address != "") {
      data[ADDRESS] = address;
    }

    http.Response response = await http
        .post(getUpdateUserApi, body: data, headers: headers)
        .timeout(const Duration(seconds: timeOut));

    if (response.statusCode == 200) {
      var getdata = json.decode(response.body);

      bool error = getdata["error"];
      String? msg = getdata["message"];
      await buttonController!.reverse();
      if (!error) {
        CUR_USERNAME = name;
        saveUserDetail(CUR_USERID!, name, email, mobile);
        if (from == 2) {
          setSnackbar(getTranslated(context, 'PASS_UPDATE_SUCCESS_MSG')!);
        } else {
          setSnackbar(msg!);
        }
      } else {
        setSnackbar(msg!);
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Theme.of(context).colorScheme.white,
        elevation: 1.0,
      ),
    );
  }

  setUser() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        children: <Widget>[
          Image.asset(
            'assets/images/username.png',
            fit: BoxFit.fill,
            color: Theme.of(context).colorScheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, NAME_LBL)!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.lightfontColor2,
                        fontWeight: FontWeight.normal,
                      ),
                ),
                name != ""
                    ? Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color:
                                  Theme.of(context).colorScheme.lightfontColor,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    : Container()
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 20,
              color: Theme.of(context).colorScheme.lightfontColor,
            ),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(0),
                    elevation: 2.0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                          5.0,
                        ),
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            20.0,
                            20.0,
                            0,
                            2.0,
                          ),
                          child: Text(
                            getTranslated(context, ADD_NAME_LBL)!,
                            style: Theme.of(this.context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor),
                          ),
                        ),
                        const Divider(),
                        Form(
                          key: _formKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              cursorColor:
                                  Theme.of(context).colorScheme.fontColor,
                              keyboardType: TextInputType.text,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal),
                              validator: (value) =>
                                  validateUserName(value, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              controller: nameC,
                              onChanged: (v) => setState(
                                () {
                                  name = v;
                                },
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                          child: Text(
                            getTranslated(context, CANCEL)!,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.lightfontColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            setState(
                              () {
                                Navigator.pop(context);
                              },
                            );
                          }),
                      TextButton(
                        child: Text(
                          getTranslated(context, SAVE_LBL)!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          final form = _formKey.currentState!;
                          if (form.validate()) {
                            form.save();
                            setState(
                              () {
                                name = nameC!.text;
                                Navigator.pop(context);
                              },
                            );
                            validateAndSubmit();
                          }
                        },
                      )
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  setMobileNo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
      child: Row(
        children: <Widget>[
          Image.asset(
            'assets/images/mobilenumber.png',
            fit: BoxFit.fill,
            color: Theme.of(context).colorScheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, MOBILEHINT_LBL)!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.lightfontColor2,
                      fontWeight: FontWeight.normal),
                ),
                mobile != "" && mobile != ""
                    ? Text(
                        mobile,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              color:
                                  Theme.of(context).colorScheme.lightfontColor,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    : Container()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget getDrivingLicense() {
    print("license get images*****${licenseGetImages.length}");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset(
            'assets/images/drivinglicense.png',
            height: 23,
            width: 23,
            fit: BoxFit.fill,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 15.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getTranslated(context, 'DRIVING_LICENSE_LBL')!,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.lightfontColor2,
                        fontWeight: FontWeight.normal,
                      ),
                ),
                const SizedBox(height: 15.0),
                SizedBox(
                  height: 110, // Adjust the height according to your needs
                  child: licenseGetImages.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: licenseGetImages.length,
                          itemBuilder: (context, index) {
                            // Build your list item widgets here
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                  start: index != 0 ? 10 : 0),
                              child: InkWell(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: FadeInImage(
                                      fadeInDuration:
                                          const Duration(milliseconds: 150),
                                      image:
                                          NetworkImage(licenseGetImages[index]),
                                      height: 100.0,
                                      fit: BoxFit.fill,
                                      width: deviceWidth! / 2.7,
                                      placeholder: placeHolder(90),
                                      imageErrorBuilder:
                                          ((context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/placeholder.png',
                                          height: 90,
                                          width: 90,
                                        );
                                      }),
                                      placeholderErrorBuilder:
                                          ((context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/placeholder.png',
                                          height: 90,
                                          width: 90,
                                        );
                                      })),
                                ),
                                onTap: () {
                                  _imgFromGallery();
                                },
                              ),
                            ); // Widget for each list item
                          },
                        )
                      : uploadOtherImage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _imgFromGallery() async {
    List<XFile>? pickedFileList = await ImagePicker().pickMultiImage(
      maxWidth: 1800,
      maxHeight: 1800,
    );
    licenseImages.clear();
    if (pickedFileList.isNotEmpty) {
      if (pickedFileList.length < 2) {
        setSnackbar(getTranslated(context, 'PLZ_ADD_FROND_BACK_IMAGE_MSG')!);
      } else if (pickedFileList.length > 2) {
        setSnackbar(getTranslated(context, 'ADD_ONLY_TWO_IMAGES')!);
      } else {
        licenseGetImages.clear();
        for (int i = 0; i < pickedFileList.length; i++) {
          licenseImages.add(File(pickedFileList[i].path));
        }

        await setDrivingLicense(licenseImages);

        setState(() {});
      }
    }
  }

  Widget uploadOtherImage() {
    return licenseImages.isEmpty
        ? InkWell(
            onTap: () {
              _imgFromGallery();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 110,
                  width: deviceWidth! / 2.7,
                  child: DashedRect(
                    color: Theme.of(context).colorScheme.fontColor,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.7),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 5),
                            child: Expanded(
                              child: Text(
                                getTranslated(context, 'FRONT_SIDE_IMAGE_LBL')!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.5)),
                              ),
                            ),
                          )
                        ]),
                  ),
                ),
                SizedBox(
                  height: 110,
                  width: deviceWidth! / 2.7,
                  child: DashedRect(
                    color: Theme.of(context).colorScheme.fontColor,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.7),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 5),
                            child: Expanded(
                              child: Text(
                                getTranslated(context, 'BACK_SIDE_IMAGE_LBL')!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.5)),
                              ),
                            ),
                          )
                        ]),
                  ),
                ),
              ],
            ),
          )
        : InkWell(
            onTap: () {
              _imgFromGallery();
            },
            child: SizedBox(
                height: 110,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: licenseImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsetsDirectional.only(
                          start: index != 0 ? 10 : 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          licenseImages[index],
                          height: 100.0,
                          fit: BoxFit.fill,
                          width: deviceWidth! / 2.7,
                        ),
                      ),
                    );
                  },
                )),
          );
  }

/*  Widget modelOtherImage() {
    return widget.model.imageDataList!.isNotEmpty
        ? Padding(
        padding: const EdgeInsets.only(top: 25),
        child: SizedBox(
            height: 125,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: widget.model.imageDataList!.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(left: 0.0, right: 0.0),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: 10, end: 8),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: CustomNetworkImage(
                              networkImageUrl: widget
                                  .model.imageDataList![index].otherImage!,
                              isVideo: false,
                              fit: BoxFit.cover,
                              height: 125,
                              width: 95,
                            )),
                      ),
                      BlocConsumer<DeleteImageCubit, DeleteImageState>(
                          bloc: context.read<DeleteImageCubit>(),
                          listener: (context, state) {
                            if (state is DeleteImageSuccess) {
                              context
                                  .read<GetUserNewsCubit>()
                                  .deleteImageId(index);
                              showSnackBar(state.message, context);
                              Navigator.pop(context);
                            }
                          },
                          builder: (context, state) {
                            return Positioned.directional(
                                textDirection: Directionality.of(context),
                                end: 0,
                                child: Container(
                                    height: 18,
                                    width: 18,
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.all(3.0),
                                    decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(25.0),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .background),
                                    child: InkWell(
                                      // backgroundColor:
                                      //     UiUtils.getColorScheme(context).background,
                                      child: Icon(
                                        Icons.close,
                                        size: 13,
                                        color:
                                        UiUtils.getColorScheme(context)
                                            .background,
                                      ),

                                      onTap: () {
                                        context
                                            .read<DeleteImageCubit>()
                                            .setDeleteImage(
                                            imageId: widget
                                                .model
                                                .imageDataList![index]
                                                .id!);
                                      },
                                    )));
                          })
                    ],
                  ),
                );
              },
            )))
        : const SizedBox.shrink();
  }*/

/*  Widget uploadDrivingLicense() {
    return InkWell(
      onTap: () {
        _showPicker();
      },
      child:  == null
          ? Container(
        height: 125,
        width: double.maxFinite,
        decoration:
        BoxDecoration(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.only(top: 25),
        child: DashedRect(
          color: Theme.of(context).colorScheme.fontColor,
          child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              Icons.image,
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 10),
              child: Text('UPLOAD_MAIN_IMAGE_LBL',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(
                    color: Theme.of(context).colorScheme.fontColor
                        .withOpacity(0.5)),
              ),
            )
          ]),
        ),
      )
          : Padding(
        padding: const EdgeInsets.only(top: 25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            image!,
            height: 125,
            width: double.maxFinite,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }*/

  changePass() {
    return SizedBox(
      height: 60,
      width: deviceWidth,
      child: Card(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(
              10.0,
            ),
          ),
        ),
        child: InkWell(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              top: 15.0,
              bottom: 15.0,
            ),
            child: Text(
              getTranslated(context, CHANGE_PASS_LBL)!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.fontColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          onTap: () {
            _showDialog();
          },
        ),
      ),
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
                        getTranslated(context, CHANGE_PASS_LBL)!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                                color: Theme.of(context).colorScheme.fontColor),
                      ),
                    ),
                    const Divider(),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              keyboardType: TextInputType.text,
                              validator: (value) =>
                                  validatePass(value, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, CUR_PASS_LBL)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightfontColor,
                                        fontWeight: FontWeight.normal),
                                suffixIcon: IconButton(
                                  icon: Icon(_showCurPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  iconSize: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .lightfontColor,
                                  onPressed: () {
                                    setStater(
                                      () {
                                        _showCurPassword = !_showCurPassword;
                                      },
                                    );
                                  },
                                ),
                              ),
                              obscureText: !_showCurPassword,
                              controller: curPassC,
                              onChanged: (v) => setState(
                                () {
                                  curPass = v;
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              keyboardType: TextInputType.text,
                              validator: (value) =>
                                  validatePass(value, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(context, NEW_PASS_LBL)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightfontColor,
                                        fontWeight: FontWeight.normal),
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  iconSize: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .lightfontColor,
                                  onPressed: () {
                                    setStater(
                                      () {
                                        _showPassword = !_showPassword;
                                      },
                                    );
                                  },
                                ),
                              ),
                              obscureText: !_showPassword,
                              controller: newPassC,
                              onChanged: (v) => setState(
                                () {
                                  newPass = v;
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return getTranslated(
                                      context, CON_PASS_REQUIRED_MSG)!;
                                }
                                if (value != newPass) {
                                  return getTranslated(
                                      context, CON_PASS_NOT_MATCH_MSG)!;
                                } else {
                                  return null;
                                }
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: getTranslated(
                                    context, CONFIRMPASSHINT_LBL)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightfontColor,
                                      fontWeight: FontWeight.normal,
                                    ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showCmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  iconSize: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .lightfontColor,
                                  onPressed: () {
                                    setStater(
                                      () {
                                        _showCmPassword = !_showCmPassword;
                                      },
                                    );
                                  },
                                ),
                              ),
                              obscureText: !_showCmPassword,
                              controller: confPassC,
                              onChanged: (v) => setState(
                                () {
                                  confPass = v;
                                },
                              ),
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
                    getTranslated(context, SAVE_LBL)!,
                    style:
                        Theme.of(this.context).textTheme.titleSmall!.copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  onPressed: () {
                    final form = _formKey.currentState!;
                    if (form.validate()) {
                      form.save();
                      setState(
                        () {
                          Navigator.pop(context);
                        },
                      );
                      checkNetwork(2);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  profileImage() {
    return Container(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 30.0,
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: const Icon(
            Icons.account_circle,
            size: 100,
          ),
        ),
      ),
    );
  }

  _getDivider() {
    return const Divider(
      height: 1,
    );
  }

  _showContent1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        child: _isNetworkAvail
            ? Column(
                children: <Widget>[
                  profileImage(),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 5.0,
                    ),
                    child: Card(
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            10.0,
                          ),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          setUser(),
                          _getDivider(),
                          //setEmail(),
                          //_getDivider(),
                          setMobileNo(),
                          _getDivider(),
                          getDrivingLicense(),
                        ],
                      ),
                    ),
                  ),
                  changePass()
                ],
              )
            : noInternet(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      appBar: getAppBar(
        getTranslated(context, EDIT_PROFILE_LBL)!,
        context,
      ),
      body: Stack(
        children: <Widget>[
          _showContent1(),
          showCircularProgress(
              _isLoading, Theme.of(context).colorScheme.primary)
        ],
      ),
    );
  }
}
