import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gur/Utils/SizeConfig.dart';
import 'package:gur/Utils/messageUI.dart';
import 'package:gur/homePages/homeMainInd.dart';
import 'package:gur/homePages/homeMainNGO.dart';
import 'package:gur/homePages/homeMainOrg.dart';
import 'package:gur/models/msg.dart';
import 'package:location/location.dart' as loc;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Utils/constants.dart';

class ChatScreen extends StatefulWidget {
  final String? receiverUid;
  final String? senderUID;
  final String? receiverName;

  ChatScreen({this.receiverUid, this.senderUID, this.receiverName});

  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController scrollController;

  ScrollController _scrollController = new ScrollController();
  var _formKey = GlobalKey<FormState>();
  var map = Map<String, dynamic>();
  late CollectionReference _collectionReference;
  late DocumentSnapshot documentSnapshot;
  var listItem;
  late String receiverPhotoUrl, senderPhotoUrl, receiverName, senderName;
  StreamSubscription<DocumentSnapshot>? subscription;
  late File imageFile;
  late TextEditingController _messageController;
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool acceptOrNot = false;
  bool isRejected = false;
  late int userType;
  String donationUIDOnlyForNGOSide = "";
  String userTypeString = '';
  bool accepted = false;
  bool isDelivered = false;
  void tolast() {
    _scrollController.animateTo(
      0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 1),
    );
  }

  @override
  void initState() {
    super.initState();

    loadType();

    _messageController = TextEditingController();

    FirebaseFirestore.instance
        .collection('donations')
        .where('donatedTo', isEqualTo: widget.senderUID)
        .where('donorUID', isEqualTo: widget.receiverUid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((event) {
      setState(() {
        donationUIDOnlyForNGOSide = event.docs[0].id;
      });
    });

    FirebaseFirestore.instance
        .collection('donorChats')
        .doc('lists')
        .collection(widget.receiverUid ?? "")
        .doc(widget.senderUID)
        .snapshots()
        .listen((event) {
      setState(() {
        if (event.data()?['isAccept'] != null)
          acceptOrNot = event.data()?['isAccept'];
        if (event.data()?['isDelivered'] != null)
          isDelivered = event.data()?['isDelivered'];
        if (event.data()?['isRejected'] != null)
          isRejected = event.data()?['isRejected'];
      });
    });
  }

  loadType() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String tempType = pref.getString('currentUserType') ?? "";
    userTypeString = tempType;

    setState(() {
      if (tempType == 'ngo')
        userType = 1;
      else
        userType = 0;
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }

  void addMessageToDb(Message message) async {
    map = message.toMap().cast();
    _collectionReference = FirebaseFirestore.instance
        .collection('donorChats')
        .doc('messages')
        .collection("messages")
        .doc(widget.senderUID)
        .collection(widget.receiverUid ?? "");

    _collectionReference.add(map).whenComplete(() {
      print("Messages added to db");
    });

    _collectionReference = FirebaseFirestore.instance
        .collection('donorChats')
        .doc('messages')
        .collection("messages")
        .doc(widget.receiverUid)
        .collection(widget.senderUID ?? "");

    _collectionReference.add(map).whenComplete(() {
      print("Messages added to db");
    });
    _messageController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Form(
          key: _formKey,
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  height: h * 60,
                  padding: EdgeInsets.symmetric(horizontal: b * 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: b * 4,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          height: h * 30,
                          width: b * 30,
                          child: SvgPicture.asset(
                            'images/Arrow1.svg',
                            allowDrawingOutsideViewBox: true,
                          ),
                        ),
                      ),
                      SizedBox(width: b * 10),
                      Text(
                        widget.receiverName == null
                            ? 'Messages'
                            : widget.receiverName ??
                                "", //name of user to be displayed
                        style: txtS(mc, 20, FontWeight.w600),
                      ),
                      Spacer(),
                      userTypeString == 'ngo'
                          ? MaterialButton(
                              height: h * 30,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(b * 6),
                              ),
                              color: Color(0xFF28797c),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onPressed: () {
                                dialogBoxReceived(context);
                                setState(() {
                                  accepted = !accepted;
                                });
                              },
                              child: Container(
                                color: Color(0xFF28797c),
                                child: Text(
                                  "Order Received??",
                                  style:
                                      txtS(Colors.white, 10, FontWeight.w500),
                                ),
                              ),
                            )
                          : SizedBox(),
                      SizedBox(width: b * 10),
                      userTypeString == 'ngo'
                          ? acceptOrNot
                              ? SizedBox()
                              : InkWell(
                                  onTap: () {
                                    dialogBoxContact(context);
                                  },
                                  child: Icon(MdiIcons.accountBox, color: mc),
                                )
                          : SizedBox(),
                    ],
                  ),
                ),
                isDelivered
                    ? Text("This Donation has been delivered")
                    : isRejected
                        ? Text("Oops! This donation has been Rejected")
                        : userType == 1
                            ? acceptOrNot
                                ? ChatMessagesListWidget()
                                : collectionReq()
                            : ChatMessagesListWidget(),
                acceptOrNot ? ChatInputWidget() : notAcceptedText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      launch(url);
    } else {
      throw "Could not launch $url";
    }
  }

  Widget ChatInputWidget() {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: b * 10, vertical: h * 15),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Container(
              child: TextFormField(
                validator: (String? input) {
                  if (input!.isEmpty) {
                    return "Please enter message";
                  }
                  return null;
                },
                style: txtS(Color(0xff828282), 14, FontWeight.w500),
                minLines: 1,
                maxLines: 4,
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: txtS(Color(0xff828282), 13, FontWeight.w400),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: h * 16,
                    horizontal: b * 20,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(b * 60),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(b * 60),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(b * 60),
                  ),
                  suffixIcon: InkWell(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: b * 6, vertical: h * 5),
                      height: h * 39,
                      width: h * 39,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        child: SvgPicture.asset(
                          'images/Send1.svg',
                          allowDrawingOutsideViewBox: true,
                          height: h * 15,
                          width: b * 15,
                        ),
                      ),
                    ),
                    onTap: () {
                      tolast();
                      if (_formKey.currentState!.validate()) {
                        //sendNotification(_messageController.text);
                        //initLocalDB(_messageController.text);
                        sendMessage();
                        //dialogBoxContact(context);
                        //viewLocationInMaps();
                      }
                    },
                  ),
                  fillColor: Color(0xfffff2e1),
                  filled: true,
                ),
                onFieldSubmitted: (value) {
                  _messageController.text = value;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void dialogBoxReceived(BuildContext context) {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;

    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: b * 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(b * 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: h * 20),
                padding: EdgeInsets.symmetric(horizontal: b * 22),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: b * 0),
                      child: Text(
                        'Are you sure the package is received by you?',
                        textAlign: TextAlign.center,
                        style: txtS(textColor, 16, FontWeight.w500),
                      ),
                    ),
                    SizedBox(height: h * 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MaterialButton(
                          elevation: 5,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(b * 36),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            width: b * 97,
                            height: h * 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(b * 36),
                              border: Border.all(
                                color: Color(0xff28797c),
                                width: b * 2,
                              ),
                            ),
                            child: Text(
                              'NO',
                              style:
                                  txtS(Color(0xff28797c), 16, FontWeight.w600),
                            ),
                          ),
                        ),
                        MaterialButton(
                          elevation: 5,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            onPackageDelivered();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(b * 36),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            width: b * 97,
                            height: h * 40,
                            decoration: BoxDecoration(
                              color: Color(0xff28797c),
                              borderRadius: BorderRadius.circular(b * 36),
                            ),
                            child: Text(
                              'YES',
                              style: txtS(Colors.white, 16, FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
      animationType: DialogTransitionType.fadeScale,
      curve: Curves.fastOutSlowIn,
      duration: Duration(milliseconds: 300),
    );
  }

  Widget notAcceptedText() {
    return Text(isDelivered
        ? "This package has been delivered"
        : userTypeString == 'ngo'
            ? "Accept the request to start this conversation"
            : "Wait for NGO to accept your request");
  }

  Widget contactDetails(String name, String phone, String colorType) {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(
        padding: EdgeInsets.fromLTRB(b * 25, h * 15, b * 20, h * 19),
        margin: EdgeInsets.only(right: b * 20),
        width: b * 260,
        decoration: BoxDecoration(
          color: colorType == 'sender' ? Color(0xfff1f1f1) : Color(0xfffff2e1),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(b * 30),
            topLeft: Radius.circular(b * 30),
            topRight: Radius.circular(b * 30),
            bottomRight: Radius.circular(b * 30),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            userTypeString == 'ngo'
                ? 'Hey! I have accepted your request for Donation'
                : "Hey! NGO has accepted your Donation", //username to be added
            style: txtS(textColor, 14, FontWeight.w600),
          ),
          SizedBox(height: h * 15),
          Text(
            userTypeString == 'ngo'
                ? 'My contact details are:'
                : 'Valet Contact Details:',
            style: txtS(textColor, 14, FontWeight.w600),
          ),
          SizedBox(height: h * 10),
          Row(
            children: [
              Text(
                'Name:   ',
                style: txtS(textColor, 14, FontWeight.w600),
              ),
              Text(
                name,
                style: txtS(textColor, 14, FontWeight.w400),
              ),
            ],
          ),
          SizedBox(height: h * 5),
          Row(
            children: [
              Text(
                'Phone:  ',
                style: txtS(textColor, 14, FontWeight.w600),
              ),
              InkWell(
                splashColor: Colors.white,
                highlightColor: Colors.white,
                onTap: () {
                  launchUrl("tel:$phone");
                },
                child: Text(
                  phone,
                  style: txtS(textColor, 14, FontWeight.w400),
                ),
              ),
              SizedBox(width: b * 10),
              InkWell(
                splashColor: Colors.white,
                highlightColor: Colors.white,
                onTap: () {
                  launchUrl("tel:$phone");
                },
                child: Icon(Icons.call_outlined,
                    color: Colors.green, size: b * 16),
              ),
            ],
          ),
        ]),
      ),
    ]);
  }

  Widget collectionReq() {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;
    return Container(
      margin: EdgeInsets.only(right: b * 130, left: b * 20),
      height: h * 170,
      width: b * 260,
      decoration: BoxDecoration(
        color: Color(0xfffff2e1),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(b * 30),
          topLeft: Radius.circular(b * 30),
          topRight: Radius.circular(b * 30),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(b * 20, h * 17, b * 50, h * 19),
            child: Text(
              'Hey! You\'ve got a food collection request.',
              style: txtS(textColor, 14, FontWeight.w600),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: b * 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    getDonationLocationInMaps();
                  },
                  child: Column(
                    children: [
                      Container(
                        height: h * 30,
                        width: b * 30,
                        child: SvgPicture.asset(
                          'images/map.svg',
                          allowDrawingOutsideViewBox: true,
                        ),
                      ),
                      sh(5),
                      Text(
                        'Get Location',
                        style: txtS(textColor, 10, FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    donationAccepted();
                  },
                  child: Column(
                    children: [
                      Container(
                        height: h * 30,
                        width: b * 30,
                        child: SvgPicture.asset(
                          'images/Tick Square.svg',
                          allowDrawingOutsideViewBox: true,
                        ),
                      ),
                      sh(5),
                      Text(
                        'Happy to Take it',
                        style: txtS(textColor, 10, FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    donationRejected();
                  },
                  child: Column(
                    children: [
                      Container(
                        height: h * 30,
                        width: b * 30,
                        child: SvgPicture.asset(
                          'images/Close Square.svg',
                          allowDrawingOutsideViewBox: true,
                        ),
                      ),
                      sh(5),
                      Text(
                        'Can\'t go Now',
                        style: txtS(textColor, 10, FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SizedBox sh(double h) {
    return SizedBox(height: h * h / 896);
  }

  TextStyle txtS(Color col, double siz, FontWeight wg) {
    return TextStyle(
      color: col,
      fontWeight: wg,
      fontSize: SizeConfig.screenWidth * siz / 414,
    );
  }

  void sendMessage() async {
    var text = _messageController.text;
    Message _message = Message(
        receiverUid: widget.receiverUid,
        senderUid: widget.senderUID,
        message: text,
        timestamp: FieldValue.serverTimestamp(),
        type: 'text');
    print(
        "receiverUid: ${widget.receiverUid} , senderUid : $widget.senderUID , message: $text");
    print(
        "timestamp: ${DateTime.now().millisecond}, type: ${text != "" ? 'text' : 'image'}");
    addMessageToDb(_message);
  }

  Future<DocumentSnapshot> getSenderPhotoUrl(String uid) {
    var senderDocumentSnapshot =
        FirebaseFirestore.instance.collection('users').doc(uid).get();
    return senderDocumentSnapshot;
  }

  Future<DocumentSnapshot> getReceiverPhotoUrl(String uid) {
    var receiverDocumentSnapshot =
        FirebaseFirestore.instance.collection('users').doc(uid).get();
    return receiverDocumentSnapshot;
  }

  Widget ChatMessagesListWidget() {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;
    return Flexible(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('donorChats')
            .doc('messages')
            .collection('messages')
            .doc(widget.senderUID)
            .collection(widget.receiverUid ?? "")
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            int rev = snapshot.data!.docs.length - 1;
            listItem = snapshot.data!.docs;
            return ListView.builder(
              physics: BouncingScrollPhysics(),
              controller: _scrollController,
              padding:
                  EdgeInsets.symmetric(horizontal: b * 10, vertical: h * 10),
              reverse: true,
              itemBuilder: (context, index) =>
                  chatMessageItem(snapshot.data!.docs[rev - index]),
              itemCount: snapshot.data!.docs.length,
            );
          }
        },
      ),
    );
  }

  Widget chatMessageItem(DocumentSnapshot documentSnapshot) {
    return buildChatLayout(documentSnapshot);
  }

  Widget buildChatLayout(DocumentSnapshot snap) {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: b * 5),
          child: Row(
            mainAxisAlignment: snap['senderUid'] == widget.senderUID
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: <Widget>[
              snap['senderUid'] == widget.senderUID
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        snap['type'] == 'text'
                            ? Row(children: [
                                Text(
                                  giveTime(snap['timestamp']),
                                  style: txtS(
                                      Color(0xff7d7d7d), 10, FontWeight.w600),
                                ),
                                SizedBox(width: b * 5),
                                CustomPaint(
                                  painter: ChatBubble(
                                    color: Color(0xfff1f1f1),
                                    alignment: Alignment.topRight,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(
                                        b * 17, h * 10, b * 15, h * 10),
                                    constraints: BoxConstraints(
                                      minWidth: 0,
                                      maxWidth: SizeConfig.screenWidth * 0.5,
                                    ),
                                    child: Text(
                                      snap['message'],
                                      maxLines: null,
                                      style:
                                          txtS(textColor, 14, FontWeight.w400),
                                    ),
                                  ),
                                ),
                              ])
                            : snap['type'] == 'contactCard'
                                ? contactDetails(snap['pickUpPersonName'],
                                    snap['pickUpPersonContact'], 'sender')
                                : SizedBox(),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: h * 7),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        snap['type'] == 'text'
                            ? Row(children: [
                                CustomPaint(
                                  painter: ChatBubble(
                                    color: Color(0xfffff2e1),
                                    alignment: Alignment.topLeft,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(
                                        b * 17, h * 10, b * 15, h * 10),
                                    constraints: BoxConstraints(
                                      minWidth: 0,
                                      maxWidth: SizeConfig.screenWidth * 0.55,
                                    ),
                                    child: Text(
                                      snap['message'],
                                      maxLines: null,
                                      style:
                                          txtS(textColor, 14, FontWeight.w400),
                                    ),
                                  ),
                                ),
                                SizedBox(width: b * 5),
                                Text(
                                  giveTime(snap['timestamp']),
                                  style: txtS(
                                      Color(0xff7d7d7d), 10, FontWeight.w600),
                                ),
                              ])
                            : snap['type'] == 'contactCard'
                                ? contactDetails(snap['pickUpPersonName'],
                                    snap['pickUpPersonContact'], 'receiver')
                                : SizedBox(),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: h * 7),
                        ),
                      ],
                    )
            ],
          ),
        ),
      ],
    );
  }

  void dialogBoxContact(BuildContext context) {
    var b = SizeConfig.screenWidth / 414;
    var h = SizeConfig.screenHeight / 896;

    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              EdgeInsets.only(top: h * 0, left: b * 20, right: b * 20),
          child: Container(
            height: h * 335,
            decoration: BoxDecoration(
              color: Color(0xfff1f1f1),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(b * 30),
                topLeft: Radius.circular(b * 30),
                topRight: Radius.circular(b * 30),
              ),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: EdgeInsets.fromLTRB(b * 25, h * 27, b * 60, h * 19),
                child: Text(
                  'You Have accepted request for the donation.',
                  style: txtS(textColor, 20, FontWeight.w500),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(b * 25, h * 0, b * 0, h * 37),
                child: Text(
                  'Share your Contact',
                  style: txtS(textColor, 14, FontWeight.w700),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: b * 25),
                padding: EdgeInsets.symmetric(horizontal: b * 16),
                height: h * 40,
                width: 212 * b,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(b * 10),
                ),
                child: TextField(
                  controller: nameController,
                  style: txtS(textColor, 15, FontWeight.w500),
                  decoration: dec('Name'),
                ),
              ),
              SizedBox(height: h * 17),
              Container(
                margin: EdgeInsets.only(left: b * 25),
                padding: EdgeInsets.symmetric(horizontal: b * 16),
                height: h * 40,
                width: 212 * b,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(b * 10),
                ),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: phoneController,
                  style: txtS(textColor, 15, FontWeight.w500),
                  decoration: dec('Phone Number'),
                ),
              ),
              SizedBox(height: h * 28),
              InkWell(
                onTap: () {
                  //Navigator.pop(context);

                  sendContactDetails(
                      nameController.text.trim(), phoneController.text.trim());
                },
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(left: b * 25),
                  height: h * 40,
                  width: 212 * b,
                  decoration: BoxDecoration(
                    color: mc,
                    borderRadius: BorderRadius.circular(b * 10),
                  ),
                  child: Text(
                    'Send',
                    style: txtS(Colors.white, 14, FontWeight.w500),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
      animationType: DialogTransitionType.slideFromBottomFade,
      curve: Curves.fastOutSlowIn,
      duration: Duration(milliseconds: 250),
    );
  }

  String giveTime(Timestamp? timestamp) {
    String time = "";
    if (timestamp != null) {
      DateTime d = timestamp.toDate();
      time = d.toString().substring(11, 16);
    }
    return time;
  }

  InputDecoration dec(String txt) {
    return InputDecoration(
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      hintText: txt,
      hintStyle: TextStyle(
        color: Color(0xffb9b9b9),
        fontSize: SizeConfig.screenWidth * 14 / 412,
        fontWeight: FontWeight.w400,
      ),
      isDense: true,
      contentPadding:
          EdgeInsets.symmetric(vertical: SizeConfig.screenHeight * 11 / 896),
    );
  }

  /*Future<void> sendNotification(String textMessage) async {
    FirebaseFunctions firebaseFunctions = FirebaseFunctions.instance;

    await firebaseFunctions.httpsCallable('sendNotification').call(
      <String, dynamic>{
        "recieverId": widget.receiverUid,
        "messageTxt": textMessage,
        "senderName": senderName
      },
    );
  }*/

  getDonationLocationInMaps() async {
    String url = "";
    double lat, lon;
    double originLat, originLon;

    if (await checkForLocationPermission()) {
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .then((position) {
        originLat = position.latitude;
        originLon = position.longitude;

        FirebaseFirestore.instance
            .collection('donations')
            .where('donatedTo', isEqualTo: widget.senderUID)
            .where('donorUID', isEqualTo: widget.receiverUid)
            .snapshots()
            .listen((snap) async {
          lat = snap.docs[0].data()['latitude'];
          lon = snap.docs[0].data()['longitude'];

          url = 'https://www.google.com/maps/dir/?api=1&' +
              'origin=' +
              originLat.toString() +
              ',' +
              originLon.toString() +
              "&destination=" +
              lat.toString() +
              ',' +
              lon.toString();

          if (await canLaunch(url)) {
            launch(url);
          } else
            throw "Could not launch $url";
        });

        print('Launching Maps');
      });
    } else
      print("Error in getting Location Permission");
  }

  Future<bool> checkForLocationPermission() async {
    loc.Location location = loc.Location();
    loc.PermissionStatus permissionStatus;
    bool permissionsOK = true;

    bool serviceEnabled = await location.serviceEnabled();

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Insufficient Permission"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
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
      return true;
    } else
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Insufficient Permission"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));

    return false;
  }

  donationAccepted() async {
    dialogBoxContact(context);
  }

  donationRejected() {
    FirebaseFirestore.instance
        .collection('donations')
        .where('donatedTo', isEqualTo: widget.senderUID)
        .where('donorUID', isEqualTo: widget.receiverUid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      String docId = snap.docs[0].id;

      FirebaseFirestore.instance.collection('donations').doc(docId).update({
        'isActive': false,
        'isRejected': true,
        'isAccept': false
      }).then((value) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) {
          return userTypeString == 'ind'
              ? HomeInd()
              : userTypeString == 'org'
                  ? HomeOrg()
                  : HomeNgo();
        }), (route) => false);
      });
    });
  }

  sendContactDetails(String name, String phone) {
    FirebaseFirestore.instance
        .collection('donations')
        .doc(donationUIDOnlyForNGOSide)
        .update({'isAccept': true}).then((value) {
      FirebaseFirestore.instance
          .collection('donorChats')
          .doc('lists')
          .collection(widget.senderUID ?? "")
          .doc(widget.receiverUid)
          .update({'isAccept': true}).then((value) {
        FirebaseFirestore.instance
            .collection('donorChats')
            .doc('lists')
            .collection(widget.receiverUid ?? '')
            .doc(widget.senderUID)
            .update({'isAccept': true}).then((value) {
          setState(() {
            acceptOrNot = true;
          });
        });
      });
    });

    print("Inside Send Contact Detail");
    Message message = Message(
        senderUid: widget.senderUID,
        receiverUid: widget.receiverUid,
        type: 'contactCard',
        pickUpPersonName: name,
        pickUpPersonContact: phone,
        timestamp: FieldValue.serverTimestamp());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          "Your Contact details has been shared. Kindly get back and had a conversation with donar."),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 5),
    ));

    addMessageToDb(message);
  }

  onPackageDelivered() async {
    FirebaseFirestore.instance
        .collection('donations')
        .doc(donationUIDOnlyForNGOSide)
        .update({'isDelivered': true});

    setState(() {
      isDelivered = true;
    });
    Navigator.of(context).pop();

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) {
        return userTypeString == 'ngo'
            ? HomeNgo()
            : userTypeString == 'org'
                ? HomeOrg()
                : HomeInd();
      }), (route) => false);
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.senderUID)
        .update({'packagesDelivered': FieldValue.increment(1)});

    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverUid)
        .update({
      'noOfDonation': FieldValue.increment(1),
      'points': FieldValue.increment(5)
    });
  }
}
