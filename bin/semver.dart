import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:semver_tool/semver_tool.dart';

main(List<String> arguments) async {
  final commandRunner = CommandRunner<String>('semver', 'Manage your semantic versions')
    ..addCommand(IncrementCommand());
  try {
    final res = await commandRunner.run(arguments);
    if (res?.isNotEmpty ?? false) {
      print(res);
    }
  } on UsageException catch (usage) {
    print(usage);
    exitCode = 1;
  }
}
