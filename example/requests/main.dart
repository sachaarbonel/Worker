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
  response.cast<List<int>>().transform(utf8.decoder).listen((String data) {
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
