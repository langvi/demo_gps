import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_location/data/location_model.dart';
import 'package:get_location/home_page.dart';
import 'package:validators/validators.dart';
import 'package:workmanager/workmanager.dart';

StreamController<String> serviceController = StreamController<String>();
Stream<String> get serviceStream => serviceController.stream;
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  // Workmanager().registerOneOffTask("send_location", "sendData");
  // Workmanager().registerPeriodicTask(uniqueName, taskName)
  runApp(const MyApp());
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    String sendingStatus = '';
    var url = inputData?['url'] ?? '';
    double lat = inputData?['lat'] ?? 0;
    double long = inputData?['long'] ?? 0;
    double accuracy = inputData?['accuracy'] ?? 0;
    sendingStatus = 'Bắt đầu gửi vị trí...';
    Response? res;
    try {
      res = await Dio().post(url, data: {
        'lat': lat,
        'lng': long,
        'accuracy': accuracy,
      });
    } catch (e) {}
    if (res != null && res.data != null) {
      sendingStatus = 'Gửi vị trí thành công';
    } else {
      sendingStatus = 'Gửi vị trí thất bại';
    }
    serviceController.sink.add(sendingStatus);
    return Future.value(true);
  });
}

void Function()? onExecuted;

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo get location',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Get location'),
      // home: HomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _urlController = TextEditingController();
  final _timeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String sendingStatus = '';
  String _url = 'https://zomee.one/eapp/public/api/v1/Tracker/addGps';
  LocationModel? locationModel;
  bool _isCancelSend = false;
  Timer? _timer;
  final dio = Dio()..options.connectTimeout = 10000;
  int timeWait = 5;
  bool isCallAPIDone = false;

  @override
  void initState() {
    // _urlController.text = 'addasds';
    _urlController.text = _url;
    initTimer();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: TextFormField(
            //     controller: _urlController,
            //     maxLines: 3,

            //     decoration: InputDecoration(
            //         hintText: 'Nhập url API',
            //         focusedBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(10),
            //             borderSide: BorderSide(color: Colors.blue)),
            //         enabledBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(10),
            //             borderSide: BorderSide(color: Colors.black))),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: Text(_urlController.text)),
                  IconButton(
                      onPressed: () {
                        showDialogEdit();
                      },
                      icon: Icon(Icons.edit))
                ],
              ),
            ),

            SizedBox(
              height: 10,
            ),
            StreamBuilder<String>(
                stream: serviceStream,
                builder: (context, snapshot) {
                  String sendingStatus = '';
                  if (snapshot.hasData) {
                    sendingStatus = snapshot.data ?? '';
                  }
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    alignment: Alignment.center,
                    child: Text(sendingStatus),
                  );
                }),
            Center(
              child: ElevatedButton(
                  onPressed: () {
                    showResult(
                        _isCancelSend
                            ? "Tiếp tục gửi vị trí..."
                            : "Huỷ việc gửi vị trí...", onCancel: () {
                      if (_isCancelSend) {
                        initTimer();
                      } else {
                        _timer?.cancel();
                      }
                      _isCancelSend = !_isCancelSend;
                      setState(() {});
                    });
                  },
                  child: Text(_isCancelSend ? "Tiếp tục" : "Tạm dừng")),
            )
          ],
        ),
      ),
    );
  }

  void initTimer() async {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: timeWait), (timer) async {
      locationModel = await getCurrentLocation();
      if (locationModel != null) {
        await Workmanager().cancelByUniqueName('send_location');
        Workmanager().registerOneOffTask(
          "send_location",
          "send_location",
          inputData: <String, dynamic>{
            'url': _url,
            'lat': locationModel!.lat,
            'long': locationModel!.long,
            'accuracy': locationModel!.accuracy,
          },
        );
      }

      // print("send location....");
      // print(_url);
      // print(timeWait);
      // if (isCallAPIDone) {
      //   await getLocation();
      // }
    });
  }

  Future<void> getLocation() async {
    locationModel = await getCurrentLocation();
    if (locationModel != null) {
      sendLocationToApi();
    }
    setState(() {});
  }

  void sendLocationToApi() async {
    if (isURL(_urlController.text)) {
      sendingStatus = 'Bắt đầu gửi vị trí...';
      isCallAPIDone = false;
      setState(() {});
      Response? res;
      try {
        res = await dio.post(_urlController.text, data: toJson());
      } catch (e) {
        print(e);
      }
      if (res != null && res.data != null) {
        sendingStatus = 'Gửi vị trí thành công';
      } else {
        sendingStatus = 'Gửi vị trí thất bại';
      }
      isCallAPIDone = true;
      locationModel = null;
      setState(() {});
    } else {
      sendingStatus = 'URL không hợp lệ';
      setState(() {});
      isCallAPIDone = true;
    }
  }

  void showResult(String message, {void Function()? onCancel}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(message),
            title: Text("Thông báo"),
            actions: onCancel == null
                ? null
                : [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Colors.grey),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Huỷ")),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: Colors.blue),
                        onPressed: () {
                          onCancel();
                          Navigator.pop(context);
                        },
                        child: Text("Xác nhận"))
                  ],
          );
        });
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': double.parse(locationModel!.lat.toStringAsFixed(5)),
      'lng': double.parse(locationModel!.long.toStringAsFixed(5)),
      'accuracy': locationModel!.accuracy,
    };
  }

  void showDialogEdit() async {
    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setStateDialog) {
            return Dialog(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _urlController,
                        maxLines: 3,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Url không hợp lệ';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            hintText: 'Nhập url API',
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.blue)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.black))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: TextFormField(
                        controller: _timeController,
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(5),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Thời gian nhập không hợp lệ';
                          } else if (int.parse(value) == 0) {
                            return 'Thời gian phải lớn hơn 0';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            hintText: 'Thời gian chờ...',
                            suffixText: 'giây',
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.blue)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.black))),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: Colors.grey),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("Huỷ")),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _url = _urlController.text;
                                      timeWait =
                                          int.parse(_timeController.text);
                                      initTimer();
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text("Cập nhật")))
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }));
        });
    setState(() {});
  }
}
