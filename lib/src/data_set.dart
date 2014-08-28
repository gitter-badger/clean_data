// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

typedef bool DataTestFunction(d);
typedef dynamic DataTransformFunction(d);

/**
 * Observable set of data objects that allows for read-only operations.
 *
 * By observable we mean that changes to the contents of the set (data addition / change / removal)
 * are propagated to registered listeners.
 */
abstract class DataSetView<V> extends Object
               with IterableMixin<V>, ChangeNotificationsMixin, ChangeChildNotificationsMixin
               implements Iterable<V> {

  Iterator<V> get iterator => _data.iterator;

  /**
   * Holds data view objects for the set.
   */
  final Set _data = new Set();

  int get length => _data.length;

// ============================ index ======================

  /**
   * The index on columns that speeds up retrievals and removals by property value.
   */
  final Map<String, HashIndex> _index = new Map<String, HashIndex>();
  StreamSubscription _indexListenerSubscription;

  /**
   * Adds indices on chosen properties. Indexed properties can be
   * used to retrieve data by their value with the [findBy] method,
   * or removed by their value with the [removeBy] method.
   */
  void addIndex([Iterable<String> indexedProps]) {

    if (indexedProps != null) {
      // initialize change listener; lazy
      if (_index.keys.length == 0) {
         _initIndexListener();
      }

      for (String prop in indexedProps) {
        if (!_index.containsKey(prop)) {
          // create and initialize the index
          _index[prop] = new HashIndex();
          _rebuildIndex(prop);
        }
      }
    }
  }

  /**
   * (Re)indexes all existing data objects into [prop] index.
   */
  void _rebuildIndex(String prop) {
    return;
//    for (dynamic d in this) {
//      if (d is DataMapView && d.containsKey(prop)) {
//        _index[prop].add(d[prop], d);
//      }
//    }
  }

  /**
   * Starts listening synchronously on changes to the set
   * and rebuilds the indices accordingly.
   */
  void _initIndexListener() {

    // TODO: think about this.
    _indexListenerSubscription = this.onChangeSync.listen((Map changes) {
      Set cs = changes['change'];

      // scan for each indexed property and reindex changed items
      for (String indexProp in _index.keys) {
        //TODO: do something
      }
    });
  }

  /**
   * Finds all objects that have [property] equal to [value] in this set.
   */
  Iterable<DataMapView> findBy(String property, dynamic value) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }
    return _data.where((e) =>  e is Map  && e[property] == value);
  }

  // ============================ /index ======================

  final StreamController_onBeforeAddedController =
      new StreamController.broadcast(sync: true);
  final StreamController _onBeforeRemovedController =
      new StreamController.broadcast(sync: true);

  /**
   * Returns true if this set contains the given [dataObj].
   *
   * @param dataObj Data object to be searched for.
   */
  bool contains(V dataObj) => _data.contains(dataObj);

  void unattachListeners() {
    _onChangeController.close();
  }

  /**
   * Stream all new changes marked in [ChangeSet].
   */

  void dispose() {
    _dispose();
    if (_indexListenerSubscription != null) {
      _indexListenerSubscription.cancel();
    }
  }

  String toString() => toList().toString();

  void _addAll(Iterable elements, {author: null}){
    elements.forEach((data) {
      var cdata = cleanify(data);
      if(!_data.contains(cdata)){
        _markChanged(cdata, added: true);
        _data.add(cdata);
        if(cdata is ChangeNotificationsMixin) {
          _addOnDataChangeListener(cdata, cdata);
        }
      }
    });
    _notify(author: author);
  }

  void _silentAddAll(Iterable elements, {author: null}){
    elements.forEach((data) {
      var cdata = cleanify(data);
      if(!_data.contains(cdata)){
        _data.add(cdata);
        if(cdata is ChangeNotificationsMixin) {
          _addOnDataChangeListener(cdata, cdata);
        }
      }
    });
  }


  void _removeAll(Iterable toBeRemoved, {author: null}) {
    toBeRemoved.forEach((data) {
      if (_data.contains(data)) {
        _markChanged(data, removed: true);
        if (data is ChangeNotificationsMixin) {
          _removeOnDataChangeListener(data);
        }
      }
    });
    _data.removeAll(toBeRemoved);
    _notify(author: author);
  }
}

/**
 * Set
 */
class DataSet<V> extends DataSetView<V>
                      implements Set<V> {

  /**
   * Creates an empty set.
   */
  DataSet() {
  }

  /**
   * Generates Set from [Iterable] of [data].
   */
  factory DataSet.from(Iterable<V> data) {
    var set = new DataSet<V>();
    set._silentAddAll(data);
    return set;
  }


  /**
   * Appends the [dataObj] to the set. If the element
   * was already in the set, [false] is returned and
   * nothing happens.
   */

  bool add(V dataObj, {author: null}) {
    var res = !_data.contains(dataObj);
    this._addAll([dataObj], author: author);
    return res;
  }


  /**
   * Appends all [elements] to the set.
   */
  void addAll(Iterable<V> elements, {author: null}) {
    this._addAll(elements, author: author);
  }

  /**
   * Removes multiple data objects from the set.
   */
  void removeAll(Iterable<V> toBeRemoved, {author: null}) {
    this._removeAll(toBeRemoved, author: author);
  }


  /**
   * Removes a data object from the set.  If the object was not in
   * the set, returns [false] and nothing happens.
   */
  bool remove(V dataObj, {author: null}) {
    var res = _data.contains(dataObj);
    this._removeAll([dataObj], author: author);
    return res;
  }

  /**
   * Removes all objects that have [property] equal to [value] from this set.
   */
  void removeBy(String property, V value, {author: null}) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }

    this._removeAll(findBy(property, value).toList(), author: author);
  }

  /**
   * Removes all objects satisfying filter [test]
   */
  void _removeWhere(DataTestFunction test, {author: null}) {
    List toBeRemoved = [];
    for (var dataObj in _data) {
      if(test(dataObj)) {
        toBeRemoved.add(dataObj);
      }
    }
    this._removeAll(toBeRemoved, author: author);
  }

  void removeWhere(DataTestFunction test, {author: null}) {
    _removeWhere(test, author:author);
  }


  lookup(Object object) => _data.lookup(object);

  bool containsAll(Iterable<V> other) => _data.containsAll(other);

  void retainWhere(bool test(V element), {author: null}) {
    this._removeWhere((data) => !test(data), author: author);
  }

  void retainAll(Iterable<V> elements, {author: null}) {
    var toKeep = new Set.from(elements);
    this._removeWhere((data) => !toKeep.contains(data), author:author);
  }

  Set difference(Set<V> other) => _data.difference(other);
  Set intersection(Set<V> other) => _data.intersection(other);
  Set union(Set<V> other) => _data.union(other);

  /**
   * Removes all data objects from the set.
   */
  void clear({author: null}) {
    // we shallow copy _data to avoid concurent modification of
    // the _data field during removal
    this._removeAll(new List.from(this._data), author:author);
  }

  void dispose() {
    super.dispose();
    if (_dataListeners != null) {
      _dataListeners.forEach((data, subscription) => subscription.cancel());
    }
  }
}
