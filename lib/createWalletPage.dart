import 'package:ethereum_addresses/ethereum_addresses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:eip55/eip55.dart' as eip55;
import 'package:hex/hex.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart';

class createWalletPage extends StatefulWidget {
  const createWalletPage({Key? key}) : super(key: key);

  @override
  _CreateWalletPageState createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<createWalletPage> {
  final TextEditingController _mnemonicController = TextEditingController();
  final storage = FlutterSecureStorage();

  //고릴 테스트넷 잔액 조회 위함.
  final goerliEndPoint =
      "https://rpc.ankr.com/eth_goerli/9d90d371f709980dd40cdd275ac9b57cafb1014ac195e70618461c3e83b1b870";

  void generateMnemonic() {
    var mnemonic = bip39.generateMnemonic(strength: 128);
    setState(() {
      _mnemonicController.text = mnemonic;
    });
    showEthereumAddress(mnemonic);
  }

  void showEthereumAddress(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final childKey = root.derivePath("m/44'/60'/0'/0/0");

    final privateKeyHex = HEX.encode(childKey.privateKey!);
    final publicKeyHex = HEX.encode(childKey.publicKey);

    //새로운 방법
    final aa = HEX.decode(publicKeyHex);
    final aa1 = ethereumAddressFromPublicKey(Uint8List.fromList(aa));
    final aa2 = checksumEthereumAddress(aa1);

    print("공개키 1 : $aa");
    print("공개키 2 : $aa1");
    print("공개키 3 : $aa2");
    print("공개키 4 : ${isValidEthereumAddress(aa2)}");

    //공개키 20바이트 자르고 0x 붙이는 방법
    // final tt = keccak256(childKey.publicKey);
    // final tt1 = tt.sublist(tt.length - 20);
    // final tt2 = HEX.encode(tt1);
    // final ttPublicKey = '0x' + tt2;

    // print("공개키 : $publicKeyHex");
    // print("공개키 : ${publicKeyHex.length}");
    // print("공개키 1 : ${tt}");
    // print("공개키 1 : ${tt.length}");
    // print("공개키 2 : ${tt1}");
    // print("공개키 2 : ${tt1.length}");
    // print("공개키 3 : ${tt2}");
    // print("공개키 3 : ${tt2.length}");
    // print("공개키 주소 변환 : ${ttPublicKey}");
    // print("공개키 주소 길이 : ${ttPublicKey.length}");

    ////////////////////////////////////////////////////
    //공개키 64길이로 맞추기. 제일제일제일제일 중요~!!!
    // final publicKey = Uint8List(64);
    // publicKey.setAll(0, childKey.publicKey);
    ////////////////////////////////////////////////////

    //개인키
    // final privateKey = childKey.privateKey.toString();

    // final credentials = EthPrivateKey.fromHex(privateKeyHex);

    //공개키 이더리움 주소로 변환
    // final pKAddress = EthereumAddress.fromPublicKey(publicKey).toString();
    //이더리움 EIP-55 체크섬 주소로 변환
    // final publicKeyAddress = eip55.toChecksumAddress(pKAddress);

    // Get the Ethereum address using the updated method.
    // final address = await credentials.extractAddress();
    // final ethereumAddress = address.hexEip55;

    final wallet = {
      'name': '이더리움',
      'coinType': 'ETH',
      'symbol': 'ETH',
      'address': aa2
    };

    await saveWallet(wallet, privateKeyHex);

    /////////////////////////////////////
    await getBalance(aa2);
    /////////////////////////////////////
    ///
    ///
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('생성된 지갑 주소(공개키)'),
        content: Text(aa2),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Future<void> saveWallet(Map<String, String> wallet, String privateKey) async {
    try {
      // 기존 지갑 목록 정보 가져오기
      final walletsString = await storage.read(key: 'WALLETS');
      final wallets = (walletsString != null) ? json.decode(walletsString) : [];

      // 기존 지갑 목록에 추가하기
      wallets.add(wallet);

      // 기존 지갑 목록 정보 저장하기
      await storage.write(key: 'WALLETS', value: json.encode(wallets));

      // 개인키를 안전한 영역에 저장하기
      await storage.write(key: wallet['address']!, value: privateKey);

      // JSON 문자열로 저장된 지갑 목록을 디코딩하여 확인
      final list = await storage.read(key: 'WALLETS');
      final decodedWallets = json.decode(list ?? '[]');
    } catch (error) {
      // 데이터 저장 중 오류 발생
      print(error);
    }
  }

  Future<BigInt> getBalance(String publickey) async {
    final httpClient = Client();
    final ethClient = Web3Client(goerliEndPoint, httpClient);

    final address = EthereumAddress.fromHex(publickey);
    final balance = await ethClient.getBalance(address);
    print(balance.getInEther);
    return balance.getInEther;
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
        title: Text('지갑 생성하기', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          Text(
            '아래 12개의 니모닉을 복사하여 저장해두세요. 지갑을 복구하는데 매우 중요한 데이터입니다.(잃어버리면 복구할 수 없습니다.)',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: TextField(
              readOnly: true,
              controller: _mnemonicController,
              maxLines: null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                generateMnemonic();
              },
              child: Text('생성하기'),
            ),
          ),
        ]),
      ),
    );
  }
}
