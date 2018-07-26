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

enum LastFlip { none, previous, next }

const double _kFastThreshold = 800.0;

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
    this.duration = const Duration(milliseconds: 100),
    this.loop = 1,
    this.startIndex = 0,
    this.spacing = 0.0,
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
  final _perspective = 0.0003;
  final _zeroAngle =
      0.0001; // There's something wrong in the perspective transform, I use a very small value instead of zero to temporarily get it around.
  T _currentValue, _nextValue;
  Timer _timer;
  StreamSubscription<T> _subscription;
  bool _isManuallyControlled;
  FlipDirection _direction;

  List<Widget> _widgets;
  List<Widget> _widgets2;

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _isStreamMode = widget.itemStream != null;
    _isReversePhase = false;
    _running = false;
    _isManuallyControlled = widget.isManuallyControlled;
    _direction = widget.direction;

    WidgetsBinding.instance.addPostFrameCallback((_) {});

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
                        _currentIndex < _widgets.length - 1
                    ? _currentIndex + 1
                    : _lastFlip == LastFlip.previous && _currentIndex > 0
                        ? _currentIndex - 1
                        : _currentIndex;
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

  void _buildChildWidgetsIfNeed(BuildContext context) {
    if (_widgets == null) {
      _widgets = List.generate(
          10,
          (index) => Container(
                color: Colors.black,
                height: MediaQuery.of(context).size.height - 24,
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Text(
                    '${index}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 400.0,
                        color: Colors.white),
                  ),
                ),
              ));
      List<Color> colors = [
        Colors.red,
        Colors.blue,
        Colors.yellow,
        Colors.green,
        Colors.amber
      ];
      _widgets2 = colors
          .map((color) => Container(
                color: color,
                height: MediaQuery.of(context).size.height - 24,
                width: MediaQuery.of(context).size.width,
              ))
          .toList();
      _upperChild1 = makeUpperClip(_widgets[0]);
      _lowerChild1 = makeLowerClip(_widgets[0]);
    }
    if (_running) {
      if (_direction == FlipDirection.up) {
        if (_currentChild == null && _currentIndex < _widgets.length - 1) {
          _currentChild = _widgets[_currentIndex];
          _nextChild = _widgets[_currentIndex + 1];
          _upperChild1 = makeUpperClip(_currentChild);
          _lowerChild1 = makeLowerClip(_currentChild);
          _upperChild2 = makeUpperClip(_nextChild);
          _lowerChild2 = makeLowerClip(_nextChild);
        }
      }
      if (_direction == FlipDirection.down) {
        if (_currentChild == null && _currentIndex > 0) {
          _currentChild = _widgets[_currentIndex];
          _prevChild = _widgets[_currentIndex - 1];
          _upperChild1 = makeUpperClip(_currentChild);
          _lowerChild1 = makeLowerClip(_currentChild);
          _upperChild2 = makeUpperClip(_prevChild);
          _lowerChild2 = makeLowerClip(_prevChild);
        }
      }
    } else {
      _currentChild = _widgets[_currentIndex];
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
    print("_halfFlipPanel: ${_halfFlipPanel}");
    print("_flipExtent: ${_flipExtent}");
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
      // Need to add 0.01 to correct an artifact appearing when campling to limit
      _dragExtent = _direction == FlipDirection.up
          ? _dragExtent.clamp(-(_flipExtent * 2 + 0.01), 0.0)
          : _dragExtent.clamp(0.0, _flipExtent * 2 - 0.01);
      if (_direction == FlipDirection.down && _currentIndex == 0) {
        _dragExtent = 0.0;
      }
      // Temporary to avoid error beyond max. items of widgets list
      if (_direction == FlipDirection.up &&
          _currentIndex == _widgets.length - 1) {
        _dragExtent = 0.0;
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

    if (_dragExtent == 0.0) return;

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
            mainAxisSize: MainAxisSize.max,
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
