import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils/api.dart';
import '../../utils/browser.dart';
import '../../utils/cli_log.dart';
import '../../utils/files.dart';
import '../../utils/storage.dart';
import '../../utils/utils.dart';
import '../base_cmd.dart';
import 'api_models.dart';

const defaultStatusMessages = <int, String>{
  400: 'Invalid request',
  401: 'Not authenticated',
  403: 'You do not have permission',
  404: 'Resource not found',
  405: 'Method not allowed',
  409: 'Conflict',
  410: 'Resource no longer available',
  413: 'Upload too large',
  415: 'Unsupported media type',
  422: 'Invalid input',
  429: 'Too many requests. Please try again later',
};

class CloudApi extends RestApi {
  final storage = SecureStorage();

  CloudApi() : super(baseUrl: getApiUrl());

  static String getApiUrl() {
    final configFile = File('${Platform.environment['HOME']}/.xwidget/config.json');
    if (configFile.existsSync()) {
      try {
        final json = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final url = json['apiUrl'] as String?;
        if (url != null && url.isNotEmpty) return url;
      } catch (_) {}
    }
    return 'https://api.xwidget.dev';
  }

  //-----------------------------------
  // auth methods
  //-----------------------------------

  Future<String> getSessionId() async {
    final sessionId = await storage.get('sessionId');
    if (sessionId != null) return sessionId;
    throw CanceledException('You are not logged in. Run "cloud login".');
  }

  Future<bool> login(String provider) async {
    final callbackPath = '/callback';
    final callbackUri = Uri.parse('http://localhost:0$callbackPath');
    final server = await HttpServer.bind('127.0.0.1', 0);
    final completer = Completer<String>();

    // localhost callback handler
    Future<void> callbackHandler(HttpRequest request, Completer<String> completer) async {
      if (request.uri.path == callbackPath) {
        final sessionId = request.uri.queryParameters['dataSessionId'];

        if (sessionId != null) {
          final response = request.response
            ..headers.contentType = ContentType.html
            ..write(await Files.readFile('xwidget_builder|res/login-success.html'));
          // ..write(loginSuccess);
          await response.close();
          await response.done;
          completer.complete(sessionId);
          return;
        }
      }

      final code = request.uri.queryParameters['errorCode'];
      final message = request.uri.queryParameters['errorMessage'];
      final reason = message ?? code ?? 'Unknown error';
      final response = request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.html
        ..write(await Files.readFile('xwidget_builder|res/login-failed.html'));
      // ..write(loginFailed);
      await response.close();
      await response.done;
      completer.completeError(Exception(reason));
    }

    server.listen((request) async {
      await callbackHandler(request, completer);
      await server.close();
    });

    final authUrl = baseUri
        .resolve('/auth/login')
        .replace(
          queryParameters: {
            'client': 'cli',
            'provider': provider,
            'returnUrl': callbackUri.replace(port: server.port).toString(),
          },
        );

    try {
      await openInBrowser(authUrl.toString());
    } catch (e) {
      CliLog.warn(
        'Could not open browser for authentication: $e '
        '- Please visit $authUrl',
      );
    }

    try {
      final sessionId = await completer.future.timeout(
        Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Authentication timed out.'),
      );
      await storage.set('sessionId', sessionId);
      return true;
    } finally {
      await server.close(force: true);
    }
  }

  Future<void> logout() async {
    final sessionId = await storage.get('sessionId');
    if (sessionId == null) return;

    final res = await apiRequest(
      method: 'POST',
      path: '/auth/logout',
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Unable to logout.');
    await storage.delete('sessionId');
  }

  Future<String?> whoami() async {
    final sessionId = await storage.get('sessionId');
    if (sessionId == null) return null;

    final res = await apiRequest(
      method: 'GET',
      path: '/auth/whoami',
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    if (!res.ok) return null;

    final data = res.data['data'];
    return '"${data['name']}" <${data['email']}>';
  }

  Future<bool> isLoggedIn() async {
    final sessionId = await storage.get('sessionId');
    if (sessionId == null) return false;

    final res = await apiRequest(
      method: 'GET',
      path: '/auth/verify',
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    if (res.ok) return true;
    if (res.statusCode == 401) return false;

    throw CloudException('Authorization failed: ${res.statusMessage}.');
  }

  //-----------------------------------
  // workspace methods
  //-----------------------------------

  Future<List<Usage>> getWorkspaceUsage(String workspaceId) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/workspace/usages',
      queryParams: {'workspaceId': workspaceId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve workspace usages.');
    final List<dynamic> usages = res.data['data'];
    return usages.map((o) => Usage.fromJson(o)).toList();
  }

  Future<Workspace?> lookupWorkspace(String name, {bool strict = true}) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/lookup/workspace',
      queryParams: {'workspaceName': name, 'strict': strict},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve workspace "$name".');
    final workspace = res.data['data'];
    return workspace != null ? Workspace.fromJson(workspace) : null;
  }

  Future<List<Workspace>> getWorkspaces() async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/workspaces',
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve workspaces.');
    final List<dynamic> workspaces = res.data['data'];
    return workspaces.map((o) => Workspace.fromJson(o)).toList();
  }

  Future<void> renameWorkspace(String workspaceId, String name) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/workspace/rename',
      data: {'workspaceId': workspaceId, 'name': name},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to rename workspace to "$name".');
  }

  //-----------------------------------
  // project methods
  //-----------------------------------

  Future<Project?> lookupProject(String workspaceId, String name, {bool strict = true}) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/lookup/project',
      queryParams: {'workspaceId': workspaceId, 'projectName': name, 'strict': strict},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve project "$name".');
    final project = res.data['data'];
    return project != null ? Project.fromJson(project) : null;
  }

  Future<String> createProject(String workspaceId, String name, String? desc) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/projects',
      data: {'workspaceId': workspaceId, 'name': name, 'description': desc},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to create project "$name".');
    final projectId = res.data['data']['id'];
    if (projectId == null) throw CloudException('Missing "id" in response.');
    return projectId;
  }

  Future<void> renameProject(String projectId, String name) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/project/rename',
      data: {'projectId': projectId, 'name': name},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to rename project to "$name".');
  }

  Future<Project> getProject(String projectId, {String? errorContext}) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/project',
      queryParams: {'projectId': projectId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: errorContext ?? 'Failed to retrieve project.');
    return Project.fromJson(res.data['data']);
  }

  Future<ProjectKeys> getProjectKeys(String projectId, {String? errorContext}) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/project/keys',
      queryParams: {'projectId': projectId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: errorContext ?? 'Failed to retrieve project key.');
    return ProjectKeys.fromJson(res.data['data']);
  }

  Future<String> rotateProjectKey(String projectId, {int? graceDays, String? errorContext}) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/project/rotate-key',
      queryParams: {'projectId': projectId, 'graceDays': graceDays},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: errorContext ?? 'Failed to retrieve project key.');
    return res.data['data']['projectKey'];
  }

  Future<List<Project>> getProjects(String workspaceId) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/projects',
      queryParams: {'workspaceId': workspaceId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve projects.');
    final List<dynamic> projects = res.data['data'];
    return projects.map((p) => Project.fromJson(p)).toList();
  }

  Future<ProjectDeletes?> deleteProject(String projectId) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'DELETE',
      path: '/api/projects',
      queryParams: {'projectId': projectId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to delete project.');
    final deletes = res.data['data'];
    return deletes != null ? ProjectDeletes.fromJson(deletes) : null;
  }

  //-----------------------------------
  // channels methods
  //-----------------------------------

  Future<Channel?> lookupChannel(String projectId, String name, {bool strict = true}) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/lookup/channel',
      queryParams: {'projectId': projectId, 'channelName': name, 'strict': strict},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve channel "$name".');
    final channel = res.data['data'];
    return channel != null ? Channel.fromJson(channel) : null;
  }

  Future<String> createChannel(String projectId, String name) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/channels',
      data: {'projectId': projectId, 'channelName': name},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to create channel "$name".');
    final channelId = res.data['data']['id'];
    if (channelId == null) throw CloudException('Missing "id" in response.');
    return channelId;
  }

  Future<void> renameChannel(String channelId, String name) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/channel/rename',
      data: {'channelId': channelId, 'name': name},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to rename channel to "$name".');
  }

  Future<List<Channel>> getChannels(String projectId) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/channels',
      queryParams: {'projectId': projectId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve channels.');
    final List<dynamic> channels = res.data['data'];
    return channels.map((o) => Channel.fromJson(o)).toList();
  }

  Future<ChannelDeletes?> deleteChannel(String channelId) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'DELETE',
      path: '/api/channels',
      queryParams: {'channelId': channelId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to delete channel');
    final deletes = res.data['data'];
    return deletes != null ? ChannelDeletes.fromJson(deletes) : null;
  }

  Future<ChannelDeletes?> deleteChannelsByProject(String projectId) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'DELETE',
      path: '/api/channels',
      queryParams: {'projectId': projectId},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to delete channels for project.');
    final deletes = res.data['data'];
    return deletes != null ? ChannelDeletes.fromJson(deletes) : null;
  }

  //-----------------------------------
  // deployment methods
  //-----------------------------------

  Future<List<Deployment>> getDeployments({
    required String projectId,
    String? channelId,
    String? version,
    int limit = 10,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/deployments',
      queryParams: {
        'projectId': projectId,
        if (channelId != null) 'channelId': channelId,
        if (version != null) 'version': version,
        'limit': limit,
      },
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve deployments.');
    final List<dynamic> deployments = res.data['data'];
    return deployments.map((d) => Deployment.fromJson(d)).toList();
  }

  Future<Deployment?> getDeploymentSummary(
    String channelId,
    String version, {
    bool strict = true,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/deployment/summary',
      queryParams: {'channelId': channelId, 'version': version, 'strict': strict},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve deployment.');
    final data = res.data['data'];
    return data != null ? Deployment.fromJson(data) : null;
  }

  Future<Map<String, String>> createDeployment({
    required String channelId,
    required String version,
    required List<int> tarball,
    String? notes,
    bool activate = true,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiMultipart(
      path: '/api/deployments/deploy',
      queryParams: {'channelId': channelId},
      headers: {'Authorization': 'Bearer $sessionId'},
      fields: {
        'version': version,
        if (notes != null) 'notes': notes,
        'activate': activate.toString(),
      },
      file: tarball,
      filename: '$version.tar.gz',
    );

    checkResponse(res, context: 'Failed to create deployment.');

    final data = res.data['data'];
    return {'id': data['id'] as String};
  }

  Future<Map<String, dynamic>> promoteDeployment({
    required String fromChannelId,
    required String toChannelId,
    required String version,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'POST',
      path: '/api/deployments/promote',
      queryParams: {'fromChannelId': fromChannelId, 'toChannelId': toChannelId, 'version': version},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to promote deployment.');

    final data = res.data['data'];
    return {'id': data['id'] as String};
  }

  Future<void> deleteDeployments({String? projectId, String? channelId, String? version}) async {
    final sessionId = await getSessionId();

    if (projectId == null && channelId == null) {
      CloudException('Either "channel" or "project" is required');
    }

    final res = await apiRequest(
      method: 'DELETE',
      path: '/api/deployments',
      queryParams: {'projectId': projectId, 'channelId': channelId, 'version': version},
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to delete deployments for channel.');
  }

  //-----------------------------------
  // analytics methods
  //-----------------------------------

  Future<List<RenderAnalytics>> queryRenderEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String interval,
    String? projectId,
    String? channel,
    String? version,
    String? platform,
    String? fragment,
    String? locale,
    String? country,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/query/renders',
      queryParams: {
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
        'interval': interval,
        if (projectId != null) 'projectId': projectId,
        if (channel != null) 'channel': channel,
        if (version != null) 'version': version,
        if (platform != null) 'platform': platform,
        if (fragment != null) 'fragment': fragment,
        if (locale != null) 'locale': locale,
        if (country != null) 'country': country,
      },
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve render analytics.');
    final List<dynamic> results = res.data['data'];
    return results.map((r) => RenderAnalytics.fromJson(r)).toList();
  }

  Future<List<DownloadAnalytics>> queryDownloadEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String interval,
    String? projectId,
    String? channel,
    String? version,
    String? platform,
    String? locale,
    String? country,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/query/downloads',
      queryParams: {
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
        'interval': interval,
        if (projectId != null) 'projectId': projectId,
        if (channel != null) 'channel': channel,
        if (version != null) 'version': version,
        if (platform != null) 'platform': platform,
        if (locale != null) 'locale': locale,
        if (country != null) 'country': country,
      },
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve download analytics.');
    final List<dynamic> results = res.data['data'];
    return results.map((r) => DownloadAnalytics.fromJson(r)).toList();
  }

  Future<List<ErrorAnalytics>> queryErrorEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String interval,
    String? projectId,
    String? channel,
    String? version,
    String? platform,
    String? fragment,
    String? locale,
    String? country,
    String? error,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/query/errors',
      queryParams: {
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
        'interval': interval,
        if (projectId != null) 'projectId': projectId,
        if (channel != null) 'channel': channel,
        if (version != null) 'version': version,
        if (platform != null) 'platform': platform,
        if (fragment != null) 'fragment': fragment,
        if (locale != null) 'locale': locale,
        if (country != null) 'country': country,
        if (error != null) 'error': error,
      },
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve error analytics.');
    final List<dynamic> results = res.data['data'];
    return results.map((r) => ErrorAnalytics.fromJson(r)).toList();
  }

  Future<List<TransitionAnalytics>> queryPageTransitions({
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
    String? channel,
    String? version,
    String? platform,
    String? fromPage,
    String? toPage,
    String? locale,
    String? country,
  }) async {
    final sessionId = await getSessionId();
    final res = await apiRequest(
      method: 'GET',
      path: '/api/query/transitions',
      queryParams: {
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
        if (projectId != null) 'projectId': projectId,
        if (channel != null) 'channel': channel,
        if (version != null) 'version': version,
        if (platform != null) 'platform': platform,
        if (fromPage != null) 'fromPage': fromPage,
        if (toPage != null) 'toPage': toPage,
        if (locale != null) 'locale': locale,
        if (country != null) 'country': country,
      },
      headers: {'Authorization': 'Bearer $sessionId'},
    );

    checkResponse(res, context: 'Failed to retrieve page transitions.');
    final List<dynamic> results = res.data['data'];
    return results.map((r) => TransitionAnalytics.fromJson(r)).toList();
  }

  //-----------------------------------
  // helper methods
  //-----------------------------------

  void checkResponse(Response res, {String? context}) {
    if (res.ok) return;

    final statusCode = res.statusCode ?? 999;
    final ctx = (context != null && context.isNotEmpty) ? context : '';
    final sep = ctx.isEmpty
        ? ''
        : RegExp(r'[.!?:;,]$').hasMatch(ctx)
        ? ' '
        : ': ';
    final msg = '$ctx$sep${_serverMessage(res)}';
    final message = msg.isNotEmpty ? msg : defaultStatusMessages[statusCode];
    switch (statusCode) {
      case 400:
        throw CloudException(message ?? 'Invalid request');
      case 401:
        throw CloudException(message ?? 'Not authenticated');
      case 403:
        throw CloudException(message ?? 'You do not have permission');
      case 404:
        throw CloudException(message ?? 'Resource not found');
      case 409:
        throw CloudException(message ?? 'Conflict');
      case 413:
        throw CloudException(message ?? 'Upload too large');
      case 429:
        throw CloudException(message ?? 'Too many requests. Please try again later');
      default:
        if (statusCode >= 500) {
          throw CloudException(message ?? 'Server error. Please try again later');
        }
        throw CloudException(message ?? context ?? 'Request failed');
    }
  }

  String? _serverMessage(Response res) {
    try {
      return res.data['error']['message'];
    } catch (_) {
      return null;
    }
  }
}

class CloudException implements Exception {
  final String message;

  CloudException(this.message);

  @override
  String toString() => message;
}
