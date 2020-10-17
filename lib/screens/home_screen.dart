import 'dart:convert';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ticket_checker_app/classes/User.dart';
import 'package:ticket_checker_app/classes/UserDetails.dart';
import 'package:ticket_checker_app/components/CustomDrawer.dart';
import 'package:http/http.dart' as http;
import 'package:ticket_checker_app/components/ModalProgressHud.dart';

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  final User manager;

  const HomeScreen({Key key, this.manager}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String errorText = "Something wrong";
  bool error = false;
  User manager;
  String result = "";
  UserDetails userDetails;
  bool isLoaded = false;
  bool processing = false;
  double fineAmount;
  String url = "http://192.168.8.101:8000/api/auth/me/";
  DateTime loadedDate = DateTime.now();
  loadUserDetails(userID) async {
    setState(() {
      processing = true;
    });
    print("load");
    final http.Response response =
        await http.get(url + userID, headers: <String, String>{
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      // print(jsonDecode(response.body)['journeyHistory']);
      userDetails = await userDetailsFromJson(jsonDecode(response.body));
      print(userDetails.travelHistory.length);
      setState(() {
        loadedDate = DateTime.now();
        isLoaded = true;
      });
    }
    setState(() {
      processing = false;
    });
  }

  Future _scanQR() async {
    try {
      var qrResult = await BarcodeScanner.scan();

      if (qrResult.type.toString() != 'Cancelled') {
        await loadUserDetails(qrResult.toString());
      } else {
        print("No data");
      }

      setState(() {
        result = qrResult.rawContent;
      });
    } catch (e) {
      print(e);
      setState(() {
        result = "error $e";
      });
    }
  }

  assignFine(amount) async {
    try {
      http.Response response = await http.post(
          'http://192.168.8.101:8000/api/fine/add-fine',
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            "managerId": manager.userId,
            "passengerId": userDetails.userId,
            "amount": amount
          }));
      print(response.statusCode);
    } catch (err) {}
  }

  FocusNode newFocusNode = new FocusNode();
  @override
  void initState() {
    manager = widget.manager;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return ModalProgressHUD(
      inAsyncCall: processing,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Check mate"),
          actions: [
            Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      loadedDate = DateTime.now();
                      userDetails = null;
                    });
                  },
                  child: Icon(
                    Icons.restore,
                    size: 26.0,
                  ),
                )),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            newFocusNode.unfocus();
          },
          child: Container(
            height: height,
            child: userDetails == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        height: (height / 10) * 1,
                        child: Row(
                          children: [
                            Text(
                              "Welcome ",
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              "${manager.name.toUpperCase()}",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            Spacer(),
                            Column(
                              children: [
                                Text('Last scanned'),
                                Text("${DateFormat.jms().format(loadedDate)}"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: (height / 10) * 6,
                        child: Center(
                          child: Image(
                            image: AssetImage('images/no-data.png'),
                          ),
                        ),
                      ),
                      Container(
                        height: (height / 10) * 2,
                        child: Column(
                          children: [
                            Text(
                              'Welcome ${widget.manager.name}',
                              style: TextStyle(fontSize: 25),
                            ),
                            Text(
                              'No user scanned yet',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: (height / 10) * 1,
                        child: Card(
                          color: Color(0x990B2512),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  "Welcome ",
                                  style: TextStyle(fontSize: 18),
                                ),
                                Text(
                                  "${manager.name.toUpperCase()}",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                Spacer(),
                                Column(
                                  children: [
                                    Text('Last scanned'),
                                    Text(
                                        "${DateFormat.jms().format(loadedDate)}"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: (height / 10) * 2,
                        child: Card(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 20.0, left: 20, right: 20),
                                child: TextField(
                                    autofocus: false,
                                    focusNode: newFocusNode,
                                    onChanged: (v) {
                                      setState(() {
                                        fineAmount = double.parse(v);
                                      });
                                    },
                                    decoration: InputDecoration(
                                      errorText: error ? errorText : null,
                                      prefixIcon: Icon(
                                        Icons.attach_money,
                                        color: Colors.blue,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.blue, width: 2)),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1)),
                                      border: OutlineInputBorder(),
                                      labelText: "Fine Amount",
                                      hintStyle: TextStyle(
                                        color: Colors.blue[400],
                                      ),
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    RaisedButton(
                                      onPressed: () async {
                                        if (fineAmount > 0) {
                                          await assignFine(fineAmount);
                                        }
                                      },
                                      color: Colors.blue,
                                      child: Text("Assign Fine"),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: (height / 10) * 6,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Person Name:"),
                                        Text(
                                          userDetails.name,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Spacer(),
                                    Chip(
                                      elevation: 4,
                                      avatar: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.perm_identity,
                                          color: Colors.green,
                                        ),
                                      ),
                                      backgroundColor: Colors.blue,
                                      label: Text(
                                        '${userDetails.nic}',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      width: width / 2.2,
                                      child: Card(
                                        color: Colors.black45,
                                        child: Padding(
                                          padding: const EdgeInsets.all(18.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Available balance",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        userDetails.balance > 0
                                                            ? Colors.white
                                                            : Colors.red),
                                              ),
                                              Text(
                                                '${userDetails.balance}',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color:
                                                        userDetails.balance > 0
                                                            ? Colors.white
                                                            : Colors.red),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: width / 2.2,
                                      child: Card(
                                        color: Colors.black45,
                                        child: Padding(
                                          padding: const EdgeInsets.all(18.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Fine balance",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: userDetails
                                                                .fineBalance >
                                                            0
                                                        ? Colors.red
                                                        : Colors.white),
                                              ),
                                              Text(
                                                '${userDetails.fineBalance}',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: userDetails
                                                                .fineBalance >
                                                            0
                                                        ? Colors.red
                                                        : Colors.white),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.all(4),
                                  width: width,
                                  child: Card(
                                    color: Colors.black45,
                                    child: userDetails.ongoing
                                        ? Row(
                                            children: [
                                              Text("Starting from : ")
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'NO ONGOING JOURNEY FOUND',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )
                                            ],
                                          ),
                                  ),
                                  height: height / 10,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          // onPressed: _scanQR,
          //todo remove above comment
          onPressed: () async {
            await loadUserDetails("5f8681a637df4c60c4e59203");
          },
          label: Text(
            "Scan user",
            style: TextStyle(fontSize: 16),
          ),
          icon: Icon(Icons.camera_enhance),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        drawer: CustomDrawer(
          user: widget.manager,
        ),
      ),
    );
  }
}