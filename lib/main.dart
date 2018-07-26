import 'package:flutter_board/my_flip_panel.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      title: 'FlipPanel',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {

  final digits = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FlipPanel.manual(
          itemBuilder: (context, index) => Container(
            color: Colors.black,
            height: MediaQuery.of(context).size.height - 24,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Text(
                '${index}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 400.0,
                    color: Colors.white),
              ),
            ),
          ),
          itemsCount: digits.length,
          loop: 1,
        ),
      ),
    );
  }
}
