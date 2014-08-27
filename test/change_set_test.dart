// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library change_set_test;

import 'package:unittest/unittest.dart';
import 'package:mock/mock.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(json apply)', () {
    test('change, add, remove in datamap', () {
      Map json = { 'add': [CLEAN_UNDEFINED, 'value'],
        'change' : ['oldValue', 'newValue'],
        'remove' : ['value', CLEAN_UNDEFINED]
      };

      DataMap map = new DataMap.from({
        'change': 'oldValue',
        'remove': 'value'
      });
      applyJSON(json, map);

      expect(map, equals({
        'add': 'value',
        'change': 'newValue'
      }));
    });

    test('change and add in datalist', () {
      Map json = { '1': [CLEAN_UNDEFINED, 'add'],
        '0' : ['oldValue', 'newValue'],
      };
      DataList list = new DataList.from(['oldValue']);

      applyJSON(json, list);

      expect(list, equals(['newValue', 'add']));
    });

    test('change and remove in datalist', () {
      Map json = { '1': ['remove', CLEAN_UNDEFINED],
        '0' : ['oldValue', 'newValue'],
      };
      DataList list = new DataList.from(['oldValue', 'remove']);

      applyJSON(json, list);

      expect(list, equals(['newValue']));
    });

    test('remove to elements at once in list', () {
      Map json = { '1': ['remove', CLEAN_UNDEFINED],
        '0' : ['oldValue', CLEAN_UNDEFINED],
        '2' : ['oldValue', CLEAN_UNDEFINED],
      };
      DataList list = new DataList.from(['value', 'oldValue', 'remove', 'toRemove']);

      applyJSON(json, list);
      expect(list, equals(['value']));
    });

    test('changes, adds, remove in dataset', () {
      Map json = { 1: ['remove', CLEAN_UNDEFINED],
        2 : [{'_id': 2, 'change': 'oldValue'}, {'_id': 2, 'changeNew': 'newValue'}],
        3 : [CLEAN_UNDEFINED, {'_id': 3, 'new': null}]
      };

      DataSet set = new DataSet.from([{'_id': 1, 'remove': null},
         {'_id': 2, 'change': 'oldValue'}]);
      set.addIndex(['_id']);

      applyJSON(json, set);

      expect(set.toList(), unorderedEquals([{'_id': 3, 'new': null},
           {'_id': 2, 'changeNew': 'newValue'}]));
    });

    test('nested data on map', () {
      Map json = { 'a': {'b': ['old', 'new']}};

      DataMap map = new DataMap.from({'a': {'b': 'old', 'c': 'c'}});

      applyJSON(json, map);

      expect(map, equals({'a': {'b': 'new', 'c': 'c'}}));
    });

    test('nested data on list', () {
      Map json = { '0': {'b': ['old', 'new']}};

      DataList list = new DataList.from([{'b': 'old', 'c': 'c'}, 'second']);

      applyJSON(json, list);

      expect(list, equals([{'b': 'new', 'c': 'c'}, 'second']));
    });

    test('nested data on set', () {
      Map json = { '1': {'b': ['old', 'new']}};

      DataSet set = new DataSet.from([{'_id': '1', 'b': 'old', 'c': 'c'},
        {'_id': '2', 'b': 'other'}]);
      set.addIndex(['_id']);

      applyJSON(json, set);

      expect(set.toList(), equals([{'_id': '1', 'b': 'new', 'c': 'c'},
                                   {'_id': '2', 'b': 'other'}]));
    });


    test('propagates only changes that have truly happened. (map)', () {
      Map json = { 'a': ['b', 'd'] ,'c': ['c', 'e'], 'd': [CLEAN_UNDEFINED, 'k']} ;

      DataMap map = new DataMap.from({'a': 'd', 'c': 'c'});

      applyJSON(json, map);

      map.onChange.listen(expectAsync((Iterable changeSet) {
        expect(changeSet, unorderedEquals(['a', 'c', 'd']));
      }));
    });

    test('propagates only changes that have truly happened. (list)', () {
      Map json = { '0': {'b': ['old', 'new'], 'd': [CLEAN_UNDEFINED, 'd']}};

      DataList list = new DataList.from([{'b': 'old', 'c': 'c'}, 'second']);

      applyJSON(json, list);

      list.onChange.listen(expectAsync((Iterable changeSet) {
        expect(changeSet, equals([0]));
      }));
    });

    test('propagates only changes that have truly happened. (set)', () {
      Map json = { '1': {'b': ['old', 'new'], 'd': [CLEAN_UNDEFINED, 'd']}};

      DataSet set = new DataSet.from([{'_id': '1', 'b': 'old', 'c': 'c'},
        {'_id': '2', 'b': 'other'}]);
      set.addIndex(['_id']);

      applyJSON(json, set);

      set.onChange.listen(expectAsync((Iterable changeSet) {
        expect(changeSet, unorderedEquals([set.singleWhere((e) => e['_id'] == '1')]));
      }));
    });


  });
}
