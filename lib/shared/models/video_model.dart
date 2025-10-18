// class Video {
//   final String id;
//   final String title;
//   final String description;
//   final String videoUrl;
//   final String thumbnailUrl;
//   final int duration;
//   final int viewsCount;
//   final bool isFeatured;
//   final String videoType;
//   final DateTime createdAt;

//   Video({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.videoUrl,
//     required this.thumbnailUrl,
//     required this.duration,
//     required this.viewsCount,
//     required this.isFeatured,
//     required this.videoType,
//     required this.createdAt,
//   });

//   factory Video.fromJson(Map<String, dynamic> json) {
//     return Video(
//       id: json['id']?.toString() ?? '',
//       title: json['title']?.toString() ?? '未知标题',
//       description: json['description']?.toString() ?? '',
//       videoUrl: json['video_url']?.toString() ?? '',
//       thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
//       duration: (json['duration'] as int?) ?? 0,
//       viewsCount: (json['views_count'] as int?) ?? 0,
//       isFeatured: (json['is_featured'] as bool?) ?? false,
//       videoType: json['video_type']?.toString() ?? '其他',
//       createdAt: json['created_at'] != null 
//           ? DateTime.parse(json['created_at'].toString())
//           : DateTime.now(),
//     );
//   }
// }
class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int duration;
  final int viewsCount;
  final bool isFeatured;
  final String videoType;
  final DateTime createdAt;
  final List<String> tags; // 新增标签字段

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.viewsCount,
    required this.isFeatured,
    required this.videoType,
    required this.createdAt,
    this.tags = const [], // 默认空列表
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    // 处理标签数据
    List<String> tags = [];
    
    // 情况1：直接从 video_tags 关联表获取
    if (json['video_tags'] != null && json['video_tags'] is List) {
      final videoTags = json['video_tags'] as List;
      tags = videoTags
          .where((tag) => tag != null && tag['tags'] != null)
          .map<String>((tag) => tag['tags']['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }
    // 情况2：如果后端直接返回 tags 字段
    else if (json['tags'] != null && json['tags'] is List) {
      tags = List<String>.from(json['tags'] ?? []);
    }
    // 情况3：从 tags 对象数组获取
    else if (json['tags'] != null && json['tags'] is List) {
      final tagsList = json['tags'] as List;
      tags = tagsList
          .where((tag) => tag != null && tag['name'] != null)
          .map<String>((tag) => tag['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '未知标题',
      description: json['description']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      duration: (json['duration'] as int?) ?? 0,
      viewsCount: (json['views_count'] as int?) ?? 0,
      isFeatured: (json['is_featured'] as bool?) ?? false,
      videoType: json['video_type']?.toString() ?? '其他',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      tags: tags, // 添加标签
    );
  }
}