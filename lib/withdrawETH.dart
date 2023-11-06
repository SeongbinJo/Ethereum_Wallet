import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class withdrawETH extends StatefulWidget {
  final String walletAddress;

  withdrawETH({required this.walletAddress});

  @override
  State<withdrawETH> createState() => _walletDetailPageState();
}

class _walletDetailPageState extends State<withdrawETH> {
  double gasValue = 0.0;

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
                          decoration: InputDecoration(
                              hintText: '보낼 대상의 이더리움 주소를 입력하세요.',
                              hintStyle: TextStyle()),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.qr_code),
                        onPressed: () {
                          // QR 코드 스캔 로직을 추가하세요.
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '보낼 금액',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '보낼 이더리움의 금액을 입력하세요.',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가스 수수료'),
                SizedBox(height: 8),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Slider(
                    value: gasValue,
                    onChanged: (newValue) {
                      setState(() {
                        gasValue = newValue;
                      });
                    },
                    min: 0.0,
                    max: 100.0, // 가스 수수료의 최대 값에 따라 조정하세요.
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Slow', style: TextStyle(color: Colors.grey)),
                    Text('Fastest', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
