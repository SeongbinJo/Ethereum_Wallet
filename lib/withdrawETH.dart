import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class withdrawETH extends StatefulWidget {
  final String walletAddress;

  withdrawETH({required this.walletAddress});

  @override
  State<withdrawETH> createState() => _walletDetailPageState();
}

class _walletDetailPageState extends State<withdrawETH> {
  final storage = FlutterSecureStorage();
  final goerliEndPoint =
      "https://rpc.ankr.com/eth_goerli/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";
  // final ethereumEndPoint = "https://rpc.ankr.com/eth/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";

  dynamic walletETH = "";
  late Timer balanceTimer;

  double gasValue = 0.0;

  bool isAddressValid = false;
  bool isAmountValid = false;

  //주소 유효성 관련 변수
  final addressController = TextEditingController();
  String addressValidationText = '';
  Color addressValidationColor = Colors.red;

  //금액 유효성 관련 변수
  final amountController = TextEditingController();
  String amountValidationText = '';
  Color amountValidationColor = Colors.red;

  @override
  void initState() {
    super.initState();
    fetchBalance();
    startBalanceTimer();

    addressController.addListener(() {
      isAddressValid = checkAddress(addressController.text);

      if (isAddressValid) {
        setState(() {
          addressValidationText = '올바른 주소입니다.';
          addressValidationColor = Colors.blue;
        });
      } else {
        setState(() {
          addressValidationText = '주소가 잘못되었습니다.';
          addressValidationColor = Colors.red;
        });
      }
    });

    amountController.addListener(() {
      isAmountValid = checkAmount(amountController.text);

      if (isAmountValid) {
        setState(() {
          amountValidationText = '';
        });
      } else {
        setState(() {
          amountValidationText = '올바른 숫자를 입력해주세요.';
          amountValidationColor = Colors.red;
        });
      }
    });
  }

  @override
  void dispose() {
    addressController.dispose();
    amountController.dispose();
    balanceTimer.cancel();
    super.dispose();
  }

  bool checkAddress(String address) {
    final pattern = RegExp(r'^(0x)?[0-9a-f]{40}$', caseSensitive: false);
    return pattern.hasMatch(address);
  }

  bool checkAmount(String amount) {
    final pattern = RegExp(r'^\d+\.?\d*$');
    bool isNumeric = pattern.hasMatch(amount) && !amount.startsWith('.');
    if (isNumeric) {
      double inputAmount = double.parse(amount);
      double balance = double.parse(walletETH);
      return inputAmount > 0 && inputAmount <= balance; // 0 초과 조건 추가
    }
    return false;
  }

  Future<String> getBalance(String publickey) async {
    final httpClient = Client();
    final ethClient = Web3Client(goerliEndPoint, httpClient);

    final address = EthereumAddress.fromHex(publickey);
    final balance = await ethClient.getBalance(address);
    print(balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(3));
    return balance.getValueInUnit(EtherUnit.ether).toStringAsFixed(3);
  }

  Future<void> fetchBalance() async {
    final balanceResult = await getBalance(widget.walletAddress);
    setState(() {
      walletETH = balanceResult;
    });
  }

  void startBalanceTimer() {
    balanceTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      fetchBalance();
    });
  }

  Future<void> sendETH() async {
    // 개인키 가져오기
    final privateKey = await storage.read(key: widget.walletAddress);
    final ethClient = Web3Client(goerliEndPoint, Client());
    final credentials = await ethClient.credentialsFromPrivateKey(privateKey!);
    final address = await credentials.extractAddress();
    final gas = await ethClient.getGasPrice();
    final weiGas = gas.getInWei;
    final num = weiGas.toInt() * 1000000000;
    final gweiGas =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(num));

    //입력받은 금액 wei단위 수정 ex) 0.01 ETH 입력 -> 0.01 * 1000000000 * 1000000000
    double amountDouble = double.parse(amountController.text);
    final toGwei = amountDouble * 1000000000;
    final toEth = toGwei * 1000000000;
    BigInt amountBigInt = BigInt.from(toEth.toInt());

    Transaction transaction = Transaction(
      to: EthereumAddress.fromHex(addressController.text),
      gasPrice: gas,
      maxGas: 21000,
      value: EtherAmount.fromUnitAndValue(EtherUnit.wei, amountBigInt),
    );

    //거래 트랜잭션 전송
    final sendTransaction =
        await ethClient.sendTransaction(credentials, transaction, chainId: 5);
    //트랜잭션 서명
    final signTransaction =
        await ethClient.signTransaction(credentials, transaction, chainId: 5);
    //거래 트랜잭션 주소 출력
    print('sendTransaction : $sendTransaction');
    print('signTransaction : $signTransaction');
    await ethClient.dispose();
  }

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
        title: Text('ETH 출금', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보낼 대상',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addressController,
                          decoration: InputDecoration(
                            hintText: '보낼 대상의 이더리움 주소를 입력하세요.',
                            hintStyle: TextStyle(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code),
                        onPressed: () {
                          // QR 코드 스캔 로직
                        },
                      ),
                    ],
                  ),
                ),
                if (addressValidationText.isNotEmpty)
                  Text(
                    addressValidationText,
                    style: TextStyle(color: addressValidationColor),
                  ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '보낼 이더리움의 금액을 입력하세요.',
                  ),
                ),
                if (amountValidationText.isNotEmpty)
                  Text(
                    amountValidationText,
                    style: TextStyle(color: amountValidationColor),
                  ),
                Row(
                  children: [
                    Text(
                      "잔액 : $walletETH ETH",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 70),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  sendETH();
                  final pvAD = await storage.read(key: widget.walletAddress);
                  if (pvAD != null) {
                    // print(pvAD.length);
                    // final tet = privateKeyBytesToPublic(hexToBytes(
                    //     '1f4f0f2d42396ca654bb66ed2c5816a9c3eff8e76dee738ebf0fa71eada0e589'));
                    // final test = priva
                    // print(tet);
                    // print(test);
                    // final publictet =
                    //     '02960e1510b08682595c600ec601466125f2e1d67836ee428801f4122332e57002';
                    // final publctet2 = publictet.sli
                    // print(test);
                    // final pbAD1 = EthereumAddress.fromHex(pvAD);
                    // print("개인키 -> 주소 : ${pbAD1.hexEip55}");
                  }
                },
                child: Text('출금'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange, width: 1.0)),
              ),
              // child: ElevatedButton(
              //   onPressed: isAddressValid && isAmountValid
              //       ? () async {
              //           sendETH();
              //         }
              //       : null,
              //   child: Text('출금'),
              //   style: ElevatedButton.styleFrom(
              //       minimumSize: Size(200, 50),
              //       backgroundColor: Colors.white,
              //       foregroundColor: Colors.orange,
              //       side: BorderSide(color: Colors.orange, width: 1.0)),
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
