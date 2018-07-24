import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

typedef Widget DigitBuilder(BuildContext, int);

/// Signature for a function that creates a widget for a given index, e.g., in a
/// list.
typedef Widget IndexedItemBuilder(BuildContext, int);

/// Signature for a function that creates a widget for a value emitted from a [Stream]
typedef Widget StreamItemBuilder<T>(BuildContext, T);

/// A widget for flip panel with built-in animation
/// Content of the panel is built from [IndexedItemBuilder] or [StreamItemBuilder]
///
/// Note: the content size should be equal

enum FlipDirection { up, down, none }

enum ChangeRequested { initial, previous, same, next }

const double _kFastThreshold = 2500.0;

class FlipPanel<T> extends StatefulWidget {
  final IndexedItemBuilder indexedItemBuilder;
  final StreamItemBuilder<T> streamItemBuilder;
  final Stream<T> itemStream;
  final int itemsCount;
  final Duration period;
  final Duration duration;
  final int loop;
  final int startIndex;
  final T initValue;
  final double spacing;
  final FlipDirection direction;

  final bool isManuallyControlled;

  FlipPanel({
    Key key,
    this.indexedItemBuilder,
    this.streamItemBuilder,
    this.itemStream,
    this.itemsCount,
    this.period,
    this.duration,
    this.loop,
    this.startIndex,
    this.initValue,
    this.spacing,
    this.direction,
    this.isManuallyControlled,
  }) : super(key: key);

  /// Create a flip panel from iterable source
  /// [itemBuilder] is called periodically in each time of [period]
  /// The animation is looped in [loop] times before finished.
  /// Setting [loop] to -1 makes flip animation run forever.
  /// The [period] should be two times greater than [duration] of flip animation,
  /// if not the animation becomes jerky/stuttery.
  FlipPanel.builder({
    Key key,
    @required IndexedItemBuilder itemBuilder,
    @required this.itemsCount,
    @required this.period,
    this.duration = const Duration(milliseconds: 500),
    this.loop = 1,
    this.startIndex = 0,
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  })  : assert(itemBuilder != null),
        assert(itemsCount != null),
        assert(startIndex < itemsCount),
        assert(period == null ||
            period.inMilliseconds >= 2 * duration.inMilliseconds),
        indexedItemBuilder = itemBuilder,
        streamItemBuilder = null,
        itemStream = null,
        initValue = null,
        isManuallyControlled = false,
        super(key: key);

  /// Create a flip panel from stream source
  /// [itemBuilder] is called whenever a new value is emitted from [itemStream]
  FlipPanel.stream({
    Key key,
    @required this.itemStream,
    @required StreamItemBuilder<T> itemBuilder,
    this.initValue,
    this.duration = const Duration(milliseconds: 500),
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  })  : assert(itemStream != null),
        indexedItemBuilder = null,
        streamItemBuilder = itemBuilder,
        itemsCount = 0,
        period = null,
        loop = 0,
        startIndex = 0,
        isManuallyControlled = false,
        super(key: key);

  /// Create a flip panel to be fliped manually
  FlipPanel.manual({
    Key key,
    @required IndexedItemBuilder itemBuilder,
    @required this.itemsCount,
    this.duration = const Duration(milliseconds: 500),
    this.loop = 1,
    this.startIndex = 0,
    this.spacing = 0.5,
    this.direction = FlipDirection.up,
  })  : assert(itemBuilder != null),
        assert(itemsCount != null),
        assert(startIndex < itemsCount),
        isManuallyControlled = true,
        indexedItemBuilder = itemBuilder,
        streamItemBuilder = null,
        period = null,
        itemStream = null,
        initValue = null,
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
  bool _isStreamMode;
  bool _running;
  final _perspective = 0.003;
  final _zeroAngle =
      0.0001; // There's something wrong in the perspective transform, I use a very small value instead of zero to temporarily get it around.
  int _loop;
  T _currentValue, _nextValue;
  Timer _timer;
  StreamSubscription<T> _subscription;
  bool _isManuallyControlled;
  FlipDirection _direction;

  Widget _child1, _child2;
  Widget _upperChild1, _upperChild2;
  Widget _lowerChild1, _lowerChild2;

  double _dragExtent = 0.0;
  bool _dragging = false;

  ChangeRequested _changeRequested = ChangeRequested.initial;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _isStreamMode = widget.itemStream != null;
    _isReversePhase = false;
    _running = false;
    _loop = 0;
    _isManuallyControlled = widget.isManuallyControlled;
    _direction = widget.direction;

    if (!_isManuallyControlled) {
      _controller =
          new AnimationController(duration: widget.duration, vsync: this)
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                _isReversePhase = true;
                _controller.reverse();
              }
              if (status == AnimationStatus.dismissed) {
                _currentValue = _nextValue;
                _running = false;
              }
            })
            ..addListener(() {
              setState(() {
                _running = true;
              });
            });
      _animation =
          Tween(begin: _zeroAngle, end: math.pi / 2).animate(_controller);
    } else {
      _controller = new AnimationController(
          duration: widget.duration, vsync: this)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed && !_dragging) {
            _isReversePhase = true;
            _controller.reverse();
            print("Completed");
          }
          if (status == AnimationStatus.dismissed) {
            //_currentValue = _nextValue;
            _running = false;
            print("Dissmissed");
          }
        })
        ..addListener(() {
          setState(() {
            _running = true;
          });
        });
      _animation =
          Tween(begin: _zeroAngle, end: math.pi / 2).animate(_controller);
    }

    if (widget.period != null) {
      _timer = Timer.periodic(widget.period, (_) {
        if (widget.loop < 0 || _loop < widget.loop) {
          if (_currentIndex + 1 == widget.itemsCount - 2) {
            _loop++;
          }
          _currentIndex = (_currentIndex + 1) % widget.itemsCount;
          _child1 = null;
          _isReversePhase = false;
          _controller.forward();
        } else {
          _timer.cancel();
          _currentIndex = (_currentIndex + 1) % widget.itemsCount;
          setState(() {
            _running = false;
          });
        }
      });
    }

    if (_isStreamMode) {
      _currentValue = widget.initValue;
      _subscription = widget.itemStream.distinct().listen((value) {
        if (_currentValue == null) {
          _currentValue = value;
        } else if (value != _currentValue) {
          _nextValue = value;
          _child1 = null;
          _isReversePhase = false;
          _controller.forward();
        }
      });
    } else if (widget.loop < 0 || _loop < widget.loop) {
      //_controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_subscription != null) _subscription.cancel();
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildChildWidgetsIfNeed(context);

    return _buildPanel();
  }

  void _buildChildWidgetsIfNeed(BuildContext context) {
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

    if (_running) {
      if (_child1 == null) {
        print("Running: Child1 null");
        _child1 = _child2 != null
            ? _child2
            : _isStreamMode
                ? widget.streamItemBuilder(context, _currentValue)
                : widget.indexedItemBuilder(
                    context, _currentIndex % widget.itemsCount);
        _child2 = null;
        _upperChild1 =
            _upperChild2 != null ? _upperChild2 : makeUpperClip(_child1);
        _lowerChild1 =
            _lowerChild2 != null ? _lowerChild2 : makeLowerClip(_child1);
      }
      if (_child2 == null) {
        print("Running: Child2 null");
        _child2 = _isStreamMode
            ? widget.streamItemBuilder(context, _nextValue)
            : widget.indexedItemBuilder(
                context, (_currentIndex + 1) % widget.itemsCount);
        _upperChild2 = makeUpperClip(_child2);
        _lowerChild2 = makeLowerClip(_child2);
      }
    } else {
      print("Not Running");
      if (_changeRequested != ChangeRequested.same) {// || _changeRequested == ChangeRequested.initial) {
        _child1 = _child2 != null
            ? _child2
            : _isStreamMode
            ? widget.streamItemBuilder(context, _currentValue)
            : widget.indexedItemBuilder(
            context, _currentIndex % widget.itemsCount);
        _upperChild1 =
        _upperChild2 != null ? _upperChild2 : makeUpperClip(_child1);
        _lowerChild1 =
        _lowerChild2 != null ? _lowerChild2 : makeLowerClip(_child1);
      }
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragging = true;
    _running = true;
    _direction = FlipDirection.none;
    _dragExtent = _controller.value * _dragExtent.sign;
    //_isReversePhase = false;
    if (_controller.isAnimating) {
      _controller.stop();
    }
    print("Drag started");
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double delta = details.primaryDelta;
    _dragExtent += delta;
    setState(() {
      FlipDirection _localDirection = _dragExtent < 0 ? FlipDirection.up : FlipDirection.down;
      if (_localDirection != _direction) {
        _direction = _localDirection;
        if (_changeRequested != ChangeRequested.initial && _changeRequested != ChangeRequested.same) {
          if (_direction == FlipDirection.up) {
            _currentIndex++;
          } else {
            _currentIndex--;
          }
          _child1 = null;
        }
      }
      if (_direction == FlipDirection.down && _currentIndex == 0) {
        _dragExtent = 0.0;
      }
      if (_dragExtent.abs() < 200.0) {
        _controller.value = (_dragExtent / 200.0).abs();
      } else  {
        _controller.value = ((400.0 - _dragExtent.abs()) / 200.0).abs();
      }
      _isReversePhase = (_dragExtent / 200.0).abs() > 1.0 ? true : false;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragging = false;
    final double velocity = details.primaryVelocity;
    final bool fast = velocity.abs() > _kFastThreshold;
    if (fast) {
      _controller.animateTo(1.0);
      _changeRequested = _direction == FlipDirection.up ? ChangeRequested.next : ChangeRequested.previous;
      print("fast");
    } else {
      if (_dragExtent.abs() < 200.0) {
        _changeRequested = ChangeRequested.same;
      } else  {
        _changeRequested = _direction == FlipDirection.up ? ChangeRequested.next : ChangeRequested.previous;
      }
      _controller.animateTo(0.0);
      print("not fast");
    }
    print("Drag end");
    print("${_currentIndex}");
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
            Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, _perspective)
                ..rotateX(_isReversePhase ? -_animation.value : math.pi / 2),
              child: _lowerChild2,
            )
          ],
        );

  Widget _buildPanel() {
    Widget content = _running
        ? Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildUpperFlipPanel(),
              Padding(
                padding: EdgeInsets.only(top: widget.spacing),
              ),
              _buildLowerFlipPanel(),
            ],
          )
        : _isStreamMode && _currentValue == null
            ? Container()
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _perspective)
                        ..rotateX(_zeroAngle),
                      child: _upperChild1),
                  Padding(
                    padding: EdgeInsets.only(top: widget.spacing),
                  ),
                  Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, _perspective)
                        ..rotateX(_zeroAngle),
                      child: _lowerChild1)
                ],
              );

    if (_isManuallyControlled) {
      return GestureDetector(
        onVerticalDragStart: _handleDragStart,
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: content,
      );
    }
    return content;
  }
}
