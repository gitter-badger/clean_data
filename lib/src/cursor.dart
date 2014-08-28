part of clean_data;

class Cursor extends Object with ChangeNotificationsMixin, ChangeChildNotificationsMixin {
  final List path;
  final Reference ref;

  factory Cursor() {
    return new Cursor.forRef(new Reference(), []);
  }
  Cursor.forRef(this.ref, this.path);

  Stream get onChange {
    if(_onChangeController == null) {
      _onChangeController = new StreamController.broadcast();
      ref.listenIn(path, _onChangeController, false);
    }
    return _onChangeController.stream;
  }
  Stream get onChangeSync  {
      if(_onChangeSyncController == null) {
        _onChangeSyncController = new StreamController.broadcast(sync: true);
        ref.listenIn(path, _onChangeSyncController, true);
      }
      return _onChangeSyncController.stream;
    }
  Stream get onBeforeAdd {
    if(_onChangeSyncController == null) {
      _onChangeSyncController = new StreamController.broadcast(sync: true);
    }
    return _onChangeSyncController.stream;
  }
  Stream get onBeforeRemove {
    if(_onBeforeRemovedController == null) {
      _onBeforeRemovedController = new StreamController.broadcast(sync: true);
    }
    return _onBeforeRemovedController.stream;
  }

  StreamController<dynamic> _onChangeController;
  StreamController<Map> _onChangeSyncController;
  StreamController<dynamic> _onBeforeAddedController;
  StreamController<dynamic> _onBeforeRemovedController;

  dispose() {
    if(_onChangeController != null)
      _onChangeController.close().then((ref.stopListenIn(path, _onChangeController, false)));
    if(_onChangeSyncController != null)
      _onChangeSyncController.close().then((ref.stopListenIn(path, _onChangeSyncController, true)));

    _onBeforeAddedController.close();
    _onBeforeRemovedController.close();
  }
}

class Reference {
  PersistentMap _data;
  get value => _data;

  Map _listeners = {};
  Map _listenersSync = {};
  Reference();

  Cursor get cursor => new Cursor.forRef(this, new List.from([]));
  //TODO: should check for existence of path
  Cursor cursorFor(key) => new Cursor.forRef(this, new List.from([key]));
  Cursor cursorForIn(List path) => new Cursor.forRef(this, path);

  lookupIn(Iterable path) {
    if(path.isEmpty) return _data;
    return _data.lookupIn(path);
  }

  changeIn(Iterable path, dynamic value) {
    if(path.isEmpty) {
      if(value is Persistent) _data = value;
      else throw new Exception('Only persistent data can be added to root');
    }
    Option opt = _data.lookupIn(path.take(path.length-1));
    if(opt.isDefined) {
      _markChange(path, 'add');
    }
    else {
      _markChange(path, 'change');
    }
    _data.insertIn(path, value);
  }

  removeIn(Iterable path, value) {
    throw 'Unsupported';
  }

  _markChange(Iterable path, String action) {
    Iterable pathPart = path;
    Iterator it = path.iterator;
    Map map = _listenersSync;

    //Sync controllers
    while(map != null && it.moveNext()) {
      List controllers = map[_controllers];
      if(controllers != null) {
        controllers.forEach((StreamController s) => s.add(pathPart));
      }
      map = map[it.current];
      pathPart = pathPart.skip(1);
    }
    List controllers = map[_controllers];
    if(controllers != null) {
      controllers.forEach((StreamController s) => s.add(pathPart));
    }

    //Async controllers
    map = _listeners;
    it = path.iterator;
    while(map != null && it.moveNext()) {
      List changed = map[_changed];
      if(changed != null) {
        changed.add(it.current);
      }
      else map[_changed] = [it.current];

      map = map[it.current];
    }

    Timer.run(() {
      if(_listeners[_changed] != null) {
        _notify(_listeners);
      }
    });
  }

  _notify(Map map) {
    if(map == null) return;

    (map[_changed] as List).forEach((e) => _notify(map[e]));
    map[_changed] == null;

    if(map[_controllers] != null)
      (map[_controllers] as List).forEach((StreamController e) => e.add(null));
  }

  listenIn(Iterable path, StreamController stream, bool sync) {
    if(sync) _insertIn(_listenersSync, path, _controllers, stream);
    else _insertIn(_listeners, path, _controllers, stream);
  }

  stopListenIn(Iterable path, StreamController stream, bool sync) {
    if(sync) _removeIn(_listenersSync, path, _controllers);
    else _removeIn(_listeners, path, _controllers);
  }
}

_insertIn(Map map, Iterable path, _KEY key, dynamic value) {
  Iterator it = path.iterator;
  while(it.moveNext()){
   if(map.putIfAbsent(it.current, () => {}));
   map = map[it.current];
  }
  map.containsKey(_controllers) ?
        (map[_controllers] as List).add(value)
      :
        (map[_controllers] = [value]);
}

_removeIn(Map map, Iterable path, _controllers) {
  throw 'Unsupported';
}

class _KEY {}
final _controllers = new _KEY();
final _changed = new _KEY();
