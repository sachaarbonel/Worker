import 'dart:async';
import 'package:worker/worker.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  final worker = new Worker(poolSize: 4, spawnLazily: false);
  var futures = <Future>[];
  
  for (var i in ["https://swapi.co/api/people/1","https://swapi.co/api/people/2","https://swapi.co/api/people/3"]) {
    futures.add(worker.handle(AsyncHttpGet(i)));
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