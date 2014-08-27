// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library misc_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';


void main() {

    test('disposing ref', () {
          var x = new DataReference(5);
          var ss = x.onChange.listen((_) => null);
          x.value = 5;
          x.dispose();
          ss.cancel();
        return new Future.delayed(new Duration(milliseconds: 100));
    });

}