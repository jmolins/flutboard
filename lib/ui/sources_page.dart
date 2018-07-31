import 'package:flutter/material.dart';
import 'package:flutter_board/model/source.dart';
import 'package:flutter_board/service/article_bloc.dart';
import 'package:flutter_board/service/article_bloc_provider.dart';

class SourcesPage extends StatefulWidget {
  final ArticleBloc bloc;

  SourcesPage(this.bloc);

  @override
  State createState() => SourcesPageState();
}

class SourcesPageState extends State<SourcesPage> {
  List<Source> list;

  @override
  void initState() {
    super.initState();
    widget.bloc.getSources();
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Sources"),
          elevation: 0.0,
        ),
        body: StreamBuilder(
          stream: ArticleBlocProvider.of(context).allSources,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              return ListView.builder(
                itemBuilder: (context, index) => ListTile(
                      leading: Checkbox(value: false, onChanged: null),
                      title: Text(snapshot.data[index].name),
                    ),
                itemCount: snapshot.data.length,
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
