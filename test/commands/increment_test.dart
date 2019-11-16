import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:semver_tool/semver_tool.dart';
import 'package:test/test.dart';

main() {
  Runner<String> runner;
  setUp(() {
    runner = run(IncrementCommand());
  });
  tearDown(() {
    fallbackReadStream = stdin;
  });
  test('should increment without v prefix', () async {
    final args = 'inc -m -v 1.2.3';
    final version = await runner(args);
    expect(version, '2.0.0');
  });
  test('should increment with case-sensitive v prefix', () async {
    expect(await runner('inc -m -v v1.2.3'), 'v2.0.0');
    expect(await runner('inc -m -v V1.2.3'), 'V2.0.0');
  });
  test('should ignore other v in string', () async {
    final args = 'inc -m --no-clean -v 1.2.3-ver+5';
    final version = await runner(args);
    expect(version, '2.0.0-ver+5');
  });
  test('should ignore other v in string', () async {
    final args = 'inc -m --no-clean -v 1.2.3-ver+5';
    final version = await runner(args);
    expect(version, '2.0.0-ver+5');
  });
  test('should use stdin when no -v provided', () async {
    fallbackReadStream = Stream<List<int>>.fromIterable(['1.2.3-ver+5'.codeUnits]);
    final version = await runner('inc -i --no-clean');
    expect(version, '1.3.0-ver+5');
  });
}

typedef Future<T> Runner<T>(String args);

Runner<R> run<R>(Command<R> command) {
  final runner = CommandRunner<R>('test', '')..addCommand(command);
  return (String args) {
    return runner.run(args.split(' '));
  };
}
