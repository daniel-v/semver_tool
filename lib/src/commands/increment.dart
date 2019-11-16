import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:version/version.dart';

import '../extensions.dart';

Stream<List<int>> _fallbackReadStream = stdin;

@visibleForTesting
set fallbackReadStream(Stream<List<int>> val) {
  _fallbackReadStream = val;
}

class IncrementCommand extends Command<String> {
  @override
  String get description => 'Increment specific part of version';

  @override
  String get name => 'inc';

  @override
  FutureOr<String> run() async {
    final options = argResults.options;
    final requiredFlag = ['major', 'minor', 'patch'];
    bool hasAny = requiredFlag.any((opt) => argResults.wasParsed(opt));
    if (!hasAny) {
      usageException('must specify at least one of major, minor, patch');
    }
    if (options.isEmpty) {
      usageException('must specify at least one option');
    }
    String versionOpt = argResults['version'];
    if (versionOpt?.isEmpty ?? true) {
      // try to read stdin
      final stdinCompleter = Completer<String>();
      StreamSubscription<String> stdinSub;
      stdinSub = _fallbackReadStream.transform(systemEncoding.decoder).listen(
        (data) {
          if (!stdinCompleter.isCompleted) {
            stdinCompleter.complete(data.trim());
          }
          stdinSub.cancel();
        },
        cancelOnError: true,
      );
      Timer timeoutTimer;
      timeoutTimer = Zone.current.createTimer(Duration(milliseconds: 50), () {
        timeoutTimer.cancel();
        if (!stdinCompleter.isCompleted) {
          stdinCompleter.completeError(TimeoutError('No stdin value arrived within 50ms'));
        }
      });
      try {
        versionOpt = await stdinCompleter.future;
      } on TimeoutError {
        usageException('must specify version or pipe version string into semver');
      } catch (e) {
        rethrow;
      } finally {
        await stdinSub.cancel();
      }
    }
    String versionPrefix = '';
    versionOpt = versionOpt.replaceFirstMapped(_vPrefix, (match) {
      versionPrefix = match.group(0);
      return '';
    });
    final version = Version.parse(versionOpt);
    Version newVer;
    if (argResults['major']) {
      newVer = version.incrementMajor();
    } else if (argResults['minor']) {
      newVer = version.incrementMinor();
    } else if (argResults['patch']) {
      newVer = version.incrementPatch();
    }
    if (!argResults['clean']) {
      newVer = newVer.copyWith(preRelease: version.preRelease, build: version.build);
    }
    final String optPreRelease = argResults['pre-release'];
    if (!isNullOrBlank(optPreRelease)) {
      newVer = newVer.copyWith(preRelease: <String>[optPreRelease.trim()]);
    }
    newVer = newVer.copyWith(build: argResults['build-no']);
    return '$versionPrefix$newVer';
  }

  IncrementCommand() {
    argParser
          ..addOption('version', abbr: 'v', help: 'SemVer in format of 0.0.0 or v0.0.0')
          ..addOption('pre-release', abbr: 'r', help: 'Pre-release info to append to version')
          ..addOption('build-no', abbr: 'n', help: 'Build number to appen to version')
          ..addFlag('clean', abbr: 'c', negatable: true, defaultsTo: true, help: 'Removes pre-release and build info')
          ..addFlag('major', abbr: 'm', negatable: false)
          ..addFlag('minor', abbr: 'i', negatable: false)
          ..addFlag('patch', abbr: 'p', negatable: false) //
        ;
  }

  static final _vPrefix = RegExp('^[vV]');
}

class TimeoutError extends Error {
  final String message;

  TimeoutError(this.message);

  @override
  String toString() => 'TimeoutError: $message';
}
