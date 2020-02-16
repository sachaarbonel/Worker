library worker.test.execution;

import 'package:async/async.dart';
import 'package:worker2/worker2.dart';
import 'package:test/test.dart';
import 'common.dart';

void main () {
  group('Task execution:', () {
    Worker worker;
    Task task;
    CancelableCompleter token;
    CancelableCompleter token2;

    setUp(() {
      worker = new Worker(poolSize: 1);
      token = CancelableCompleter();
      token2 = CancelableCompleter();
    });

    tearDown(() {
      worker.close();
    });

    test('of sync task', () {
      task = new AddTask(1, 2);

      worker.handle(task,token).then(expectAsync1((result) {
        expect(result, equals(3));
      }));
    });

    test('of sync task with exception', () {
      task = new AddTask(1, 2, throwException: true);


      worker.handle(task,token).then(
          (result) {},
      onError: expectAsync1(
          (error) => expect(error, isNotNull)));
    });

    test('of async task', () {
      task = new AsyncAddTask(3, 2);

      worker.handle(task,token).then(expectAsync1((result) {
        expect(result, equals(5));
      }));
    });

    test('of async task with exception', () {
      task = new AsyncAddTask(1, 2, throwException: true);

      worker.handle(task,token).then(
          (result) {},
          onError: expectAsync1(
              (error) => expect(error, isNotNull))
      );

    });

    test('of task with error', () {
      task = new ErrorTask();

      worker.handle(task,token).then(
          (result) {},
          onError: expectAsync2((error, stackTrace) {
            expect(error, isNotNull);
            expect(stackTrace, TypeMatcher<StackTrace>());
          })
      );

    });

    test('of task with no return', () {
      task = new NoReturnTask();

      var future = worker.handle(task,token);

      expect(future, completes);
    });

    test('wait for tasks to be completed', () {
      var task1 = new LongRunningTask();
      var task2 = new LongRunningTask();

      var future1 = worker.handle(task1,token);
      var future2 = worker.handle(task2,token);
      var closeFuture = worker.close(afterDone: true);

      expect(future1, completes);
      expect(future2, completes);
      expect(closeFuture, completes);
    });

    test('does not wait for tasks to be completed', () {
      var task1 = new LongRunningTask();
      var task2 = new LongRunningTask();

      var future1 = worker.handle(task1,token);
      var future2 = worker.handle(task2,token);
      var closeFuture = worker.close(afterDone: false);

      expect(future1, throwsA(TypeMatcher<TaskCancelledException>()));
      expect(future2, throwsA(TypeMatcher<TaskCancelledException>()));
      expect(closeFuture, completes);
    });

  });
}
