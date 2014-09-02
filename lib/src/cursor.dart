part of clean_data;

class Cursor {
  final List path;
  final Reference reference;

  get value => reference.lookupIn(path);

  Cursor(this.reference, this.path);

  Stream get onChange {
    if(_onChangeController == null) {
      _onChangeController = new StreamController.broadcast();
      reference.listenIn(path, _onChangeController, false);
    }
    return _onChangeController.stream;
  }

  Stream get onChangeSync  {
    if(_onChangeSyncController == null) {
      _onChangeSyncController = new StreamController.broadcast(sync: true);
      reference.listenIn(path, _onChangeSyncController, true);
    }
    return _onChangeSyncController.stream;
  }

  StreamController _onChangeController;
  StreamController _onChangeSyncController;

  dispose() {
    if(_onChangeController != null)
      _onChangeController.close().then((reference.stopListenIn(path, _onChangeController, false)));
    if(_onChangeSyncController != null)
      _onChangeSyncController.close().then((reference.stopListenIn(path, _onChangeSyncController, true)));
  }
}

class Reference {
  PersistentMap _data;
  get value => _data;

  Map _listeners = {};
  Map _listenersSync = {};
  Reference(this._data);
  factory Reference.from(data) => new Reference(deepPersistent(data));

  Cursor get cursor => new Cursor(this, new List.from([]));
  /*Cursor*/ cursorFor(key, {forPrimitives: true}) =>
      cursorForIn([key], forPrimitives: forPrimitives);
  /*Cursor*/ cursorForIn(List path, {forPrimitives: true}) {
    var val = lookupIn(path);
    if(val is PersistentMap) return new MapCursor(this, path);
    //TODO: if(val is PersistentVector) return new VectorCursor(this, path);
    else {
      if(forPrimitives) return new Cursor(this, path);
      else return val;
    }
  }

  lookupIn(Iterable path) {
    if(path.isEmpty) return _data;
    return _data.lookupIn(path);
  }

  changeIn(Iterable path, dynamic value) {
    value = deepPersistent(value);
    if(path.isEmpty) {
      if(_data == value) return;
      _markDiffChanges(_findIn(_listeners, path, create: false), _data, value);
      _markDiffChanges(_findIn(_listenersSync, path, create: false), _data, value);
      _data = value;
    }
    else {
      var newData = _data.insertIn(path, value);
      if(newData == _data) return;
      var oldData = _data.lookupIn(path, orElse: () => _none);
      if(oldData != _none) {
        _markDiffChanges(_findIn(_listeners, path, create: false), oldData, value);
        _markDiffChanges(_findIn(_listenersSync, path, create: false), oldData, value);
      }
      _data = newData;
    }

    _markChangePath(path);
    _notify();
  }

  removeIn(Iterable path) {
    if(path.isEmpty) throw 'Cannot delete with empty path';
    _data = _data.deleteIn(path);
    _markChangePath(path);
    _notify();
  }

  _markDiffChanges(Map listeners, before, after) {
    assert(before != after);
    if(listeners == null ||
        before is! PersistentMap || after is! PersistentMap) return;
    listeners[_changed] = [];
    before.keys.forEach((key) {
      if(!after.containsKey(key)) return; //IF ADDED - nobody else to notify
      if(before[key] != after[key]) {
        _markDiffChanges(listeners[key], before[key], after[key]);
        (listeners[_changed] as List).add(key);
      }
    });

    //IF ADDED - nobody else to notify
    if(listeners[_changed].isEmpty)
      listeners[_changed] = null;
  }

  _markChangePath(Iterable path) {
    //Sync controllers
   _markPath(_listenersSync, path);
    //Async controllers
   _markPath(_listeners, path);
  }

  _markPath(Map map, Iterable path) {
    Iterator it = path.iterator;
    while(map != null && it.moveNext()) {
      List changed = map[_changed];
      if(changed != null) {
        changed.add(it.current);
      }
      else map[_changed] = [it.current];
      map = map[it.current];
    }
  }

  _notify() {
    _notifyListeners(_listenersSync);
    Timer.run(() {
      if(_listeners[_changed] != null) {
        _notifyListeners(_listeners);
      }
    });
  }

  _notifyListeners(Map map) {
    if(map == null) return;

    if(map[_changed] != null ) {
      (map[_changed] as List).forEach((e) => _notifyListeners(map[e]));
      map[_changed] = null;
    }

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

Map _findIn(Map map, Iterable path, {create: false}) {
  Iterator it = path.iterator;
   while(it.moveNext() && map != null){
      if(create) map.putIfAbsent(it.current, () => {});
      map = map[it.current];
   }
   return map;
}

_insertIn(Map map, Iterable path, _KEY key, dynamic value) {
  map = _findIn(map, path, create: true);
  map.containsKey(_controllers) ?
        (map[_controllers] as List).add(value)
      :
        (map[_controllers] = [value]);
}

_removeIn(Map map, Iterable path, _controllers) {
  throw 'Unsupported';
}

class _KEY { String name; _KEY(this.name); toString() => name; }
final _controllers = new _KEY('controlllers');
final _changed = new _KEY('changed');
final _none = new _KEY('none');
