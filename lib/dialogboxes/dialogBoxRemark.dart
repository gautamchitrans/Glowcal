import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gur/models/foodPacket.dart';
import 'package:gur/searchScreens/nearbyNGO.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';
import '../Utils/SizeConfig.dart';
import '../Utils/constants.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';

class DialogBoxRemark extends StatefulWidget {
  final String foodAmount;
  DialogBoxRemark(this.foodAmount);
  _DialogBoxRemarkState createState() => _DialogBoxRemarkState();
}

class _DialogBoxRemarkState extends State<DialogBoxRemark> {
  final ScrollController _scrollController = ScrollController();
  TextEditingController remarkController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  double? latitude;
  double? longitude;
  bool isLocationGot = false;

  bool rad = true;

  loc.Location location = loc.Location();
  bool serviceEnabled = false;
  loc.PermissionStatus? permissionStatus;
  loc.LocationData? locationData;

  void toNavigate(double qwer) {
    _scrollController.animateTo(SizeConfig.screenHeight * qwer / 896,
        curve: Curves.easeOut, duration: const Duration(microseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;
    return Dialog(
      insetPadding: EdgeInsets.only(top: h * 400),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(b * 30),
          topRight: Radius.circular(b * 30),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: h * 26),
            padding: EdgeInsets.symmetric(horizontal: b * 20),
            child: Column(
              children: [
                Text(
                  'Remarks for NGO',
                  textAlign: TextAlign.center,
                  style: txtS(textColor, 22, FontWeight.w600),
                ),
                sh(32),
                Container(
                  height: h * 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(0xffff9104).withOpacity(0.31),
                      width: b * 2,
                    ),
                    borderRadius: BorderRadius.circular(b * 18),
                  ),
                  child: TextField(
                    controller: remarkController,
                    onTap: () {
                      toNavigate(60);
                    },
                    style: txtS(textColor, 18, FontWeight.w500),
                    decoration: InputDecoration(
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Enter Remarks',
                      hintStyle: txtS(Color(0xff828282), 18, FontWeight.w500),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: h * 9, horizontal: b * 23),
                    ),
                    maxLines: null,
                  ),
                ),
                sh(38),
                Row(
                  children: [
                    SizedBox(width: b * 20),
                    Text(
                      'Use Geolocation for Address',
                      style: txtS(textColor, 18, FontWeight.w600),
                    ),
                    Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          rad = false;
                          locationController.text = "";
                        });
                        currentLocation();
                      },
                      child: Container(
                        padding: EdgeInsets.all(2.5),
                        height: h * 22,
                        width: b * 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: mc,
                            width: b * 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: b * 7,
                          backgroundColor: rad == false ? mc : Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: b * 20),
                  ],
                ),
                /* sh(30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(color: rc, height: h * 1, width: b * 130),
                    Text(
                      'Or',
                      style: txtS(rc, 14, FontWeight.w500),
                    ),
                    Container(color: rc, height: h * 1, width: b * 130),
                  ],
                ),
                sh(30),
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(0xffff9104).withOpacity(0.31),
                      width: b * 2,
                    ),
                    borderRadius: BorderRadius.circular(b * 18),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    width: b * 300,
                    child: TextFormField(
                      controller: locationController,
                      keyboardType: TextInputType.text,
                      onFieldSubmitted: (String qwert) {
                        toNavigate(0);
                      },
                      onTap: () async {
                        setState(() {
                          rad = false;
                        });
                        toNavigate(500);
                       
                      },
                      style: txtS(textColor, 18, FontWeight.w600),
                      decoration: InputDecoration(
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: "Enter Location Manually",
                        hintStyle: txtS(Color(0xff828282), 16, FontWeight.w600),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: h * 12),
                      ),
                    ),
                  ),
                ), */
                sh(34),
                InkWell(
                  onTap: () async {
                    if (isLocationGot) {
                      Navigator.pop(context);
                      collectFoodPackedData();
                    }
                  },
                  child: Container(
                    height: h * 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isLocationGot ? mc : Color(0xff828282),
                      borderRadius: BorderRadius.circular(b * 46),
                    ),
                    child: Text(
                      'Done',
                      style: txtS(Colors.white, 16, FontWeight.w700),
                    ),
                  ),
                ),
                sh(350),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  collectFoodPackedData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    FoodPacket foodPacket = FoodPacket(
        amount: widget.foodAmount,
        donor: preferences.getString('currentUserName') ?? "",
        donorUID: preferences.getString('currentUserUID') ?? "",
        latitude: latitude ?? 0.0,
        longitude: longitude ?? 0.0,
        remark: remarkController.text.trim(),
        dateTime: Timestamp.now().millisecondsSinceEpoch.toString(),
        isActive: true,
        isAccept: false,
        isDelivered: false);
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return NearbyNGO(foodPacket);
    }));
  }

  currentLocation() async {
    serviceEnabled = await location.serviceEnabled();
    bool permissionsOK;

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (serviceEnabled)
        permissionsOK = true;
      else
        permissionsOK = false;
    } else
      permissionsOK = true;

    permissionStatus = await location.hasPermission();
    if (permissionStatus == loc.PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();

      if (permissionStatus == loc.PermissionStatus.denied ||
          permissionStatus == loc.PermissionStatus.deniedForever) {
        permissionsOK = false;
        Toast.show("Permission Required");
      } else
        permissionsOK = true;
    } else if (permissionStatus == loc.PermissionStatus.deniedForever)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Insufficient Permission"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    else
      permissionsOK = true;

    if (permissionsOK) {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best)
          .then((position) {
        latitude = position.latitude;
        longitude = position.longitude;
        setState(() {
          isLocationGot = true;
        });
      });
    } else
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Insufficient Permission"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
  }
}

TextStyle txtS(Color col, double siz, FontWeight wg) {
  return TextStyle(
    color: col,
    fontWeight: wg,
    fontSize: SizeConfig.screenWidth * siz / 414,
  );
}

SizedBox sh(double h) {
  return SizedBox(height: SizeConfig.screenHeight * h / 896);
}

void dialogBoxRemark(BuildContext context, String foodWeightCode) {
  showAnimatedDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return DialogBoxRemark(foodWeightCode);
    },
    animationType: DialogTransitionType.slideFromBottomFade,
    curve: Curves.fastOutSlowIn,
    duration: Duration(milliseconds: 250),
  );
}
