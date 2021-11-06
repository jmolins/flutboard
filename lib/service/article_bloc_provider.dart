import 'package:flutter/material.dart';
import 'package:flutboard/service/article_bloc.dart';

class ArticleBlocProvider extends StatefulWidget {
  final Widget child;
  final ArticleBloc bloc;

  const ArticleBlocProvider({Key? key, required this.child, required this.bloc}) : super(key: key);

  @override
  _ArticleBlocProviderState createState() => _ArticleBlocProviderState();

  static ArticleBloc of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ArticleBlocProvider>()!.bloc;
  }
}

class _ArticleBlocProviderState extends State<ArticleBlocProvider> {
  @override
  Widget build(BuildContext context) {
    return _ArticleBlocProvider(bloc: widget.bloc, child: widget.child);
  }

  @override
  void dispose() {
    widget.bloc.close();
    super.dispose();
  }
}

class _ArticleBlocProvider extends InheritedWidget {
  final ArticleBloc bloc;

  const _ArticleBlocProvider({
    Key? key,
    required this.bloc,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ArticleBlocProvider old) => bloc != old.bloc;
}
