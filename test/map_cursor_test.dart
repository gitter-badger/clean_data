// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map_cursor_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';


void main() {

  group('(MapCursor)',() {

    setUp((){});

    test('Dummy. (T01)', () {
      Reference ref = new Reference.from({'hello': { 'persistent': 'data'}});
      MapCursor hello = new MapCursor(ref, ['hello']);

      expect(hello.value, equals(ref.value.lookup('hello')));
    });

    test('Dummy. (T02)', () {
      Reference ref = new Reference.from({'hello': { 'persistent': 'data'}});
      MapCursor hello = new MapCursor(ref, ['hello']);
      String data = hello['persistent'];

      expect(data, equals('data'));
    });

    test('Dummy. (T03)', () {
      Reference ref = new Reference.from({'hello': { 'persistent': 'data'}});
      MapCursor map = new MapCursor(ref, []);
      String data = map['hello']['persistent'];

      expect(data, equals('data'));
    });

    test('Change. (T04)', () {
      Reference ref = new Reference.from({'hello': { 'persistent': 'data'}});
      MapCursor map = new MapCursor(ref, []);
      map['hello']['persistent'] = 'newData';

      expect(map['hello']['persistent'], equals('newData'));
    });

    test('Add. (T05)', () {
      Reference ref = new Reference.from({'hello': { 'persistent': 'data'}});
      MapCursor map = new MapCursor(ref, []);
      map['hello']['listenable'] = 'data';

      expect(map['hello']['listenable'], equals('data'));
    });

    test('Remove. (T05)', () {
      Reference ref = new Reference.from({'hello': { 'persistent': 'data'}});
      MapCursor map = new MapCursor(ref, []);
      map['hello'].remove('persistent');
      expect(() => map['hello']['persistent'], throws);
    });
  });
}