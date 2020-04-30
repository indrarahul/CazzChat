import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/core/const.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatItemPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final bool isOnline;
  final bool isTyping;
  final int lastSeen;

  ChatItemPage(
      {this.peerId,
      this.peerName,
      this.peerAvatar,
      this.isOnline,
      this.isTyping,
      this.lastSeen});

  @override
  _ChatItemPageState createState() => _ChatItemPageState(
      this.peerId,
      this.peerName,
      this.peerAvatar,
      this.isOnline,
      this.isTyping,
      this.lastSeen);
}

class _ChatItemPageState extends State<ChatItemPage>
    with TickerProviderStateMixin {
  final String peerId;
  final String peerName;
  final String peerAvatar;
  bool isOnline;
  final bool isTyping;
  int lastSeen;
  SharedPreferences pref;

  _ChatItemPageState(this.peerId, this.peerName, this.peerAvatar, this.isOnline,
      this.isTyping, this.lastSeen);

  String id;
  String finalPairId;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    finalPairId = '';
    chattingPair();
  }

  void onFocusChange() {
    if (textEditingController.text != "") {
      print("donedeo");
    }
  }

  updateUnreadMsg() async {
    int noOfUnreadMsg1;
    var doc1 = await Firestore.instance
        .collection('messages')
        .document(finalPairId)
        .get();

    noOfUnreadMsg1 = doc1.data['noOfUnreadMsg-$peerId'];
    int noOfUnreadMsg = noOfUnreadMsg1 + 1;

    await Firestore.instance
        .collection('messages')
        .document(finalPairId)
        .updateData({'noOfUnreadMsg-$peerId': noOfUnreadMsg});
  }

  chattingPair() async {
    pref = await SharedPreferences.getInstance();
    id = pref.getString('id') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      finalPairId = '$id-$peerId';
    } else {
      finalPairId = '$peerId-$id';
    }

    Firestore.instance
        .collection('users')
        .document(id)
        .updateData({'chattingWith': peerId});

    Firestore.instance
        .collection('messages')
        .document(finalPairId)
        .updateData({'noOfUnreadMsg-$id': 0});

    var document =
        await Firestore.instance.collection('users').document(peerId).get();

    isOnline = document.data['isOnline'];
    lastSeen = document.data['lastSeen'];

    setState(() {});
  }

  void onSendMessage(String content) {
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(finalPairId)
          .collection(finalPairId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'content': content,
            'type': 0
          },
        );
      });

      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      updateUnreadMsg();
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: <Widget>[
            Text('${peerName ?? 'Not available'}',style: TextStyle( color: AppColors.textColor),),
            SizedBox(
              height: 5,
            ),
            Text(
              isOnline
                  ? "online"
                  : "last seen today at " +
                      DateFormat.jm()
                          .format(DateTime.fromMillisecondsSinceEpoch(lastSeen))
                          .toString(),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text2Color,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.blueColor,
            ),
            onPressed: () {
              Firestore.instance
                  .collection('users')
                  .document(id)
                  .updateData({'chattingWith': null});
              Navigator.of(context).pop();
            }),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.menu, color: AppColors.blueColor),
              onPressed: null)
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
                stream: Firestore.instance
                    .collection('messages')
                    .document(finalPairId)
                    .collection(finalPairId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  } else {
                    return ListView.builder(
                        controller: listScrollController,
                        itemCount: snapshot.data.documents.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            child: Row(
                              mainAxisAlignment: snapshot.data.documents[index]
                                          ['idFrom'] !=
                                      peerId
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: <Widget>[
                                _isFirstMessage(
                                            snapshot.data.documents, index) &&
                                        snapshot.data.documents[index]
                                                ['idFrom'] ==
                                            peerId
                                    ? Container(
                                        width: 35,
                                        height: 35,
                                        child: Stack(
                                          children: <Widget>[
                                            Material(
                                              child: peerAvatar != null
                                                  ? CachedNetworkImage(
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 1.0,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.green),
                                                        ),
                                                        width: 50.0,
                                                        height: 50.0,
                                                        padding: EdgeInsets.all(
                                                            15.0),
                                                      ),
                                                      imageUrl: peerAvatar,
                                                      width: 50.0,
                                                      height: 50.0,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Icon(
                                                      Icons.account_circle,
                                                      size: 50.0,
                                                      color: Colors.grey,
                                                    ),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(25.0)),
                                              clipBehavior: Clip.hardEdge,
                                            ),
                                            Positioned(
                                              bottom: 2,
                                              left: 29,
                                              child: isOnline
                                                  ? Stack(
                                                      children: <Widget>[
                                                        Container(
                                                          height: 7,
                                                          width: 7,
                                                          decoration: BoxDecoration(
                                                              borderRadius: BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          100)),
                                                              color: AppColors
                                                                  .mainColor),
                                                        ),
                                                        Positioned(
                                                          top: 0,
                                                          left: 0,
                                                          child: Container(
                                                            height: 6,
                                                            width: 6,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius: BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          100)),
                                                              color: Hexcolor(
                                                                '#5ab82c',
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  : Container(),
                                            )
                                          ],
                                        ),
                                      )
                                    : Container(
                                        width: 30,
                                        height: 30,
                                      ),
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                  margin: EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(_isFirstMessage(
                                              snapshot.data.documents, index)
                                          ? 0
                                          : 10),
                                      topRight: Radius.circular(10),
                                      bottomLeft: Radius.circular(
                                          _isLastMessage(
                                                  snapshot.data.documents,
                                                  index)
                                              ? 0
                                              : 10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    color: snapshot.data.documents[index]
                                                ['idFrom'] !=
                                            peerId
                                        ? AppColors.blueColor
                                        : AppColors.text2Color,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Text(
                                        snapshot.data.documents[index]
                                            ['content'],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        DateFormat.jm()
                                            .format(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    snapshot.data
                                                            .documents[index]
                                                        ['timestamp']))
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  }
                }),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SpinKitThreeBounce(
                          color: AppColors.blueColor,
                          size: 20.0,
                          controller: AnimationController(
                              vsync: this,
                              duration: const Duration(milliseconds: 1200))),
                    ],
                  ),
                  Text(
                    "$peerName is typing..",
                    style: TextStyle(
                      color: Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: AppColors.darkColor,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Row(
          children: <Widget>[
            Flexible(
                child: TextField(
              style: TextStyle(color: AppColors.textColor),
              focusNode: focusNode,
              controller: textEditingController,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type Something...",
                  hintStyle: TextStyle(
                    color: AppColors.text2Color,
                  )),
            )),
            IconButton(
                icon: Icon(Icons.send, color: AppColors.blueColor),
                onPressed: () => onSendMessage(textEditingController.text)),
            IconButton(
                icon: Icon(FontAwesomeIcons.smile, color: AppColors.blueColor),
                onPressed: null)
          ],
        ));
  }
}

_isFirstMessage(documents, int index) {
  return (documents[index]['idFrom'] !=
          documents[index - 1 < 0 ? 0 : index - 1]['idFrom']) ||
      index == 0;
}

_isLastMessage(documents, int index) {
  int maxItem = documents.length - 1;
  return (documents[index]['idFrom'] !=
          documents[index + 1 > maxItem ? maxItem : index + 1]['idFrom']) ||
      index == maxItem;
}
