class Workspace {
  final String id;
  final String name;
  final String? roleId;

  Workspace({required this.id, required this.name, this.roleId});

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(id: json['id'], name: json['name'], roleId: json['roleId']);
  }
}

class Usage {
  final String metric;
  final int maxAllowed;
  final String period;
  final String periodType;
  final int used;

  Usage({
    required this.metric,
    required this.maxAllowed,
    required this.period,
    required this.periodType,
    required this.used,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      metric: json['metric'],
      maxAllowed: json['maxAllowed'],
      period: json['period'],
      periodType: json['periodType'],
      used: json['used'],
    );
  }
}

class Project {
  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final int? createdAt;
  final int? updatedAt;

  Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      workspaceId: json['workspaceId'],
      name: json['name'],
      description: json['description'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class ProjectDeletes {
  final int projects;
  final int channels;
  final int deployments;

  ProjectDeletes({required this.projects, required this.channels, required this.deployments});

  factory ProjectDeletes.fromJson(Map<String, dynamic> json) {
    return ProjectDeletes(
      projects: json['projects'],
      channels: json['channels'],
      deployments: json['deployments'],
    );
  }
}

class ProjectKeys {
  final String projectKey;
  final String storageKey;

  ProjectKeys({required this.projectKey, required this.storageKey});

  factory ProjectKeys.fromJson(Map<String, dynamic> json) {
    return ProjectKeys(projectKey: json['key'], storageKey: json['storageKey']);
  }
}

class Channel {
  final String id;
  final String name;
  final int? createdAt;
  final int? updatedAt;

  Channel({required this.id, required this.name, this.createdAt, this.updatedAt});

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class ChannelDeletes {
  final int channels;
  final int deployments;

  ChannelDeletes({required this.channels, required this.deployments});

  factory ChannelDeletes.fromJson(Map<String, dynamic> json) {
    return ChannelDeletes(channels: json['channels'], deployments: json['deployments']);
  }
}

class Deployment {
  final String id;
  final String channelId;
  final String? channelName;
  final String versionNumber;
  final String? versionMetadata;
  final String? notes;
  final int sizeBytes;
  final String? deployedByUserName;
  final int createdAt;
  final int updatedAt;

  Deployment({
    required this.id,
    required this.channelId,
    this.channelName,
    required this.versionNumber,
    this.versionMetadata,
    this.notes,
    required this.sizeBytes,
    this.deployedByUserName,
    required this.createdAt,
    required this.updatedAt,
  });

  String get version => versionMetadata != null ? '$versionNumber+$versionMetadata' : versionNumber;

  factory Deployment.fromJson(Map<String, dynamic> json) {
    return Deployment(
      id: json['id'],
      channelId: json['channelId'],
      channelName: json['channelName'],
      versionNumber: json['versionNumber'],
      versionMetadata: json['versionMetadata'],
      notes: json['notes'],
      sizeBytes: json['sizeBytes'],
      deployedByUserName: json['deployedByUserName'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class RenderAnalytics with AnalyticsMixin {
  final String period;
  final String channel;
  final String versionNumber;
  final String versionMetadata;
  final String fragment;
  final String platform;
  final String locale;
  final String countryCode;
  final int renderCount;
  final int errorCount;

  RenderAnalytics({
    required this.period,
    required this.channel,
    required this.versionNumber,
    required this.versionMetadata,
    required this.fragment,
    required this.platform,
    required this.locale,
    required this.countryCode,
    required this.renderCount,
    required this.errorCount,
  });

  factory RenderAnalytics.fromJson(Map<String, dynamic> json) {
    return RenderAnalytics(
      period: json['period'] ?? '',
      channel: json['channel'] ?? '',
      versionNumber: json['version_number'] ?? '',
      versionMetadata: json['version_metadata'] ?? '',
      fragment: json['fragment'] ?? '',
      platform: json['platform'] ?? '',
      locale: json['locale'] ?? '',
      countryCode: json['country_code'] ?? '',
      renderCount: json['render_count'] ?? 0,
      errorCount: json['error_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'channel': channel,
    'version': fullVersion(versionNumber, versionMetadata),
    'versionNumber': versionNumber,
    'versionMetadata': versionMetadata,
    'fragment': fragment,
    'platform': platform,
    'locale': locale,
    'countryCode': countryCode,
    'renderCount': renderCount,
    'errorCount': errorCount,
  };
}

class DownloadAnalytics with AnalyticsMixin {
  final String period;
  final String channel;
  final String versionNumber;
  final String versionMetadata;
  final String platform;
  final String locale;
  final String countryCode;
  final int cacheCount;
  final int downloadCount;
  final int errorCount;

  DownloadAnalytics({
    required this.period,
    required this.channel,
    required this.versionNumber,
    required this.versionMetadata,
    required this.platform,
    required this.locale,
    required this.countryCode,
    required this.cacheCount,
    required this.downloadCount,
    required this.errorCount,
  });

  factory DownloadAnalytics.fromJson(Map<String, dynamic> json) {
    return DownloadAnalytics(
      period: json['period'] ?? '',
      channel: json['channel'] ?? '',
      versionNumber: json['version_number'] ?? '',
      versionMetadata: json['version_metadata'] ?? '',
      platform: json['platform'] ?? '',
      locale: json['locale'] ?? '',
      countryCode: json['country_code'] ?? '',
      cacheCount: json['cache_count'] ?? 0,
      downloadCount: json['download_count'] ?? 0,
      errorCount: json['error_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'channel': channel,
    'version': fullVersion(versionNumber, versionMetadata),
    'versionNumber': versionNumber,
    'versionMetadata': versionMetadata,
    'platform': platform,
    'locale': locale,
    'countryCode': countryCode,
    'cacheCount': cacheCount,
    'downloadCount': downloadCount,
    'errorCount': errorCount,
  };
}

class ErrorAnalytics with AnalyticsMixin {
  final String period;
  final String channel;
  final String versionNumber;
  final String versionMetadata;
  final String fragment;
  final String platform;
  final String locale;
  final String countryCode;
  final String errorMessage;
  final int errorCount;

  ErrorAnalytics({
    required this.period,
    required this.channel,
    required this.versionNumber,
    required this.versionMetadata,
    required this.fragment,
    required this.platform,
    required this.locale,
    required this.countryCode,
    required this.errorMessage,
    required this.errorCount,
  });

  factory ErrorAnalytics.fromJson(Map<String, dynamic> json) {
    return ErrorAnalytics(
      period: json['period'] ?? '',
      channel: json['channel'] ?? '',
      versionNumber: json['version_number'] ?? '',
      versionMetadata: json['version_metadata'] ?? '',
      fragment: json['fragment'] ?? '',
      platform: json['platform'] ?? '',
      locale: json['locale'] ?? '',
      countryCode: json['country_code'] ?? '',
      errorMessage: json['error_message'] ?? '',
      errorCount: json['error_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'channel': channel,
    'version': fullVersion(versionNumber, versionMetadata),
    'versionNumber': versionNumber,
    'versionMetadata': versionMetadata,
    'fragment': fragment,
    'platform': platform,
    'locale': locale,
    'countryCode': countryCode,
    'errorMessage': errorMessage,
    'errorCount': errorCount,
  };
}

class TransitionAnalytics with AnalyticsMixin {
  final String channel;
  final String versionNumber;
  final String versionMetadata;
  final String platform;
  final String locale;
  final String countryCode;
  final String fromPage;
  final String toPage;
  final int transitions;
  final double percentage;
  final int? avgDurationSeconds;

  TransitionAnalytics({
    required this.channel,
    required this.versionNumber,
    required this.versionMetadata,
    required this.platform,
    required this.locale,
    required this.countryCode,
    required this.fromPage,
    required this.toPage,
    required this.transitions,
    required this.percentage,
    this.avgDurationSeconds,
  });

  factory TransitionAnalytics.fromJson(Map<String, dynamic> json) {
    return TransitionAnalytics(
      channel: json['channel'] ?? '',
      versionNumber: json['version_number'] ?? '',
      versionMetadata: json['version_metadata'] ?? '',
      platform: json['platform'] ?? '',
      locale: json['locale'] ?? '',
      countryCode: json['country_code'] ?? '',
      fromPage: json['from_page'] ?? '',
      toPage: json['to_page'] ?? '',
      transitions: json['transitions'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      avgDurationSeconds: json['avg_duration_seconds'],
    );
  }

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'version': fullVersion(versionNumber, versionMetadata),
    'versionNumber': versionNumber,
    'versionMetadata': versionMetadata,
    'platform': platform,
    'locale': locale,
    'countryCode': countryCode,
    'fromPage': fromPage,
    'toPage': toPage,
    'transitions': transitions,
    'percentage': percentage,
    'avgDurationSeconds': avgDurationSeconds,
  };
}

mixin AnalyticsMixin {
  String? fullVersion(String? number, String? metadata) {
    return number != null && number.isNotEmpty
        ? metadata != null && metadata.isNotEmpty
              ? '$number+$metadata'
              : number
        : null;
  }
}
