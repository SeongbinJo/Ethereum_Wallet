import 'package:ethereum_wallet/depositETH.dart';
import 'package:ethereum_wallet/withdrawETH.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:async';

class walletDetailPage extends StatefulWidget {
  final Map<String, dynamic> walletData;

  walletDetailPage({required this.walletData});

  @override
  State<walletDetailPage> createState() => _walletDetailPageState();
}

class _walletDetailPageState extends State<walletDetailPage> {
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //고릴 테스트넷 잔액조회 & 20초마다 업데이트//////////////////////////////////////////////////////////////////
  final goerliEndPoint =
      "https://rpc.ankr.com/eth_goerli/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";

  dynamic walletETH = "";
  late Timer balanceTimer;

  @override
  void initState() {
    super.initState();
    fetchBalance();
    startBalanceTimer();
  }

  @override
  void dispose() {
    balanceTimer.cancel();
    super.dispose();
  }

  Future<String> getBalance(String publickey) async {
    final httpClient = Client();
    final ethClient = Web3Client(goerliEndPoint, httpClient);

    final address = EthereumAddress.fromHex(publickey);
    final balance = await ethClient.getBalance(address);
    print("여기 보세요 ㅎㅎㅅㅂ");
    print(balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(3));
    return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(3);
  }

  Future<void> fetchBalance() async {
    final balanceResult = await getBalance(widget.walletData['address']);
    setState(() {
      walletETH = balanceResult;
    });
  }

  void startBalanceTimer() {
    balanceTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      fetchBalance();
    });
  }
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //고릴 테스트넷 잔액조회 & 20초마다 업데이트//////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(widget.walletData['name'],
            style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(50.0),
              child: SizedBox(
                width: 70,
                height: 70,
                child: Image.asset('image/ethereum.png'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "$walletETH ETH",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "≈ ￦ 0.00",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                widget.walletData['address'],
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => depositETH(
                                    walletAddress:
                                        widget.walletData['address'])));
                      },
                      child: Text('입금'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(130, 50),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue, width: 1.0)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => withdrawETH(
                                    walletAddress:
                                        widget.walletData['address'])));
                      },
                      child: Text('출금'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(130, 50),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          side: BorderSide(color: Colors.orange, width: 1.0)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
