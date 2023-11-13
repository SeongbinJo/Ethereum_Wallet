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

class withdrawCAM extends StatefulWidget {
  final String walletAddress;

  withdrawCAM({required this.walletAddress});

  @override
  State<withdrawCAM> createState() => _walletDetailPageState();
}

class _walletDetailPageState extends State<withdrawCAM> {
  final storage = FlutterSecureStorage();
  final goerliEndPoint =
      "https://rpc.ankr.com/eth_goerli/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";
  // final ethereumEndPoint = "https://rpc.ankr.com/eth/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";

  dynamic walletCAMT = "";
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
      double balance = double.parse(walletCAMT);
      return inputAmount > 0 && inputAmount <= balance; // 0 초과 조건 추가
    }
    return false;
  }

  Future<String> getCAMTBalance(String publickey) async {
    final httpClient = Client();
    final ethClient = Web3Client(goerliEndPoint, httpClient);
    final camtAbi = await rootBundle.loadString("assets/CAMTjson.json");
    final camtTokenAddress = "0x226c08905d91dB6fcC7E3901559F2741cDD33b55";

    final DeployedContract camtContract = DeployedContract(
        ContractAbi.fromJson(camtAbi, "CAMT"),
        EthereumAddress.fromHex(camtTokenAddress));
    final balanceFunction = camtContract.function('balanceOf');
    final address = EthereumAddress.fromHex(publickey);
    final balance = await ethClient.call(
        contract: camtContract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(publickey)]);

    final balanceValue = balance.first;
    print(balanceValue.runtimeType);
    return balanceValue.toString();
  }

  Future<void> fetchBalance() async {
    final balanceResult = await getCAMTBalance(widget.walletAddress);
    setState(() {
      walletCAMT = balanceResult;
    });
  }

  void startBalanceTimer() {
    balanceTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      fetchBalance();
    });
  }

  Future<void> sendCAMT() async {
    //개인키 가져오기
    final privateKey = await storage.read(key: widget.walletAddress);
    final ethClient = Web3Client(goerliEndPoint, Client());
    final credentials = await ethClient.credentialsFromPrivateKey(privateKey!);

    //CAMT 토큰 컨트랙트 정보
    final camtAbi = await rootBundle.loadString("assets/CAMTwithdraw.json");
    final camTAddress = "0x226c08905d91dB6fcC7E3901559F2741cDD33b55";
    final DeployedContract camtContract = DeployedContract(
        ContractAbi.fromJson(camtAbi, "CAMT"),
        EthereumAddress.fromHex(camTAddress));

    //전송할 주소, 금액
    final toAddress = EthereumAddress.fromHex(addressController.text);
    double amountDouble = double.parse(amountController.text);
    final amountGwei = amountDouble * 1000;
    final amountBigInt = BigInt.from(amountGwei.toInt());

    //가스
    final gas = await ethClient.getGasPrice();
    final weiGas = gas.getInWei.toInt();
    final gasReal = weiGas * 200000;
    final multipliedGasInEther =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, BigInt.from(gasReal));

    //CAMT 토큰의 transfer 함수 호출
    final transferFunction = camtContract.function('transfer');
    final transaction = Transaction.callContract(
        contract: camtContract,
        function: transferFunction,
        parameters: [toAddress, amountBigInt],
        gasPrice: multipliedGasInEther,
        maxGas: 210000);

    //트랜잭션 전송
    final sendTransaction =
        await ethClient.sendTransaction(credentials, transaction, chainId: 5);
    final signTransaction =
        await ethClient.signTransaction(credentials, transaction, chainId: 5);
    print("전송된 트랜잭션 : $sendTransaction");

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
        title: Text('CAMT 출금', style: TextStyle(color: Colors.black)),
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
                Text(
                  '보낼 금액',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '보낼 CAMT의 금액을 입력하세요.',
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
                      "잔액 : $walletCAMT CAMT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 70),
            Center(
              child: ElevatedButton(
                onPressed: isAddressValid && isAmountValid
                    ? () async {
                        sendCAMT();
                      }
                    : null,
                child: Text('출금'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange, width: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
