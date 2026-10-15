import 'dart:math';

// One shared id generator for local models (records, profiles):
// timestamp micros plus a small random suffix. Not a UUID — the cloud
// table's client_id column is plain text, so any unique string works.
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';
