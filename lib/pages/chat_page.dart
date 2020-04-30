import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/core/const.dart';
import 'package:chatapp/pages/chat_item_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/core/flutter_icon.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;

  ChatPage({@required this.currentUserId});

  @override
  _ChatPageState createState() => _ChatPageState(currentUserId: currentUserId);
}

class _ChatPageState extends State<ChatPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final String currentUserId;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  SharedPreferences pref;
  bool isSwitched = false;

  _ChatPageState({@required this.currentUserId});

  void setStatus({bool isOnline}) {
    Firestore.instance
        .collection('users')
        .document(currentUserId)
        .updateData({'isOnline': isOnline});
  }

  void setLastSeen() {
    Firestore.instance
        .collection('users')
        .document(currentUserId)
        .updateData({'lastSeen': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus(isOnline: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      setStatus(isOnline: false);
      setLastSeen();
    } else if (state == AppLifecycleState.resumed) {
      setStatus(isOnline: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      appBar: AppBar(
        leading: new Container(),
        elevation: 0,
        backgroundColor: AppColors.mainColor,
        title: Text(
          "Chat",
          style: TextStyle(fontSize: 32, color: AppColors.textColor),
        ),
        actions: <Widget>[
          Switch(
            value: isSwitched,
            onChanged: (value) {
              setState(() {
                isSwitched = value;
                if (isSwitched) {
                  AppColors.mainColor = Colors.white;
                  AppColors.darkColor = Colors.white12;
                  AppColors.blueColor = Color(0XFF2c75fd);
                  AppColors.textColor = Colors.black;
                  AppColors.text2Color = Colors.grey;
                } else {
                  AppColors.mainColor = Color(0XFF252331);
                  AppColors.darkColor = Color(0XFF1e1c26);
                  AppColors.blueColor = Color(0XFF2c75fd);
                  AppColors.textColor = Colors.white;
                  AppColors.text2Color = Colors.white54;
                }
              });
            },
            activeTrackColor: Colors.lightGreenAccent,
            activeColor: Colors.green,
          ),
          IconButton(
              icon: Icon(
                FlutterIcons.filter,
                color: AppColors.blueColor,
              ),
              onPressed: () {})
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.darkColor,
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: TextField(
              style: TextStyle(color: AppColors.textColor),
              decoration: InputDecoration(
                  prefixIcon: Icon(
                    FlutterIcons.search,
                    color: AppColors.text2Color,
                  ),
                  hintText: "Search",
                  hintStyle: TextStyle(color: AppColors.text2Color)),
            ),
          ),
          _buildChat(context, this)
        ],
      ),
    );
  }

  Future<int> noOfUnreadMsg(String peerId) async {
    // int num;
    String finalPairId;
    if (currentUserId.hashCode <= peerId.hashCode) {
      finalPairId = '$currentUserId-$peerId';
    } else {
      finalPairId = '$peerId-$currentUserId';
    }

    var doc = await Firestore.instance
        .collection('messages')
        .document(finalPairId)
        .get();
    return doc.data['noOfUnreadMsg-$currentUserId'];
  }

  Widget _buildChat(BuildContext context, _ChatPageState _chatPageState) {
    return Expanded(
      child: Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            } else {
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  if (snapshot.data.documents[index]['id'] == currentUserId) {
                    return Container();
                  } else {
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatItemPage(
                              peerName: snapshot.data.documents[index]
                                  ['nickname'],
                              peerId: snapshot.data.documents[index].documentID,
                              peerAvatar: snapshot.data.documents[index]
                                  ['photoUrl'],
                              isOnline: snapshot.data.documents[index]
                                  ['isOnline'],
                              isTyping: snapshot.data.documents[index]
                                  ['isTyping'],
                              lastSeen: snapshot.data.documents[index]
                                  ['lastSeen'],
                            ),
                          ),
                        );
                      },
                      leading: Container(
                          width: 60,
                          height: 50,
                          child: Stack(
                            children: <Widget>[
                              Material(
                                child: snapshot.data.documents[index]
                                            ['photoUrl'] !=
                                        null
                                    ? CachedNetworkImage(
                                        placeholder: (context, url) =>
                                            Container(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.green),
                                          ),
                                          width: 50.0,
                                          height: 50.0,
                                          padding: EdgeInsets.all(15.0),
                                        ),
                                        imageUrl: snapshot.data.documents[index]
                                            ['photoUrl'],
                                        width: 50.0,
                                        height: 50.0,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.account_circle,
                                        size: 50.0,
                                        color: Colors.grey,
                                      ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                              Positioned(
                                bottom: 5,
                                left: 40,
                                child: snapshot.data.documents[index]
                                        ['isOnline']
                                    ? Stack(
                                        children: <Widget>[
                                          Container(
                                            height: 16,
                                            width: 16,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(100)),
                                                color: AppColors.mainColor),
                                          ),
                                          Positioned(
                                            top: 2,
                                            left: 2,
                                            child: Container(
                                              height: 12,
                                              width: 12,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(100)),
                                                color: Hexcolor(
                                                  '#5ab82c',
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    : Container(),
                              ),
                              Positioned(
                                  bottom: 32,
                                  left: 38,
                                  child: FutureBuilder(
                                      future: noOfUnreadMsg(
                                          snapshot.data.documents[index]['id']),
                                      builder: (context, sshot) {
                                        if (!sshot.hasData) {
                                          return Container();
                                        } else if (sshot.data <= 0) {
                                          return Container();
                                        } else {
                                          return Stack(
                                            children: <Widget>[
                                              Container(
                                                height: 16,
                                                width: 16,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(100)),
                                                  color: Colors.red,
                                                ),
                                              ),
                                              Container(
                                                child: Positioned(
                                                  top: 0,
                                                  left: 4,
                                                  child: Container(
                                                    height: 16,
                                                    width: 16,
                                                    child: Text(
                                                      '${sshot.data}',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'Montserrat'),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          );
                                        }
                                      }))
                            ],
                          )),
                      title: Text(
                        '${snapshot.data.documents[index]['nickname'] ?? 'Not available'}',
                        style: TextStyle(color: AppColors.textColor),
                      ),
                      subtitle: snapshot.data.documents[index]['isTyping']
                          ? Row(
                              children: <Widget>[
                                SpinKitThreeBounce(
                                    color: AppColors.blueColor,
                                    size: 20.0,
                                    controller: AnimationController(
                                        vsync: _chatPageState,
                                        duration: const Duration(
                                            milliseconds: 1200))),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  '${snapshot.data.documents[index]['aboutMe'] ?? 'Not available'}',
                                  style: TextStyle(
                                    color: AppColors.text2Color,
                                  ),
                                ),
                              ],
                            ),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}
