// tinyeval worker: evals/support.sh starts it with `worker dart run bin/evalworker.dart`.
// It reads each input up to a NUL byte on stdin, and prints the reply and a NUL byte.
import 'dart:convert';
import 'dart:io';

import 'package:support/support.dart';

Future<void> main() async {
  final support = Support(); // once per worker, not once per test case
  var rest = <int>[];
  await for (final chunk in stdin) {
    rest.addAll(chunk);
    for (var i = rest.indexOf(0); i >= 0; i = rest.indexOf(0)) {
      final input = utf8.decode(rest.sublist(0, i));
      rest = rest.sublist(i + 1);
      stdout.add([...utf8.encode(await reply(support, input)), 0]);
      await stdout.flush();
    }
  }
}

/// The bot's reply to [input]. When the call fails for a reason that isn't the
/// app's fault, tinyeval counts it as couldn't run instead of failed.
Future<String> reply(Support support, String input) async {
  try {
    return await support.answer(input);
  } on ApiException catch (e) {
    final status = e.statusCode;
    if (status == 401 || status == 429 || status >= 500) return couldntRun(e);
    return 'error: $e'; // a 400 or 404 comes from the request the app built
  } on Exception catch (e) {
    return couldntRun(e); // no key, the network, a timeout or a broken response
  }
}

String couldntRun(Exception e) =>
    '#tinyeval couldnt_run ${'$e'.replaceAll('\n', ' ')}\n';
