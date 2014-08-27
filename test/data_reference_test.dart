// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_reference_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

void main() {

  group('(DataReference)', () {

    test('Getter (T01)', () {
      DataReference<String> ref = new DataReference<String>('value');
      expect(ref.value, 'value');
    });

    test('Dispose', (){
      DataReference<String> ref = new DataReference<String>('value');
      ref.dispose();
    });

    test('Setter (T02)', () {
      DataReference ref = new DataReference<String>('value');
      ref.value = 'newValue';
      expect(ref.value, 'newValue');
    });


    test('Listen on change (T03)', () {
      DataReference<String> ref = new DataReference('oldValue');

      ref.value = 'newValue';
      ref.onChange.listen(expectAsync((List change) {
        expect(change, isNotNull);
      }));
    });

    test('Correctly merge changes. (T04)', () {
      DataMap<String, String> d = new DataMap.from({'name': 'Bond. James Bond.'});
      var oldRef = d.ref('name');
      d['name'] = 'Guybrush';
      d.remove('name');
      d['name'] = 'Guybrush Threepwood';

      d.onChange.listen(expectAsync((change){
        expect(change, isNotNull);
      }));
    });

    test('Listen on changeSync (T05)', () {
      DataReference<String> ref = new DataReference<String>('oldValue');

      var check = expectAsync((event) {
        expect(event['change'], isNotNull);
      });

      ref.onChangeSync.listen(check);
      ref.value = 'newValue';
    });

    test('Listen on changes of value. (T06)', () {
      var data = new DataMap.from({'key': 'oldValue'});
      var dataRef = new DataReference<DataMap>(data);

      // when
      dataRef.value['key'] = 'semiNewValue';
      dataRef.value['key'] = 'newValue';

      // then
      dataRef.onChange.listen(expectAsync((Iterable event) {
        var ref = data.ref('key');
        expect(event, isNotNull);
      }));
    });


    test('Listen synchronyosly on changes of value. (T07)', () {
      //given
      var data = new DataMap.from({'key': 'oldValue'});
      var dataRef = new DataReference<DataMap>(data);
      var change;
      dataRef.onChangeSync.listen((event){
        change = event['change'];
      });

      // when
      dataRef.value['key'] = 'newValue';

      // then
      expect(change, isNotNull);
    });

    test('Listen synchronyosly on changes of value. (T08)', () {

      DataReference a = new DataReference(null);
      a.onChange.listen(expectAsync((change){
        expect(change, isNotNull);
      }));
      a.value = new DataMap.from({'daco':1});
      return new Future.delayed(new Duration(milliseconds: 20));
    });
  });
}