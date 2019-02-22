Worker
=====

An easy to use utility to perform tasks concurrently.

By performing blocking CPU intensive tasks concurrently, you free your main isolate 
to do other stuff while you take advantage of the CPU capabilities.

Usage
-----

To use this library, create a new Worker that will handle the isolates for you, 
encapsulate your task in class that implements the Task interface and pass it to the Worker 
to execute it:

```dart
void main () {
	Worker worker = new Worker();
	Task task = new AckermannTask(1, 2);
	worker.handle(task).then((result) => print(result));
}

class AckermannTask implements Task {
  int x, y;

  AckermannTask (this.x, this.y);

  int execute () {
    return ackermann(x, y);
  }

  int ackermann (int m, int n) {
    if (m == 0)
      return n+1;
    else if (m > 0 && n == 0)
      return ackermann(m-1, 1);
    else
      return ackermann(m-1, ackermann(m, n-1));
  }
}
```

You can also define how many tasks a worker can execute concurrently and if the isolates
should be spawned lazily:

```dart
Worker worker = new Worker(poolSize: 4, spawnLazily: false);
```
If you want to manage the isolates and SendPorts yourself but still use Tasks,
WorkerIsolate comes to the rescue:

```dart
WorkerIsolate isolate = new WorkerIsolate();
isolate.performTask(new AckermannTask(1, 2))
		.then(doSomethingAwesome);
```

You can perform multple http get requests in parallel for example :
```dart
import 'dart:async';
import 'package:worker2/worker2.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  final worker = new Worker(poolSize: 4, spawnLazily: false);
  var futures = <Future>[];
  
  for (var url in ["https://swapi.co/api/people/1","https://swapi.co/api/people/2","https://swapi.co/api/people/3"]) {
    futures.add(worker.handle(AsyncHttpGet(url)));
  }

  Future.wait(futures).then((r) {
    print(r);
    worker.close();
  });

}

Future<String> getUrl(String url) async {
  Completer completer = new Completer();
  StringBuffer contents = new StringBuffer();
  var request = await HttpClient().getUrl(Uri.parse(url));
  var response = await request.close(); 
 response.transform(utf8.decoder).listen((String data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return await completer.future;
}

class AsyncHttpGet implements Task<Future<String>> {
  String url;
  bool throwException;

  AsyncHttpGet (this.url, {this.throwException: false});

  Future<String> execute () {
    return getUrl(url);
  }
}
```

Tips
----
* A Task may return a Future. The Worker will wait until this Future is completed and will return its result.
* If you have to perform many iterations of an operation, you can batch it into tasks and run them concurrently.
* Running tasks in other isolates involves copying the task object to the other isolate. Keep your task thin.
* Always use benchmarks to identify if Worker is really helping and if the amount of isolates is ideal.
