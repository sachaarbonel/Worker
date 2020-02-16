library worker.test.stress;

import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:worker2/worker2.dart';
import 'package:test/test.dart';
import 'common.dart';

void main () {
  group("Stress test:", () {
    Worker worker;

    setUp(() {
      worker = new Worker();
    });

    tearDown(() {
      worker.close();
    });

    test("Run single long running task", () {
      CancelableCompleter token = CancelableCompleter();
      var future = worker.handle(new LongRunningTask(),token);

      expect(future, completes);
    });

    test("Run one long running task for each processor", () {
      var futures = <Future>[];
      CancelableCompleter token = CancelableCompleter();
      for (var i = 0; i < Platform.numberOfProcessors; i++) {
        futures.add(worker.handle(new LongRunningTask(),token));
      }

      expect(Future.wait(futures), completes);
    });

    test("Run more long running tasks than available processors", () {
      var futures = <Future>[];
      CancelableCompleter token = CancelableCompleter();

      for (var i = 0; i < Platform.numberOfProcessors *2; i++) {
        futures.add(worker.handle(new LongRunningTask(),token));
      }

      expect(Future.wait(futures), completes);
    });
  });
}
