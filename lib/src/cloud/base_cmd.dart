import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:interact2/interact2.dart';

import '../utils/ansi.dart';
import '../utils/cli_log.dart';
import '../utils/project_config.dart';
import 'api/api_models.dart';
import 'api/cloud_api.dart';

enum Existence { mustExist, mustNotExist }

abstract class BaseCommand extends Command {
  final api = CloudApi();

  @override
  Future<void> run() async {
    if (await verifyAuthenticated()) {
      await runAuthenticated();
    }
  }

  Future<void> runAuthenticated() async {}

  Future<bool> verifyAuthenticated() async {
    final loggedIn = await api.isLoggedIn();
    if (!loggedIn) {
      CliLog.warn("You are not logged in.\n");
    }
    return loggedIn;
  }

  Future<Workspace> resolveWorkspace([String? workspaceName]) async {
    return (workspaceName != null
        ? await api.lookupWorkspace(workspaceName)
        : await selectWorkspace())!;
  }

  Future<Project> resolveProject({
    String? workspaceName,
    String? projectName,
    ProjectConfig? projectConfig,
  }) async {
    // try to resolve by names
    if (workspaceName != null || projectName != null) {
      final workspace = await resolveWorkspace(workspaceName);
      return (projectName != null
          ? await api.lookupProject(workspace.id, projectName)
          : await selectProject(workspace.id))!;
    }

    // get project id from config
    final projectCfg = projectConfig ?? ProjectConfig();
    final projectId = await projectCfg.getId();
    if (projectId != null) {
      return await api.getProject(
        projectId,
        errorContext: "Failed to retrieve configured project.",
      );
    }

    // prompt user to select a project
    final workspace = await resolveWorkspace();
    return await selectProject(workspace.id);
  }

  Future<Channel> resolveChannel(
    String projectId, {
    String? channelName,
    String? prompt,
    bool allowNew = false,
  }) async {
    // resolve channelId by name
    final channel = channelName != null
        ? await api.lookupChannel(projectId, channelName)
        : await selectChannel(projectId, prompt: prompt, allowNew: allowNew);
    return channel!;
  }

  Future<Workspace> selectWorkspace([String prompt = "Select workspace:"]) async {
    final workspaces = await api.getWorkspaces();

    if (workspaces.isEmpty) throw CanceledException("No workspaces for user.");
    if (workspaces.length == 1) return workspaces.first;

    // has multiple workspaces, pick one
    final index = Select(
      prompt: prompt,
      options: workspaces.map((e) => e.name).toList(),
      initialIndex: 0, // optional, will be 0 by default
    ).interact();

    CliLog.resetBlankLines();
    return SelectedWorkspace(index, workspaces);
  }

  Future<Project> selectProject(String workspaceId, [String prompt = "Select project:"]) async {
    final projects = await api.getProjects(workspaceId);

    if (projects.isEmpty) throw CanceledException("No projects for workspace.");
    if (projects.length == 1) return projects.first;

    // has multiple workspaces, pick one
    final index = Select(
      prompt: prompt,
      options: projects.map((e) => e.name).toList(),
      initialIndex: 0, // optional, will be 0 by default
    ).interact();

    CliLog.resetBlankLines();
    return SelectedProject(index, projects);
  }

  Future<String> inputProjectName(
    String workspaceId, {
    String prompt = "Project name:",
    Existence? existence,
  }) async {
    final newName = await AsyncInput(
      prompt: prompt,
      validator: (input) async {
        final value = input.trim();
        if (value.isEmpty) {
          throw ValidationError("Project name is required.");
        }
        if (value.length > 64) {
          throw ValidationError("Project name exceeds max length of 64 characters.");
        }
        if (existence != null) {
          final existing = await api.lookupProject(workspaceId, value, mustExist: false);
          if (existing != null && existence == Existence.mustNotExist) {
            throw ValidationError("A project named '$value' already exists.");
          }
          if (existing == null && existence == Existence.mustExist) {
            throw ValidationError("Project '$value' does not exist.");
          }
        }
        return true;
      },
    ).interact();

    CliLog.resetBlankLines();
    return newName.trim();
  }

  Future<Channel> selectChannel(String projectId, {String? prompt, bool allowNew = false}) async {
    final channels = await api.getChannels(projectId);

    if (channels.isEmpty) {
      if (allowNew) {
        return await createNewChannel(projectId);
      }
      throw CanceledException("No channels for project.");
    } else {
      final options = channels.map((e) => e.name).toList();
      if (allowNew) options.add("Create a new channel");

      final index = Select(
        prompt: prompt ?? "Select channel:",
        options: options,
        initialIndex: 0, // optional, will be 0 by default
      ).interact();

      CliLog.resetBlankLines();
      if (index >= channels.length) {
        return await createNewChannel(projectId);
      } else {
        return channels[index];
      }
    }
  }

  Future<Channel> createNewChannel(
    String projectId, [
    String prompt = "Create a new channel:",
  ]) async {
    final name = await inputChannelName(
      projectId,
      prompt: prompt,
      existence: Existence.mustNotExist,
    );
    CliLog.resetBlankLines();

    final id = await api.createChannel(projectId, name);
    return Channel(id: id, name: name);
  }

  Future<String> inputChannelName(
    String projectId, {
    String prompt = "Channel name:",
    Existence? existence,
  }) async {
    final name = await AsyncInput(
      prompt: prompt,
      validator: (input) async {
        final value = input.trim();
        if (value.isEmpty) {
          throw ValidationError("Channel is required.");
        }
        if (value.length > 30) {
          throw ValidationError("Must be 30 characters or less.");
        }
        final allowed = RegExp(r'^[A-Za-z0-9_\-]+$');
        if (!allowed.hasMatch(value)) {
          throw ValidationError(
            "Only letters, numbers, hyphens, "
            "and underscores allowed.",
          );
        }
        if (existence != null) {
          final existing = await api.lookupChannel(projectId, value, mustExist: false);
          if (existing != null && existence == Existence.mustNotExist) {
            throw ValidationError("A channel named '$value' already exists.");
          }
          if (existing == null && existence == Existence.mustExist) {
            throw ValidationError("Channel '$value' does not exist.");
          }
        }
        return true;
      },
    ).interact();

    CliLog.resetBlankLines();
    return name.trim();
  }

  Future<String?> inputVersion({
    String? initialText,
    String? defaultValue,
    bool isRequired = false,
    dynamic Function(String)? validator,
  }) async {
    final asyncInput = AsyncInput(
      prompt: 'Deployment version:',
      defaultValue: defaultValue,
      initialText: initialText ?? "",
      validator: (input) async {
        final value = input.trim();
        if (isRequired && value.isEmpty) {
          throw ValidationError("Version is required.");
        }
        if (value.isNotEmpty) {
          if (value.length > 50) {
            throw ValidationError("Version must be <= 50 characters.");
          }
          if (!isValidVersion(value)) {
            throw ValidationError(
              "Version must be of the format "
              "{major}.{minor}.{patch}[-{prerelease}][+{build_number}]",
            );
          }
        }
        if (validator != null) {
          await validator(value);
        }
        return true;
      },
    );

    CliLog.resetBlankLines();
    final version = await asyncInput.interact();
    final value = version.trim();
    // validate + normalize (strips leading zeros to canonical form)
    return value.isEmpty ? null : normalizeVersion(value);
  }

  Future<String?> inputRevision({
    String? initialText,
    String? defaultValue,
    bool isRequired = false,
    dynamic Function(String)? validator,
  }) async {
    final asyncInput = AsyncInput(
      prompt: 'Deployment revision:',
      defaultValue: defaultValue,
      initialText: initialText ?? "",
      validator: (input) async {
        final value = input.trim();
        if (isRequired && value.isEmpty) {
          throw ValidationError("Revision is required.");
        }
        if (value.isNotEmpty) {
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            throw ValidationError("Revision must contain only digits.");
          }
          // tryParse returns null on overflow (value exceeds max int)
          final revision = int.tryParse(value);
          if (revision == null) {
            throw ValidationError("Revision is too large.");
          }
          if (revision < 0) {
            throw ValidationError("Revision must be >= 0.");
          }
        }
        if (validator != null) {
          await validator(value);
        }
        return true;
      },
    );

    CliLog.resetBlankLines();
    final revision = await asyncInput.interact();
    final value = revision.trim();
    return value.isEmpty ? null : value;
  }

  /// Validates and normalizes a version string.
  ///
  /// Accepts {major}.{minor}.{patch}[-{prerelease}][+{build}] where the numeric
  /// parts may contain leading zeros (as Flutter/iOS/Android permit). Strips
  /// leading zeros from each numeric component so the stored form matches the
  /// device's canonical version (iOS treats 1.02.3 as 1.2.3). Throws on input
  /// that doesn't match the version format.
  String normalizeVersion(String version) {
    // build is numeric only; prerelease allows alphanumerics, dots, hyphens.
    // leading zeros permitted here and stripped below.
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+\d+)?$');
    if (!versionRegex.hasMatch(version)) {
      throw ValidationError('Invalid version format: "$version".');
    }

    // split off build (+) and prerelease (-) so only numeric parts are touched
    final buildSplit = version.split('+');
    final core = buildSplit[0];
    final build = buildSplit.length > 1 ? buildSplit[1] : null;

    final preSplit = core.split('-');
    final mmp = preSplit[0]; // major.minor.patch
    final prerelease = preSplit.length > 1 ? preSplit.sublist(1).join('-') : null;

    // strip leading zeros from each of major.minor.patch (preserve a lone zero)
    final normalizedCore = mmp
        .split('.')
        .map((part) => part.replaceFirst(RegExp(r'^0+(?=\d)'), ''))
        .join('.');

    // strip leading zeros from the numeric build (preserve a lone zero)
    final normalizedBuild = build?.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    var result = normalizedCore;
    if (prerelease != null) result += '-$prerelease';
    if (normalizedBuild != null) result += '+$normalizedBuild';
    return result;
  }

  bool isValidVersion(String version) {
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+\d+)?$');
    return versionRegex.hasMatch(version);
  }

  /// Returns the positional argument at [index], or null if not provided.
  String? positionalArg(int index) {
    final rest = argResults!.rest;
    return index < rest.length ? rest[index] : null;
  }

  /// Returns the required positional argument at [index].
  /// Throws [UsageException] if not provided.
  String requiredPositionalArg(int index, String name) {
    final value = positionalArg(index);
    if (value == null) {
      usageException('Missing required argument: <$name>');
    }
    return value;
  }

  void printTitle({
    String? user,
    Workspace? workspace,
    Project? project,
    String? channel,
    String? version,
  }) {
    String? title;
    if (user != null) {
      title = "${Ansi.bold}User: $user${Ansi.reset}";
    }
    if (workspace != null && workspace is! SelectedWorkspace) {
      title = "${Ansi.bold}Workspace: ${workspace.name}${Ansi.reset}";
    }
    if (project != null && project is! SelectedProject) {
      title = "${Ansi.bold}Project: ${project.name}${Ansi.reset}";
    }
    if (channel != null) {
      title = "${Ansi.bold}Channel: $channel${Ansi.reset}";
    } else if (version != null) {
      title = "${Ansi.bold}Version: $version${Ansi.reset}";
    }
    if (title != null) {
      CliLog.blankLine();
      CliLog.info(title);
      CliLog.blankLine();
    }
  }

  void printResults(
    List<Map<String, dynamic>> rows,
    Map<String, ({String label, String? value})> columns,
  ) {
    // Print filter headers
    final activeFilters = columns.entries.where((entry) => entry.value.value != null).toList();

    if (activeFilters.isNotEmpty) {
      final maxWidth = activeFilters
          .map((entry) => entry.value.label.length)
          .reduce((curr, next) => curr > next ? curr : next);

      for (final entry in activeFilters) {
        CliLog.bold('${entry.value.label.padRight(maxWidth)}: ${entry.value.value}');
      }
    }

    if (rows.isEmpty) {
      CliLog.info('\nNo data found.');
      return;
    }

    // Table columns are the ones with null values
    final tableColumns = columns.entries.where((e) => e.value.value == null).toList();

    final headers = tableColumns.map((e) => e.value.label).toList();
    final tableRows = rows
        .map((row) => tableColumns.map((e) => row[e.key]?.toString() ?? '').toList())
        .toList();

    printTable(headers, tableRows);
  }

  void printTable(List<String> headers, List<List<Object?>> rows, {int padding = 4}) {
    CliLog.blankLine();

    // Detect date columns
    final dateColumns = <int>{};
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      final lower = h.toLowerCase();
      if (h.endsWith('At') || lower.endsWith('_at')) {
        dateColumns.add(i);
      }
    }

    // Convert to strings, and format dates
    final stringRows = rows.map((row) {
      return List.generate(headers.length, (i) {
        if (i >= row.length || row[i] == null) return '';
        if (dateColumns.contains(i)) return _tryFormatDate(row[i]);
        var value = row[i].toString();
        return value;
      });
    }).toList();

    // Format headers
    final upperHeaders = headers.map(_formatHeader).toList();
    final separator = ''.padRight(padding);

    final widths = List.generate(upperHeaders.length, (i) {
      final maxData = stringRows.isEmpty
          ? 0
          : stringRows.map((r) => _visibleLength(r[i])).reduce((a, b) => a > b ? a : b);
      final headerLength = _visibleLength(upperHeaders[i]);
      return headerLength > maxData ? headerLength : maxData;
    });

    final header = [
      for (var i = 0; i < upperHeaders.length; i++) _padRightVisible(upperHeaders[i], widths[i]),
    ].join(separator);

    CliLog.info(header);
    for (final row in stringRows) {
      CliLog.info(
        [
          for (var i = 0; i < widths.length; i++) _padRightVisible(row[i], widths[i]),
        ].join(separator),
      );
    }
    CliLog.blankLine();
  }

  void printJson(List<dynamic> items) {
    final json = items.map((item) => item.toJson()).toList();
    print(JsonEncoder.withIndent('  ').convert(json));
  }

  String _formatHeader(String header) {
    return "${Ansi.bold}$header${Ansi.reset}";
  }

  String _tryFormatDate(dynamic epochMs) {
    if (epochMs == null) return '';
    final ms = int.tryParse(epochMs.toString());
    if (ms == null) return '';

    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int _visibleLength(String s) {
    return s.replaceAll(RegExp(r'\x1b\[[0-9;]*m'), '').length;
  }

  String _padRightVisible(String s, int width) {
    final extra = s.length - _visibleLength(s);
    return s.padRight(width + extra);
  }
}

class CanceledException implements Exception {
  final String message;

  CanceledException([this.message = "Canceled."]);

  @override
  String toString() => message;
}

class SelectedWorkspace extends Workspace {
  final int index;
  final List<Workspace> choices;

  SelectedWorkspace(this.index, this.choices)
    : super(id: choices[index].id, name: choices[index].name, roleId: choices[index].roleId);
}

class SelectedProject extends Project {
  final int index;
  final List<Project> choices;

  SelectedProject(this.index, this.choices)
    : super(
        id: choices[index].id,
        workspaceId: choices[index].workspaceId,
        name: choices[index].name,
        description: choices[index].description,
        createdAt: choices[index].createdAt,
        updatedAt: choices[index].updatedAt,
      );
}
