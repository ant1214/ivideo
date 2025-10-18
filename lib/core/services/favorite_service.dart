// import 'package:ivideo/core/supabase/supabase_client.dart';

// class FavoriteService {
//   // 添加收藏
//   static Future<bool> addFavorite(String videoId) async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return false;

//       final response = await SupabaseService.client
//           .from('favorites')
//           .insert({
//             'user_id': user.id,
//             'video_id': videoId,
//           });

//       if (response.error != null) {
//         // 如果是重复收藏，也认为是成功
//         if (response.error!.message.contains('duplicate key')) {
//           return true;
//         }
//         throw Exception(response.error!.message);
//       }

//       return true;
//     } catch (e) {
//       print('添加收藏失败: $e');
//       return false;
//     }
//   }

//   // 取消收藏
//   static Future<bool> removeFavorite(String videoId) async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return false;

//       final response = await SupabaseService.client
//           .from('favorites')
//           .delete()
//           .eq('user_id', user.id)
//           .eq('video_id', videoId);

//       if (response.error != null) {
//         throw Exception(response.error!.message);
//       }

//       return true;
//     } catch (e) {
//       print('取消收藏失败: $e');
//       return false;
//     }
//   }

//   // 检查是否已收藏
//   static Future<bool> isFavorite(String videoId) async {
//     try {
//       final user = SupabaseService.client.auth.currentUser;
//       if (user == null) return false;

//       final response = await SupabaseService.client
//           .from('favorites')
//           .select('id')
//           .eq('user_id', user.id)
//           .eq('video_id', videoId);

//           try {
//             final response = await SupabaseService.client
//                 .from('favorites')
//                 .insert({
//                   'user_id': user.id,
//                   'video_id': videoId,
//                 });
            
//             if (response.hasError) {
//               throw Exception(response.error?.message ?? 'Unknown error');
//             }
            
//             // 成功逻辑
//           } catch (e) {
//             // 错误处理
//           }

//      final data = response.cast<Map<String, dynamic>>();
//       return data.isNotEmpty;
//     } catch (e) {
//       print('检查收藏状态失败: $e');
//       return false;
//     }
//   }

//   // 切换收藏状态
//   static Future<bool> toggleFavorite(String videoId, bool currentlyFavorited) async {
//     if (currentlyFavorited) {
//       return await removeFavorite(videoId);
//     } else {
//       return await addFavorite(videoId);
//     }
//   }
// }
import 'package:ivideo/core/supabase/supabase_client.dart';
import 'package:ivideo/shared/models/video_model.dart';

class FavoriteService {
  // 添加收藏 - 完全修复版本
  static Future<bool> addFavorite(String videoId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      // 新版本直接执行，如果重复收藏会抛出异常
      await SupabaseService.client
          .from('favorites')
          .insert({
            'user_id': user.id,
            'video_id': videoId,
          });

      return true;
    } catch (e) {
      // 如果是重复收藏的约束错误，也认为是成功
      if (e.toString().contains('duplicate key') || 
          e.toString().contains('23505')) {
        print('视频已收藏，无需重复添加');
        return true;
      }
      print('添加收藏失败: $e');
      return false;
    }
  }

  // 取消收藏
  static Future<bool> removeFavorite(String videoId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      await SupabaseService.client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('video_id', videoId);

      return true;
    } catch (e) {
      print('取消收藏失败: $e');
      return false;
    }
  }

  // 检查是否已收藏
  static Future<bool> isFavorite(String videoId) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      final response = await SupabaseService.client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('video_id', videoId);

      return response.isNotEmpty;
    } catch (e) {
      print('检查收藏状态失败: $e');
      return false;
    }
  }

  // 切换收藏状态
  static Future<bool> toggleFavorite(String videoId, bool currentlyFavorited) async {
    if (currentlyFavorited) {
      return await removeFavorite(videoId);
    } else {
      return await addFavorite(videoId);
    }
  }
  // 在 FavoriteService 中添加
static Future<List<Video>> getUserFavoriteVideos() async {
  try {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return [];

    final response = await SupabaseService.client
        .from('favorites')
        .select('''
          video_id,
          videos (
            id,
            title,
            description,
            video_url,
            thumbnail_url,
            views_count,
            duration,
            created_at
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // 转换数据为 Video 对象列表
    final List<Video> favoriteVideos = [];
    for (var item in response) {
      final videoData = item['videos'] as Map<String, dynamic>;
      favoriteVideos.add(Video.fromJson(videoData));
    }
    
    return favoriteVideos;
  } catch (e) {
    print('获取收藏视频失败: $e');
    return [];
  }
}
}