import 'package:bip39/bip39.dart';
import 'package:ethereum_wallet/createWalletPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'walletCard.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: mainPage(),
    );
  }
}

class mainPage extends StatefulWidget {
  const mainPage({Key? key}) : super(key: key);

  @override
  State<mainPage> createState() => _mainPageState();
}

class _mainPageState extends State<mainPage> {
  final storage = FlutterSecureStorage(); //지갑의 정보를 저장하기 위한 로컬 저장소.
  List<dynamic> walletList = []; //지갑의 정보를 담아두기 위한 변수 선언
  List<dynamic> walletalllist = [];

  //flutter_secure_storage 사용을 위한 초기화 작업
  @override
  void initState() {
    super.initState();
    getWalletData();
  }

  getWalletData() async {
    final walletsDataString = await storage.read(key: 'WALLETS');
    if (walletsDataString != null) {
      setState(() {
        final parsedJson = json.decode(walletsDataString ?? '[]');
        walletList = parsedJson;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            'Ethereum Wallet',
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: ListView.builder(
          itemCount: walletList.length + 1, // 추가한 1은 '지갑 생성' card를 위한 것
          itemBuilder: (BuildContext context, int index) {
            if (index == walletList.length) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: Card(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const createWalletPage()),
                        );
                        getWalletData();
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 50),
                            Text(
                              '지갑 생성',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return walletCard(
                wallets: walletList,
                index: index,
                fucn1: getWalletData(),
                // onPopFunction: getWalletData(),
              );
            }
          },
        ),
      ),
    );
  }
}
