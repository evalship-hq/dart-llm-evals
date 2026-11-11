// tinyeval worker: evals/support.sh starts it with `worker dart run bin/evalworker.dart`.
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:support/support.dart';
import 'package:tinyeval/tinyeval.dart';

final support = Support(); // built on the first input, once per worker

/// When the call fails for a reason that isn't the app's fault, tinyeval counts
/// the test case as couldn't run instead of failed. Any other exception, such
/// as a bug in the app's code, becomes the reply, so the eval fails.
Future<void> main() => worker((input) async {
  try {
    return await support.answer(input);
  } on ApiException catch (e) {
    final status = e.statusCode;
    if (status == 401 || status == 429 || status >= 500) throw CouldntRun('$e');
    rethrow; // a 400 or 404 comes from the request the app built
  } on NoKeyException catch (e) {
    throw CouldntRun('$e');
  } on TimeoutException catch (e) {
    throw CouldntRun('$e');
  } on http.ClientException catch (e) {
    throw CouldntRun('$e'); // the network
  } on SocketException catch (e) {
    throw CouldntRun('$e');
  }
});
