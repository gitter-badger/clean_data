part of clean_data;

isActive(StreamController sc) {
  return sc!=null && !sc.isClosed;
}

abstract class ChangeNotificationsMixin {

  /**
   * Controlls notification streams. Used to propagate change events to the outside world.
   */
  StreamController<dynamic> _onChangeController;

  StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

  /**
   * [_change] and [_changeSync] are either of a type Change or ChangeSet depending
   * on concrete implementation of a mixin
   */
  get _change;
  get _changeSync;

  /**
   * following wanna-be-abstract methods must be overriden
   */
  void _clearChanges();
  void _clearChangesSync();
  void _onBeforeNotify() {}

  /**
   * Used to propagate change events to the outside world.
   */
  StreamController<dynamic> _onBeforeAddedController;
  StreamController<dynamic> _onBeforeRemovedController;

  /**
   * Stream populated with [DataMapView] events before any
   * data object is added.
   */
   Stream<dynamic> get onBeforeAdd {
     if(_onBeforeAddedController == null) {
       _onBeforeAddedController =
           new StreamController.broadcast(sync: true);
     }
     return _onBeforeAddedController.stream;
   }

  /**
   * Stream populated with [DataMapView] events before any
   * data object is removed.
   */
   Stream<dynamic> get onBeforeRemove {
     if(_onBeforeRemovedController == null) {
       _onBeforeRemovedController =
           new StreamController.broadcast(sync: true);
     }
     return _onBeforeRemovedController.stream;
   }



  /**
   * Stream populated with [ChangeSet] events whenever the collection or any
   * of data object contained gets changed.
   */
  Stream<List> get onChange {
    if(_onChangeController == null) {
      _onChangeController =
          new StreamController.broadcast();
    }
    return _onChangeController.stream;
  }

  /**
   * Stream populated with {'change': [List], 'author': [dynamic]} events
   * synchronously at the moment when the collection or any data object contained
   * gets changed.
   */
  Stream<Map> get onChangeSync => _onChangeSyncController.stream;


  /**
   * Streams all new changes marked in [_change].
   */
  void _notify({author: null}) {
    if (_changeSync != null) {
      _onChangeSyncController.add({'author': author, 'change': _changeSync});
      _clearChangesSync();
    }

    Timer.run(() {
      if (_change != null) {
        _onBeforeNotify();
        if(isActive(_onChangeController)) _onChangeController.add(_change);
        _clearChanges();
      }
    });
  }

  void _closeChangeStreams(){
    if(isActive(_onChangeController)) _onChangeSyncController.close();
  }

}

abstract class ChangeChildNotificationsMixin implements ChangeNotificationsMixin {
  /**
   * Holds pending changes.
   */

  Set _change;
  Set _changeSync;

  /**
   * Internal set of listeners for change events on individual data objects.
   */
  Map<dynamic, StreamSubscription> _dataListeners;

  _clearChanges() {
    _change = null;
    _changeSync = null;
  }

  _clearChangesSync() {
    _changeSync = null;
  }

  _markChanged(dynamic key, {bool added: false, bool removed: false}) {
    if(added && isActive(_onBeforeAddedController))
        _onBeforeAddedController.add(key);
    if(removed && isActive(_onBeforeRemovedController)) {
        _onBeforeRemovedController.add(key);
    }
    if(_change==null) _change = new Set();
    if(_changeSync==null) _changeSync = new Set();
    _change.add(key);
    _changeSync.add(key);
  }

  /**
   * Starts listening to changes on [dataObj].
   */
  void _addOnDataChangeListener(key, dataObj) {
    if (_dataListeners == null){
      _dataListeners = {};
    }
    if (_dataListeners.containsKey(key)) {
      throw new Exception('Re-adding listener on key: $key, with dataObj: $dataObj in: $this.');
    }

    _dataListeners[key] = dataObj.onChangeSync.listen((changeEvent) {
      _markChanged(key);
      _notify(author: changeEvent['author']);
    });
  }

  void _removeOnDataChangeListener(key) {
    if (_dataListeners == null){
      return;
    }
    if (_dataListeners.containsKey(key)) {
      _dataListeners[key].cancel();
      _dataListeners.remove(key);
    }
  }

  void _dispose() {
    _closeChangeStreams();
    if(isActive(_onBeforeAddedController)) _onBeforeAddedController.close();
    if(isActive(_onBeforeRemovedController)) _onBeforeRemovedController.close();
    if(_dataListeners != null) _dataListeners.forEach((K, V) => V.cancel());
  }
}

const notNullValue = const [];

abstract class ChangeValueNotificationsMixin implements ChangeNotificationsMixin {
  var _change;
  var _changeSync;

  _clearChanges() {
    _change = null;
  }

  _clearChangesSync() {
    _changeSync = null;
  }

  _markChanged() {
    _changeSync = notNullValue;
    _change = notNullValue;
  }

  void _dispose(){
    _closeChangeStreams();
  }
}
