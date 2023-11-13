import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class depositETH extends StatefulWidget {
  final String walletAddress;

  depositETH({required this.walletAddress});

  @override
  State<depositETH> createState() => _walletDetailPageState();
}

class _walletDetailPageState extends State<depositETH> {
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
        title: Text('입금', style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Image.asset(
                'image/ethereum.png',
                width: 50,
                height: 50,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: QrImageView(
                data: widget.walletAddress,
                size: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Text(
                widget.walletAddress,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.walletAddress));
              },
              icon: Icon(Icons.copy),
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
