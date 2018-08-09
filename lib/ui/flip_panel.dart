// The FlipPanel class is an evolution of the FlipPanel conceived and implemented
// by Hunghd for the flip_panel package whose source code you can find here:
//  https://github.com/hnvn/flutter_flip_panel
//
// It has been largely modified to adapt it to the manual gestures but the
// build methods mostly remain as in the original source, though slightly
// reduced.

import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

typedef Widget ItemBuilder<T>(BuildContext, T, VoidCallback, double);

// Callback that allows to request for more items to the server or to refresh
// the list if refresh is true.
typedef void GetItems({bool refresh});

enum FlipDirection { up, down, none }

enum LastFlip { none, previous, next }

const double _kFastThreshold = 800.0;

class FlipPanel<T> extends StatefulWidget {
  final ItemBuilder<T> itemBuilder;
  final Duration duration;
  final double height;
  final Stream<List<T>> itemStream;
  final GetItems getItemsCallback;

  FlipPanel({
    Key key,
    @required this.itemBuilder,
    @required this.itemStream,
    @required this.getItemsCallback,
    @required this.height,
    this.duration = const Duration(milliseconds: 100),
  })  : assert(itemBuilder != null),
        assert(itemStream != null),
        assert(getItemsCallback != null),
        assert(height != null),
        super(key: key);

  @override
  _FlipPanelState<T> createState() => _FlipPanelState<T>();
}

class _FlipPanelState<T> extends State<FlipPanel>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;
  int _currentIndex;
  bool _isReversePhase;
  bool _running;
  final _perspective = 0.0003;
  final _zeroAngle =
      0.0001; // There's something wrong in the perspective transform, I use a very small value instead of zero to temporarily get it around.

  double _height;

  FlipDirection _direction;

  List<Widget> widgets;

  StreamSubscription<List<T>> _subscription;

  // Items that have been received through the stream.
  // This is used to know if we need to request more items from the server
  // depending on the user flipping.
  int _availableItems = 0;

  // Number of items between the _currentIndex and _availableItemns below which
  // we launch a request to server for more items (next page).
  int _updateThreshold = 5;

  bool _waitingForRefresh = false;

  Widget _prevChild, _currentChild, _nextChild;
  Widget _upperChild1, _upperChild2;
  Widget _lowerChild1, _lowerChild2;

  double _dragExtent = 0.0;
  bool _dragging = false;

  // _flipExtent is the distance needed for the manual flip.
  // The flip distance is the distance from the drag start point to the center
  // of the flip panel, with a minimum distance of a quarter of the panel
  // height
  double _flipExtent = 200.0;

  LastFlip _lastFlip = LastFlip.none;

  bool _shouldShowNoMoreItemsMessage = false;

  /// The first time the widget is built in the physical device the passed
  /// height is 0.0. Later the widget is updated with the correct size. Since
  /// initState() is not called again, we set the size here.
  /// This does not happen in the virtual device.
  @override
  didUpdateWidget(FlipPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _height = widget.height;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _isReversePhase = false;
    _running = false;
    _direction = FlipDirection.none;
    _height = widget.height;

    WidgetsBinding.instance.addPostFrameCallback((_) {});

    _controller =
        new AnimationController(duration: widget.duration, vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_dragging) {
              _isReversePhase = true;
              _controller.reverse();
            }
            if (status == AnimationStatus.dismissed) {
              //_currentValue = _nextValue;
              _running = false;
              _currentIndex = _lastFlip == LastFlip.next &&
                      _currentIndex < widgets.length - 1
                  ? _currentIndex + 1
                  : _lastFlip == LastFlip.previous && _currentIndex > 0
                      ? _currentIndex - 1
                      : _currentIndex;
              // Avoid going beyond max. items of widgets list
              if (_lastFlip == LastFlip.next &&
                  _currentIndex == _availableItems - _updateThreshold) {
                widget.getItemsCallback();
              }
            }
          })
          ..addListener(() {
            setState(() {
              _running = true;
            });
          });
    _animation =
        Tween(begin: _zeroAngle, end: math.pi / 2).animate(_controller);

    _subscription = widget.itemStream.distinct().listen((items) {
      // A null items list is sent to indicate that a refresh
      // request has been sent to the server. It will be used to show a refresh
      // indicator
      if (items == null || items.length == 0) {
        widgets = null;
        _availableItems = 0;
        _currentIndex = 0;
        _waitingForRefresh = true;
        setState(() {});
        return;
      }
      _waitingForRefresh = false;
      if (_availableItems == 0) {
        widgets = [];
        widgets.add(_buildFirstWidget(items[0]));
        widgets.addAll(items
            .skip(1)
            .map((item) => widget.itemBuilder(context, item, FlipBack, _height))
            .toList());
        _upperChild1 = makeUpperClip(widgets[0]);
        _lowerChild1 = makeLowerClip(widgets[0]);
      } else {
        widgets.addAll(items
            .map((item) => widget.itemBuilder(context, item, FlipBack, _height))
            .toList());
      }
      _availableItems += items.length;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_subscription != null) _subscription.cancel();
    super.dispose();
  }

  Widget _buildFirstWidget(T item) {
    return widget.itemBuilder(context, item, null, _height);
  }

  @override
  Widget build(BuildContext context) {
    // We only build new widgets when not waiting for refresh.
    // If we are waiting for refresh we don't invalidate the present widgets
    // until new ones are received
    if (!_waitingForRefresh) {
      if (widgets == null || _availableItems == 0) {
        return Container(
          color: Colors.white,
          height: _height,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      _buildChildWidgetsIfNeed(context);
    }

    return _buildPanel();
  }

  Widget makeUpperClip(Widget widget) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 0.5,
        child: widget,
      ),
    );
  }

  Widget makeLowerClip(Widget widget) {
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.5,
        child: widget,
      ),
    );
  }

  void FlipBack({bool backToTop = false}) {
    if (_currentIndex == 0) return;
    _running = true;
    _currentChild = null;
    _isReversePhase = false;
    _direction = FlipDirection.down;
    _lastFlip = LastFlip.previous;
    if (backToTop) {
      _currentChild = widgets[_currentIndex];
      _prevChild = widgets[0];
      _currentIndex = 0;
      _upperChild1 = makeUpperClip(_currentChild);
      _lowerChild1 = makeLowerClip(_currentChild);
      _upperChild2 = makeUpperClip(_prevChild);
      _lowerChild2 = makeLowerClip(_prevChild);
    }
    _controller.animateTo(1.0);
  }

  void _buildChildWidgetsIfNeed(BuildContext context) {
    if (_running) {
      if (_direction == FlipDirection.up) {
        if (_currentChild == null && _currentIndex < widgets.length - 1) {
          _currentChild = widgets[_currentIndex];
          _nextChild = widgets[_currentIndex + 1];
          _upperChild1 = makeUpperClip(_currentChild);
          _lowerChild1 = makeLowerClip(_currentChild);
          _upperChild2 = makeUpperClip(_nextChild);
          _lowerChild2 = makeLowerClip(_nextChild);
        }
      }
      if (_direction == FlipDirection.down) {
        if (_currentChild == null && _currentIndex > 0) {
          _currentChild = widgets[_currentIndex];
          _prevChild = widgets[_currentIndex - 1];
          _upperChild1 = makeUpperClip(_currentChild);
          _lowerChild1 = makeLowerClip(_currentChild);
          _upperChild2 = makeUpperClip(_prevChild);
          _lowerChild2 = makeLowerClip(_prevChild);
        }
      }
    } else {
      _currentChild = widgets[_currentIndex];
      _upperChild1 = makeUpperClip(_currentChild);
      _lowerChild1 = makeLowerClip(_currentChild);
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragging = true;
    _running = true;
    _direction = FlipDirection.none;
    _dragExtent = _controller.value * _dragExtent.sign;

    double _halfFlipPanel = context.size.height / 2;
    RenderBox referenceBox = context.findRenderObject();
    Offset localPosition = referenceBox.globalToLocal(details.globalPosition);
    _flipExtent = (localPosition.dy - _halfFlipPanel)
        .abs()
        .clamp(_halfFlipPanel / 2, double.infinity);
    if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double delta = details.primaryDelta;
    _dragExtent += delta;
    setState(() {
      if (_direction == FlipDirection.none) {
        _direction = _dragExtent < 0 ? FlipDirection.up : FlipDirection.down;
        _currentChild = null;
      }
      // Need to add 0.01 to correct an artifact appearing when clamping to limit
      _dragExtent = _direction == FlipDirection.up
          ? _dragExtent.clamp(-(_flipExtent * 2 + 0.01), 0.0)
          : _dragExtent.clamp(0.0, _flipExtent * 2 - 0.01);
      if (_direction == FlipDirection.down && _currentIndex == 0) {
        _dragExtent = 0.0;
      }
      if (_direction == FlipDirection.up &&
          _currentIndex == widgets.length - 1) {
        _dragExtent = 0.0;
        _shouldShowNoMoreItemsMessage = true;
      }
      if (_dragExtent.abs() < _flipExtent) {
        _controller.value = (_dragExtent / _flipExtent).abs();
      } else {
        _controller.value =
            (((_flipExtent * 2) - _dragExtent.abs()) / _flipExtent).abs();
      }
      _isReversePhase = (_dragExtent / _flipExtent).abs() > 1.0 ? true : false;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragging = false;

    if (_dragExtent == 0.0) {
      if (_shouldShowNoMoreItemsMessage) {
        _showNoMoreItemsMessage();
        _shouldShowNoMoreItemsMessage = false;
      }
      return;
    }

    final double velocity = details.primaryVelocity;
    final bool fast = velocity.abs() > _kFastThreshold;

    if (fast) {
      if (_dragExtent.abs() > _flipExtent) {
        _controller.animateTo(0.0);
      } else {
        _controller.animateTo(1.0);
      }
      _lastFlip =
          _direction == FlipDirection.up ? LastFlip.next : LastFlip.previous;
    } else {
      if (_dragExtent.abs() > _flipExtent) {
        _lastFlip =
            _direction == FlipDirection.up ? LastFlip.next : LastFlip.previous;
      } else {
        _lastFlip = LastFlip.none;
      }
      _controller.animateTo(0.0);
    }
  }

  Widget _buildUpperFlipPanel() => _direction == FlipDirection.up
      ? Stack(
          children: [
            Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _upperChild1),
            _isReversePhase
                ? Opacity(
                    opacity: 1 - _controller.value,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      height: _height / 2,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black,
                    ))
                : Container(),
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? _animation.value : math.pi / 2),
              child: _upperChild2,
            ),
          ],
        )
      : Stack(
          children: [
            Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _upperChild2),
            !_isReversePhase
                ? Opacity(
                    opacity: 1 - _controller.value,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      height: _height / 2,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black,
                    ))
                : Container(),
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? math.pi / 2 : _animation.value),
              child: _upperChild1,
            ),
          ],
        );

  Widget _buildLowerFlipPanel() => _direction == FlipDirection.up
      ? Stack(
          children: [
            Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerChild2),
            !_isReversePhase
                ? Opacity(
                    opacity: 1 - _controller.value,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      height: _height / 2,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black,
                    ))
                : Container(),
            Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? math.pi / 2 : -_animation.value),
              child: _lowerChild1,
            )
          ],
        )
      : Stack(
          children: [
            Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, _perspective)
                  ..rotateX(_zeroAngle),
                child: _lowerChild1),
            _isReversePhase
                ? Opacity(
                    opacity: 1 - _controller.value,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      height: _height / 2,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black,
                    ))
                : Container(),
            Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? -_animation.value : math.pi / 2),
              child: _lowerChild2,
            ),
          ],
        );

  Widget _buildPanel() {
    Widget content = _running
        ? Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildUpperFlipPanel(),
              _buildLowerFlipPanel(),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: <Widget>[
                  _upperChild1,
                  _waitingForRefresh
                      ? Padding(
                          padding: EdgeInsets.only(top: 100.0),
                          child: Container(
                            width: double.infinity,
                            child: Center(child: RefreshProgressIndicator()),
                          ),
                        )
                      : Container(),
                ],
              ),
              _lowerChild1,
            ],
          );

    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: content,
    );
  }

  void _showNoMoreItemsMessage() {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text("No more articles for selected sources"),
      ),
    );
  }
}
