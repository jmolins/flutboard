import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutboard/model/source.dart';
import 'package:flutboard/service/article_bloc.dart';
import 'package:flutboard/service/article_bloc_provider.dart';

class SourcesPage extends StatefulWidget {
  // Setting the bloc as a field since we need it in State.initState().
  // It could be obtained in initState() using a PostFrameCallback.
  final ArticleBloc bloc;

  SourcesPage(this.bloc);

  @override
  State createState() => SourcesPageState();
}

class SourcesPageState extends State<SourcesPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  int _checkedItemCount = 0;

  @override
  void initState() {
    super.initState();
    widget.bloc.getSources();
  }

  void onItemChanged(bool value) {
    value ? _checkedItemCount++ : _checkedItemCount--;
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          return new Future(() {
            if (_checkedItemCount == 0) {
              _scaffoldKey.currentState
                  .showSnackBar(SnackBar(content: Text("No sources selected")));
              return false;
            }
            return true;
          });
        },
        child: Scaffold(
          key: _scaffoldKey,
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
                  itemBuilder: (context, index) => SourceTile(
                      snapshot.data[index], widget.bloc, onItemChanged),
                  itemCount: snapshot.data.length,
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}

class SourceTile extends StatefulWidget {
  final Source source;
  final ArticleBloc bloc;
  final ValueChanged<bool> onChanged;

  SourceTile(this.source, this.bloc, this.onChanged);

  @override
  _SourceTileState createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  bool checkboxValue;

  @override
  void initState() {
    super.initState();
    checkboxValue = widget.bloc.activeSources.contains(widget.source.id);
    if (checkboxValue) widget.onChanged(checkboxValue);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: checkboxValue,
        onChanged: (bool newValue) {
          setState(() {
            checkboxValue = newValue;
            widget.onChanged(newValue);
            widget.bloc
                .activateSource(id: widget.source.id, activate: newValue);
          });
        },
      ),
      title: Text(widget.source.name),
    );
  }
}
