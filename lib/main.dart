import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:some_package/some_package.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppleTVGestureHandler().init();
  bool isAppleTV = (String.fromEnvironment('TARGET_PLATFORM') == 'TVOS');

  runApp(App());

  RawKeyboard.instance.addListener((event) {
    if ((LogicalKeyboardKey.backspace == event.logicalKey) ||
        (LogicalKeyboardKey.escape == event.logicalKey)) {
      exit(0); // not the correct way to close / minimize it
    }
  });
}

class AppleTVGestureHandler {
  static AppleTVGestureHandler? _instance;

  factory AppleTVGestureHandler() => _instance ??= AppleTVGestureHandler._();

  num swipeStartX = 0.0;
  num swipeStartY = 0.0;
  bool isMoving = false;
  static const gamePadChannelName = 'flutter/gamepadtouchevent';
  //static const keyEventChannelName = 'flutter/keyevent';
  static const codec = JSONMessageCodec();

  static const channel = BasicMessageChannel<dynamic>(gamePadChannelName, codec);
  //static const channel_key = BasicMessageChannel<dynamic>(keyEventChannelName, codec);

  AppleTVGestureHandler._();

  void init() {
    channel.setMessageHandler(_onMessage);

    // (< flutter 1.26) Workarround for the fact that ios (and therefore also AppleTV) does not support keyboards and
    // therefor do not handle key events for ios in the Focusmanger in the flutter library (outside the scope of the engine)
    HardwareKeyboard.instance.addHandler((event) {
      if (event.runtimeType == RawKeyUpEvent) {
        if (LogicalKeyboardKey.arrowLeft == event.logicalKey) {
          _moveLeft();
          return true;
        } else if (LogicalKeyboardKey.arrowRight == event.logicalKey) {
          _moveRight();
          return true;
        } else if (LogicalKeyboardKey.arrowUp == event.logicalKey) {
          _moveUp();
          return true;
        } else if (LogicalKeyboardKey.arrowDown == event.logicalKey) {
          _moveDown();
          return true;
        } else if ((LogicalKeyboardKey.enter == event.logicalKey) ||
            (LogicalKeyboardKey.select == event.logicalKey)) {
          return true;
        } else if ((LogicalKeyboardKey.backspace == event.logicalKey) ||
            (LogicalKeyboardKey.escape == event.logicalKey)) {
          ByteData message = const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute'));
          ServicesBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage('flutter/navigation', message, (_) {});
          return true;
        }
      } else if (event.runtimeType == RawKeyDownEvent) {
        if ((LogicalKeyboardKey.enter == event.logicalKey) ||
            (LogicalKeyboardKey.select == event.logicalKey)) {
          return true;
        }
      }
      return false;
    });
  }

// Using "FocusManager.instance.primaryFocus.focusInDirection" is a workarround because ios target does not handle key presses in flutter focusmanager. Ideally we would send key events!
// In the future when ios does support, the code needs to be update to simulate the key press. At that point also key codes sent need to be validated corrected in the code below!

  void _moveUp() {
    FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.up);
  }

  void _moveDown() {
    FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.down);
  }

  void _moveLeft() {
    FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.left);
  }

  void _moveRight() {
    FocusManager.instance.primaryFocus?.focusInDirection(TraversalDirection.right);
  }

  Future<void> _onMessage(dynamic arguments) async {
    num x = arguments['x'];
    num y = arguments['y'];
    String type = arguments['type'];

    if (type == 'started') {
      swipeStartX = x;
      swipeStartY = y;
      isMoving = true;
    } else if (type == 'move') {
      if (isMoving) {
        var moveX = swipeStartX - x;
        var moveY = swipeStartY - y;

        // need to move min distance in any direction
        // the 150px needs tweaking and might needs to be variable based on location of the widget on screen and duration/time of the movement to make it smoother
        if ((moveX.abs() >= 150) || (moveY.abs() >= 150)) {
          // determine direction horz/vert
          if (moveX.abs() >= moveY.abs()) {
            if (moveX >= 0) {
              _moveLeft();
            } else {
              _moveRight();
            }
          } else {
            if (moveY >= 0) {
              _moveUp();
            } else {
              _moveDown();
            }
          }
          // reset start point (direction could change based on next cooordinates received)
          swipeStartX = x;
          swipeStartY = y;
        }
      }
    } else if (type == 'ended') {
      isMoving = false;
    }
  }
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final fn = FocusNode(descendantsAreFocusable: true, debugLabel: 'root');
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      fn.consumeKeyboardToken();
    });
    super.initState();
    initPlatformState();
    print('version = $_platformVersion');
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await SomePackage.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      home: Focus(
        focusNode: fn,
        descendantsAreFocusable: true,
        child: Home(),
      ),
    );
  }
}

class Tile extends StatefulWidget {
  final double? w;
  final double? h;
  final Color? color;
  final bool autofocus;

  const Tile({
    Key? key,
    this.w,
    this.h,
    this.color,
    this.autofocus = true,
  }) : super(key: key);

  @override
  _TileState createState() => _TileState();
}

class _TileState extends State<Tile> {
  bool focused = false;
  Color _containerColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (value) => setState(() {
          focused = value;

          if (focused) {
            _containerColor = Colors.blue;
            // do stuff
          } else {}
        }),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            color: this.widget.color ?? (focused ? _containerColor : Colors.white),
            image: DecorationImage(
              image: AssetImage('assets/images/flutter.png'),
            ),
          ),
          width: widget.w,
          height: widget.h,
        ),
        onKeyEvent: (_, event) {
          // In some cases RawKeyDownEvent isn't sent by engine.
          // To manage all cases use RawKeyUpEvent which is always sent.
          if (event is RawKeyUpEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select)) {
            setState(() {
              _containerColor = Colors.red;
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      ),
    );
  }
}

class Collection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: AxisTraversalPolicy(axis: Axis.horizontal),
      child: ListView.builder(
        itemCount: 4,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 76),
        itemBuilder: (context, index) {
          return Tile(w: MediaQuery.of(context).size.width / 5);
        },
      ),
    );
  }
}

class AxisTraversalPolicy extends FocusTraversalPolicy {
  final Axis axis;

  AxisTraversalPolicy({required this.axis});

  @override
  FocusNode? findFirstFocusInDirection(
    FocusNode currentNode,
    TraversalDirection direction,
  ) {
    return null;
  }

  @override
  FocusNode? findFirstFocus(FocusNode currentNode, {bool ignoreCurrentFocus = false}) {
    return null;
  }

  bool handleHorizontalGroupNavigation(
    FocusNode currentNode,
    TraversalDirection direction,
    Iterable<FocusNode> nodes,
  ) {
    switch (direction) {
      case TraversalDirection.left:
        if (nodes.first == currentNode) {
          exitGroup(currentNode, direction);
        } else {
          moveFocus(currentNode, direction);
        }
        break;

      case TraversalDirection.right:
        if (nodes.last == currentNode) {
          exitGroup(currentNode, direction);
        } else {
          moveFocus(currentNode, direction);
        }
        break;
      case TraversalDirection.up:
      case TraversalDirection.down:
        exitGroup(currentNode, direction);
        break;
    }

    return true;
  }

  bool handleVerticalGroupNavigation(
    FocusNode currentNode,
    TraversalDirection direction,
    Iterable<FocusNode> nodes,
  ) {
    switch (direction) {
      case TraversalDirection.up:
        if (nodes.first == currentNode) {
          exitGroup(currentNode, direction);
        } else {
          moveFocus(currentNode, direction);
        }
        break;

      case TraversalDirection.down:
        if (nodes.last == currentNode) {
          exitGroup(currentNode, direction);
        } else {
          moveFocus(currentNode, direction);
        }
        break;
      case TraversalDirection.left:
      case TraversalDirection.right:
        exitGroup(currentNode, direction);
        break;
    }

    return true;
  }

  void exitGroup(FocusNode node, TraversalDirection direction) {
    _ensureVisible(node.nearestScope?.traversalDescendants.toList(), node, direction);
  }

  void moveFocus(FocusNode node, TraversalDirection direction) {
    _ensureVisible(node.parent?.traversalDescendants.where((element) => element != node).toList(),
        node, direction);
  }

  void _ensureVisible(List<FocusNode>? candidates, FocusNode node, TraversalDirection direction) {
    if (candidates != null) {
      final ctxt = _moveFocus(node, direction, candidates).context;
      if (ctxt != null) {
        Scrollable.ensureVisible(
          ctxt,
          alignment: 0.5,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          duration: const Duration(milliseconds: 250),
        );
      }
    }
  }

  FocusNode _moveFocus(FocusNode node, TraversalDirection direction, List<FocusNode> candidates) {
    switch (direction) {
      case TraversalDirection.up:
        candidates = candidates.where((element) => element.rect.bottom < node.rect.top).toList();
        break;
      case TraversalDirection.right:
        candidates = candidates.where((element) => element.rect.left > node.rect.right).toList();
        break;
      case TraversalDirection.down:
        candidates = candidates.where((element) => element.rect.top > node.rect.bottom).toList();
        break;
      case TraversalDirection.left:
        candidates = candidates.where((element) => element.rect.right < node.rect.left).toList();
        break;
    }

    if (candidates.isEmpty) return node;

    candidates
      ..sort((a, b) {
        switch (direction) {
          case TraversalDirection.up:
            return (node.rect.topCenter - a.rect.bottomCenter)
                .distance
                .compareTo((node.rect.topCenter - b.rect.bottomCenter).distance);

          case TraversalDirection.right:
            return (node.rect.centerRight - a.rect.centerLeft)
                .distance
                .compareTo((node.rect.centerRight - b.rect.centerLeft).distance);
          case TraversalDirection.down:
            return (node.rect.bottomCenter - a.rect.topCenter)
                .distance
                .compareTo((node.rect.bottomCenter - b.rect.topCenter).distance);
          case TraversalDirection.left:
            return (node.rect.centerRight - a.rect.centerLeft)
                .distance
                .compareTo((node.rect.centerRight - b.rect.centerLeft).distance);
        }
      });

    final newFocusNode = candidates.first;
    newFocusNode.requestFocus();
    return newFocusNode;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    var items = sortDescendants(currentNode.parent?.children ?? [], currentNode);

    if (axis == Axis.vertical) {
      handleVerticalGroupNavigation(currentNode, direction, items);
    } else {
      handleHorizontalGroupNavigation(currentNode, direction, items);
    }

    return false;
  }

  @override
  Iterable<FocusNode> sortDescendants(Iterable<FocusNode> descendants, FocusNode currentNode) {
    int Function(FocusNode, FocusNode) compare;

    switch (axis) {
      case Axis.horizontal:
        compare = (a, b) => (a.offset.dx - b.offset.dx).toInt();
        break;
      case Axis.vertical:
        compare = (a, b) => (a.offset.dy - b.offset.dy).toInt();
        break;
    }

    return descendants.toList()..sort(compare);
  }
}

Future<bool> _onBackPressed() {
  exit(0);
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: new Scaffold(
          body: Stack(
            children: [
              Padding(
                  padding: EdgeInsets.fromLTRB(80, 40, 20, 20),
                  child: Text('Flutter for Apple TV', style: TextStyle(fontSize: 28))),
              Container(
                child: ListView.builder(
                  itemCount: 4,
                  padding: const EdgeInsets.only(top: 100),
                  itemBuilder: (context, index) {
                    return Container(
                      height: MediaQuery.of(context).size.height / 5,
                      child: Collection(),
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}
