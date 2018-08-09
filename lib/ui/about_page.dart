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
        body: ListView(
          children: <Widget>[
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: Text(
                  "FlutBoard",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 40.0),
                child: SizedBox(
                  height: 100.0,
                  width: 100.0,
                  child: Image.asset("assets/images/flutboard_logo.png"),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 15.0),
                child: Text(
                  "Proudly made with Flutter",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 10.00),
                child: Text(
                  "by Chema Molins",
                  style: TextStyle(fontSize: 14.0),
                ),
              ),
            ),
            Center(
              child: Text(
                "@jmolins",
                style: TextStyle(fontSize: 14.0),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 25.00, bottom: 5.0),
                child: Text(
                  "Report any issues to:",
                  style: TextStyle(fontSize: 14.0),
                ),
              ),
            ),
            Center(
              child: Text(
                "https://github.com/jmolins/flutboard",
                style: TextStyle(fontSize: 14.0),
              ),
            ),
            Center(
              child: Padding(
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
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: GestureDetector(
                  onTap: _launchNewsApiURL,
                  child: Text(
                    "Disclaimer: FlutBoard is based on the idea developed by FlipBoard of browsing news "
                        "by flipping through pages. The app has been built with an educational "
                        "purpose using the Flutter cross platform SDK from Google. "
                        "Its full source code can be found at: 'https://github.com/jmolins/flutboard'.",
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
