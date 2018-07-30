import 'package:flutter/material.dart';

class SourcesPage extends StatefulWidget {
  @override
  State createState() => SourcesPageState();
}

class SourcesPageState extends State<SourcesPage> {
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Sources"),
          elevation: 0.0,
        ),
        body: ListView.builder(
          itemBuilder: (context, index) => ListTile(
                leading: Checkbox(value: false, onChanged: null),
                title: Text("News source"),
              ),
          itemCount: 50,
        ),
      ),
    );
  }
}
