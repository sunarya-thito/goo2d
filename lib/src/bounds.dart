import 'dart:ui';

import 'package:goo2d/goo2d.dart';

abstract interface class RenderObjectBounds extends Component {
  Size get size;
}

class ObjectSize extends Component {
  Size size = Size.infinite;
}
