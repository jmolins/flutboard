import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef void FlipBack({bool backToTop});

class AboutPage extends StatelessWidget {
  static const String NEWSAPI_URL = "https://newsapi.org";

  AboutPage();

  _launchNewsApiURL() async {
    if (await canLaunch(NEWSAPI_URL)) {
      await launch(NEWSAPI_URL);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(5.0),
              child: Text(
                "FlutBoard",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 40.0),
              child: Center(
                child: SizedBox(
                  height: 100.0,
                  width: 100.0,
                  child: Image.asset("assets/images/flutboard_logo.png"),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 15.0),
              child: Text(
                "Proudly made with Flutter",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 10.00),
              child: Text(
                "by Chema Molins",
                style: TextStyle(fontSize: 14.0),
              ),
            ),
            Text(
              "@jmolins",
              style: TextStyle(fontSize: 14.0),
            ),
            Padding(
              padding: EdgeInsets.only(top: 25.00, bottom: 5.0),
              child: Text(
                "Report any issues to:",
                style: TextStyle(fontSize: 14.0),
              ),
            ),
            Text(
              "https://github.com/jmolins/flutboard",
              style: TextStyle(fontSize: 14.0),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30.0),
              child: GestureDetector(
                onTap: _launchNewsApiURL,
                child: Text(
                  "Powered by News API",
                  style: TextStyle(
                      fontSize: 14.0, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
