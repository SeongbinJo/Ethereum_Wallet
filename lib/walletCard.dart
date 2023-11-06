import 'dart:async';
import 'package:ethereum_wallet/walletDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class walletCard extends StatefulWidget {
  final List<dynamic> wallets;
  final int index;

  walletCard({required this.wallets, required this.index});

  @override
  State<walletCard> createState() => _walletCardState();
}

class _walletCardState extends State<walletCard> {
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //고릴 테스트넷 잔액조회 & 20초마다 업데이트//////////////////////////////////////////////////////////////////
  final goerliEndPoint =
      "https://rpc.ankr.com/eth_goerli/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";

  dynamic walletETH = "";

  late Timer balanceTimer;

  Future<String> getBalance(String publickey) async {
    final httpClient = Client();
    final ethClient = Web3Client(goerliEndPoint, httpClient);

    final address = EthereumAddress.fromHex(publickey);
    final balance = await ethClient.getBalance(address);
    print("여기 보세요 ㅎㅎㅅㅂ");
    print(balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(3));
    return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(3);
  }

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

  Future<void> fetchBalance() async {
    final balanceResult =
        await getBalance(widget.wallets[widget.index]['address']);
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
    final wallet = widget.wallets[widget.index];
    dynamic symbolImage = Image.asset(
      'image/ethereum.png',
      width: 25,
      height: 25,
    );
    print(wallet['symbol']);
    print(wallet.runtimeType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
      child: Container(
        // margin: EdgeInsets.only(top: 20), // AppBar와의 간격 조정
        width: MediaQuery.of(context).size.width * 0.9, // 배경화면의 90%
        height: MediaQuery.of(context).size.height * 0.2, // 세로 : 200
        child: Card(
          color: Colors.white,
          child: InkWell(
            onTap: () async {
              print(
                  "현재 클릭한 지갑의 정보 : [지갑 이름 : ${wallet['name']}, 블록체인 : ${wallet['coinType']}, 주소 : ${wallet['address']}");
              print(
                  "해당 주소(${wallet['address']}의 Goerli 잔액은 : ${await getBalance(wallet['address'])} ETH 입니다.");
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          walletDetailPage(walletData: wallet)));
            }, // 버튼 기능을 넣어줄 수 있습니다.
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("지갑 이름 : ${wallet['name']}"),
                    Row(
                      children: [
                        Text("블록체인 : ${wallet['coinType']}"),
                        symbolImage
                      ],
                    ),
                    Text("잔액 : $walletETH ETH"),
                    Text("주소 : ${wallet['address']}"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
