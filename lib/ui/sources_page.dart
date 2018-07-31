import 'package:flutter/material.dart';
import 'package:flutter_board/service/article_bloc.dart';
import 'package:flutter_board/service/article_bloc_provider.dart';

class SourcesPage extends StatefulWidget {
  final ArticleBloc bloc;

  SourcesPage(this.bloc);

  @override
  State createState() => SourcesPageState();
}

class SourcesPageState extends State<SourcesPage> {
  @override
  void initState() {
    super.initState();
    widget.bloc.getSources();
  }

  bool isActive(String sourceId) {
    return widget.bloc.activeSourcesList.contains(sourceId);
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Sources"),
          elevation: 0.0,
          centerTitle: true,
        ),
        body: StreamBuilder(
          stream: ArticleBlocProvider.of(context).allSources,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active &&
                snapshot.data != null) {
              return ListView.builder(
                itemBuilder: (context, index) => ListTile(
                      leading: Checkbox(
                        value: isActive(snapshot.data[index].id),
                        onChanged: null,
                      ),
                      title: Text(snapshot.data[index].name),
                    ),
                itemCount: snapshot.data.length,
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
