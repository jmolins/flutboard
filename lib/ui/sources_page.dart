import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutboard/model/source.dart';
import 'package:flutboard/service/article_bloc.dart';
import 'package:flutboard/service/article_bloc_provider.dart';

class SourcesPage extends StatefulWidget {
  // Setting the bloc as a field since we need it in State.initState().
  // It could be obtained in initState() using a PostFrameCallback.
  final ArticleBloc bloc;

  const SourcesPage({Key? key, required this.bloc}) : super(key: key);

  @override
  State createState() => SourcesPageState();
}

class SourcesPageState extends State<SourcesPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _checkedItemCount = 0;

  @override
  void initState() {
    super.initState();
    widget.bloc.getSources();
  }

  void onItemChanged(bool value) {
    value ? _checkedItemCount++ : _checkedItemCount--;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          return Future(() {
            if (_checkedItemCount == 0) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("No sources selected")));
              return false;
            }
            return true;
          });
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text("Sources"),
            elevation: 0.0,
            centerTitle: true,
          ),
          body: StreamBuilder(
            stream: ArticleBlocProvider.of(context).allSources,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active && snapshot.data != null) {
                var data = (snapshot.data as List<Source>).toList();
                return ListView.builder(
                  itemBuilder: (context, index) =>
                      SourceTile(data[index], widget.bloc, onItemChanged),
                  itemCount: data.length,
                );
              } else {
                return const Center(child: CircularProgressIndicator());
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

  const SourceTile(this.source, this.bloc, this.onChanged, {Key? key}) : super(key: key);

  @override
  _SourceTileState createState() => _SourceTileState();
}

class _SourceTileState extends State<SourceTile> {
  late bool checkboxValue;

  @override
  void initState() {
    super.initState();
    checkboxValue = widget.bloc.activeSources!.contains(widget.source.id);
    if (checkboxValue) widget.onChanged(checkboxValue);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: checkboxValue,
        onChanged: (bool? newValue) {
          setState(() {
            checkboxValue = newValue!;
            widget.onChanged(newValue);
            widget.bloc.activateSource(id: widget.source.id!, activate: newValue);
          });
        },
      ),
      title: Text(widget.source.name!),
    );
  }
}
