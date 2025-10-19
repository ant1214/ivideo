import 'package:ivideo/core/supabase/supabase_client.dart';

class VideoService {
  // 增加视频观看次数 - 修复版本
  static Future<bool> incrementViewCount(String videoId) async {
    try {
      print('正在增加视频 $videoId 的观看次数...');
      
      // 方法1：使用 RPC 函数（如果已创建）
      try {
        await SupabaseService.client
            .rpc('increment_views', params: {'video_id': videoId});
        print('✅ 使用 RPC 增加观看次数成功');
        return true;
      } catch (e) {
        print('RPC 失败，使用更新查询: $e');
      }
      
      // 方法2：使用更新查询（先获取再更新）
      final currentResponse = await SupabaseService.client
          .from('videos')
          .select('views_count')
          .eq('id', videoId)
          .single();

      if (currentResponse.isEmpty) {
        print('❌ 未找到视频');
        return false;
      }

      final currentViews = currentResponse['views_count'] as int;
      print('当前观看次数: $currentViews');

      final updateResponse = await SupabaseService.client
          .from('videos')
          .update({
            'views_count': currentViews + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', videoId);

      if (updateResponse.hasError) {
        print('❌ 更新失败: ${updateResponse.error}');
        return false;
      }

      // 验证更新是否成功
      final verifyResponse = await SupabaseService.client
          .from('videos')
          .select('views_count')
          .eq('id', videoId)
          .single();

      final newViews = verifyResponse['views_count'] as int;
      print('更新后观看次数: $newViews');

      if (newViews > currentViews) {
        print('✅ 观看次数验证成功: $currentViews → $newViews');
        return true;
      } else {
        print('❌ 观看次数没有变化');
        return false;
      }

    } catch (e) {
      print('❌ 增加观看次数异常: $e');
      return false;
    }
  }

  // 获取视频详情（包含标签）- 修复版本
  static Future<Map<String, dynamic>?> getVideo(String videoId) async {
    try {
      final response = await SupabaseService.client
          .from('videos')
          .select('''
            *,
            video_tags (
              tags (
                name
              )
            )
          ''')
          .eq('id', videoId)
          .single();

      // 新版本 Supabase 直接返回数据，没有 error 字段
      if (response.isEmpty) {
        print('未找到视频数据');
        return null;
      }

      print('获取到的视频数据: $response');
      return response;
    } catch (e) {
      print('获取视频详情失败: $e');
      return null;
    }
  }

  // 获取视频列表（包含标签）- 修复版本
  static Future<List<Map<String, dynamic>>> getVideos({int limit = 20}) async {
    try {
      final response = await SupabaseService.client
          .from('videos')
          .select('''
            *,
            video_tags (
              tags (
                name
              )
            )
          ''')
          .order('created_at', ascending: false)
          .limit(limit);

      // 新版本直接返回 List
      if (response.isEmpty) {
        print('未找到视频数据');
        return [];
      }

      return response;
    } catch (e) {
      print('获取视频列表失败: $e');
      return [];
    }
  }
}
