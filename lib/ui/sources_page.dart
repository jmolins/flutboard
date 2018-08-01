import 'package:flutter/material.dart';
import 'package:flutter_board/model/source.dart';
import 'package:flutter_board/service/article_bloc.dart';
import 'package:flutter_board/service/article_bloc_provider.dart';

class SourcesPage extends StatefulWidget {
  // Setting the bloc as a field since we need it in State.initState()
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
                itemBuilder: (context, index) =>
                    SourceTile(snapshot.data[index], widget.bloc),
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

class SourceTile extends StatefulWidget {
  final Source source;
  final ArticleBloc bloc;

  SourceTile(this.source, this.bloc);

  @override
  _SourceTileState createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  bool checkboxValue;

  @override
  void initState() {
    super.initState();
    checkboxValue = widget.bloc.activeSources.contains(widget.source.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: checkboxValue,
        onChanged: (bool newValue) {
          setState(() {
            checkboxValue = newValue;
            widget.bloc
                .activateSource(id: widget.source.id, activate: newValue);
          });
        },
      ),
      title: Text(widget.source.name),
    );
  }
}
