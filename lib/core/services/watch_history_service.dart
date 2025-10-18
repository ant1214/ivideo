// // watch_history_service.dart
// import 'package:ivideo/core/supabase/supabase_client.dart';
// import 'package:ivideo/shared/models/video_model.dart';

// class WatchHistoryService {
//   // 添加观看记录
//   static Future<bool> addWatchHistory(String videoId, {int progressSeconds = 0}) async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return false;

//       await SupabaseService.client
//           .from('watch_history')
//           .upsert({
//             'user_id': user.id,
//             'video_id': videoId,
//             'progress_seconds': progressSeconds,
//             'watched_at': DateTime.now().toIso8601String(),
//           }, onConflict: 'user_id,video_id');

//       return true;
//     } catch (e) {
//       print('添加观看记录失败: $e');
//       return false;
//     }
//   }

//   // 获取用户的观看历史
//   static Future<List<Video>> getUserWatchHistory() async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return [];

//       final response = await SupabaseService.client
//           .from('watch_history')
//           .select('''
//             video_id,
//             watched_at,
//             progress_seconds,
//             videos (
//               id,
//               title,
//               description,
//               video_url,
//               thumbnail_url,
//               views_count,
//               duration,
//               created_at
//             )
//           ''')
//           .eq('user_id', user.id)
//           .order('watched_at', ascending: false);

//       // 转换数据为 Video 对象列表
//       final List<Video> historyVideos = [];
//       for (var item in response) {
//         final videoData = item['videos'] as Map<String, dynamic>;
//         historyVideos.add(Video.fromJson(videoData));
//       }
      
//       return historyVideos;
//     } catch (e) {
//       print('获取观看历史失败: $e');
//       return [];
//     }
//   }

//   // 清空观看历史
//   static Future<bool> clearWatchHistory() async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return false;

//       await SupabaseService.client
//           .from('watch_history')
//           .delete()
//           .eq('user_id', user.id);

//       return true;
//     } catch (e) {
//       print('清空观看历史失败: $e');
//       return false;
//     }
//   }

//   // 删除单条观看记录
//   static Future<bool> removeWatchHistory(String videoId) async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return false;

//       await SupabaseService.client
//           .from('watch_history')
//           .delete()
//           .eq('user_id', user.id)
//           .eq('video_id', videoId);

//       return true;
//     } catch (e) {
//       print('删除观看记录失败: $e');
//       return false;
//     }
//   }

//   // 获取观看记录数量 - 修复版本
//   static Future<int> getWatchHistoryCount() async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return 0;

//       // 方法1：直接获取所有记录并计算长度
//       final response = await SupabaseService.client
//           .from('watch_history')
//           .select()
//           .eq('user_id', user.id);

//       return response.length;
//     } catch (e) {
//       print('获取观看记录数量失败: $e');
//       return 0;
//     }
//   }

//   // 备选方案：使用 head 方法获取计数
//   static Future<int> getWatchHistoryCountAlternative() async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return 0;

//       final response = await SupabaseService.client
//           .from('watch_history')
//           .select('id')
//           .eq('user_id', user.id);

//       return response.length;
//     } catch (e) {
//       print('获取观看记录数量失败: $e');
//       return 0;
//     }
//   }
// }
// watch_history_service.dart
import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:ivideo/shared/models/video_model.dart';

class WatchHistoryService {
  // 添加观看记录 - 匹配你的表结构
  // static Future<bool> addWatchHistory(String videoId, {int progress = 0, int duration = 0}) async {
  //   try {
  //     final user = SupabaseService.client.auth.currentUser;
  //     if (user == null) return false;

  //     await SupabaseService.client
  //         .from('watch_history')
  //         .upsert({
  //           'user_id': user.id,
  //           'video_id': videoId,
  //           'progress': progress,
  //           'duration': duration,
  //           'watched_at': DateTime.now().toIso8601String(),
  //         });

  //     return true;
  //   } catch (e) {
  //     print('添加观看记录失败: $e');
  //     return false;
  //   }
  // }
    // 在 WatchHistoryService 中修复 addWatchHistory 方法
    static Future<bool> addWatchHistory(String videoId, {int progress = 0, int? duration}) async {
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) return false;

        // 使用 upsert 而不是 insert，这样如果记录已存在就更新
        await SupabaseService.client
            .from('watch_history')
            .upsert({
              'user_id': user.id,
              'video_id': videoId,
              'progress': progress,
              'duration': duration ?? 0,
              'watched_at': DateTime.now().toIso8601String(), // 更新观看时间
            });

        return true;
      } catch (e) {
        // 如果是重复记录错误，也认为是成功（因为使用了 upsert）
        if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
          print('观看记录已存在，更新时间戳');
          return true;
        }
        print('添加观看记录失败: $e');
        return false;
      }
    }
  // 获取用户的观看历史 - 匹配你的表结构
  // static Future<List<Video>> getUserWatchHistory() async {
  //   try {
  //     final user = SupabaseService.client.auth.currentUser;
  //     if (user == null) return [];

  //     final response = await SupabaseService.client
  //         .from('watch_history')
  //         .select('''
  //           video_id,
  //           watched_at,
  //           progress,
  //           duration,
  //           videos (
  //             id,
  //             title,
  //             description,
  //             video_url,
  //             thumbnail_url,
  //             views_count,
  //             duration as video_duration,
  //             created_at
  //           )
  //         ''')
  //         .eq('user_id', user.id)
  //         .order('watched_at', ascending: false);

  //     // 转换数据为 Video 对象列表
  //     final List<Video> historyVideos = [];
  //     for (var item in response) {
  //       final videoData = item['videos'] as Map<String, dynamic>;
  //       historyVideos.add(Video.fromJson(videoData));
  //     }
      
  //     return historyVideos;
  //   } catch (e) {
  //     print('获取观看历史失败: $e');
  //     return [];
  //   }
  // }
static Future<List<Video>> getUserWatchHistory() async {
  try {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];

    final response = await SupabaseService.client
        .from('watch_history')
        .select('video_id, watched_at, progress, duration, videos(*)')
        .eq('user_id', user.id)
        .order('watched_at', ascending: false);

    final List<Video> historyVideos = [];
    for (var item in response) {
      final videoData = item['videos'] as Map<String, dynamic>;
      historyVideos.add(Video.fromJson(videoData));
    }
    
    return historyVideos;
  } catch (e) {
    print('获取观看历史失败: $e');
    return [];
  }
}
  // 清空观看历史
  static Future<bool> clearWatchHistory() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      await SupabaseService.client
          .from('watch_history')
          .delete()
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('清空观看历史失败: $e');
      return false;
    }
  }

  // 删除单条观看记录
  static Future<bool> removeWatchHistory(String videoId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      await SupabaseService.client
          .from('watch_history')
          .delete()
          .eq('user_id', user.id)
          .eq('video_id', videoId);

      return true;
    } catch (e) {
      print('删除观看记录失败: $e');
      return false;
    }
  }

  // 获取观看记录数量
  static Future<int> getWatchHistoryCount() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return 0;

      final response = await SupabaseService.client
          .from('watch_history')
          .select()
          .eq('user_id', user.id);

      return response.length;
    } catch (e) {
      print('获取观看记录数量失败: $e');
      return 0;
    }
  }

  // 更新观看进度
  static Future<bool> updateWatchProgress(String videoId, int progress, int duration) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      await SupabaseService.client
          .from('watch_history')
          .upsert({
            'user_id': user.id,
            'video_id': videoId,
            'progress': progress,
            'duration': duration,
            'watched_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      print('更新观看进度失败: $e');
      return false;
    }
  }
}