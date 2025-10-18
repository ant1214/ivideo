
import 'package:flutter/material.dart';
import 'package:ivideo/core/services/favorite_service.dart';
import 'package:ivideo/core/services/video_service.dart';
import 'package:ivideo/core/services/watch_history_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:ivideo/shared/models/video_model.dart';
import 'package:ivideo/core/supabase/supabase_client.dart';

class VideoPlayerPage extends StatefulWidget {
  final Video video;

  const VideoPlayerPage({super.key, required this.video});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _isFavorited = false;
  bool _isCheckingFavorite = true;
  bool _historyAdded = false;
  bool _viewCountIncremented = false;
  late Video _currentVideo; // 添加这个变量来存储包含标签的视频数据

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video; // 初始使用传入的视频数据
    _loadVideoWithTags(); // 加载包含标签的完整数据
  }

  // 加载包含标签的完整视频数据
  Future<void> _loadVideoWithTags() async {
    try {
      print('正在加载视频标签数据...');
      final videoData = await VideoService.getVideo(widget.video.id);
      
      if (videoData != null) {
        final videoWithTags = Video.fromJson(videoData);
        setState(() {
          _currentVideo = videoWithTags;
        });
        print('✅ 视频标签数据加载成功: ${_currentVideo.tags}');
      } else {
        print('⚠️ 无法获取视频标签数据，使用原始数据');
      }
    } catch (e) {
      print('❌ 加载视频标签数据失败: $e');
    } finally {
      // 无论是否成功获取标签，都初始化播放器
      _initializeVideoPlayer();
      _checkFavoriteStatus();
      _addToWatchHistory();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_currentVideo.videoUrl), // 使用 _currentVideo
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade400,
        ),
      );

      _videoPlayerController.addListener(() {
        final currentPosition = _videoPlayerController.value.position.inSeconds;
        final isPlaying = _videoPlayerController.value.isPlaying;

        if (isPlaying && currentPosition % 30 == 0 && currentPosition > 0) {
          print('📊 更新观看进度: $currentPosition 秒');
          _updateWatchProgress(currentPosition);
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('视频播放器初始化失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateWatchProgress(int progress) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return;

      await WatchHistoryService.updateWatchProgress(
        _currentVideo.id, // 使用 _currentVideo
        progress,
        _currentVideo.duration ?? 0, // 使用 _currentVideo
      );
      print('✅ 观看进度更新: $progress 秒');
    } catch (e) {
      print('❌ 更新观看进度失败: $e');
    }
  }

  void _addToWatchHistory() async {
    try {
      final user = SupabaseService.client.auth.currentUser;

      print('正在处理观看数据，视频ID: ${_currentVideo.id}'); // 使用 _currentVideo

      if (!_viewCountIncremented) {
        print('正在增加观看次数...');
        final viewSuccess = await VideoService.incrementViewCount(_currentVideo.id); // 使用 _currentVideo
        if (viewSuccess) {
          print('✅ 观看次数增加成功');
          _viewCountIncremented = true;
        } else {
          print('❌ 观看次数增加失败');
        }
      } else {
        print('⚠️ 观看次数已增加，跳过重复操作');
      }

      if (user != null) {
        if (!_historyAdded) {
          print('正在添加观看记录...');
          final historySuccess = await WatchHistoryService.addWatchHistory(
            _currentVideo.id, // 使用 _currentVideo
            progress: 0,
            duration: _currentVideo.duration ?? 0, // 使用 _currentVideo
          );

          if (historySuccess) {
            print('✅ 观看记录添加成功');
            _historyAdded = true;
          } else {
            print('❌ 观看记录添加失败');
          }
        } else {
          print('⚠️ 观看记录已添加，跳过重复操作');
        }
      } else {
        print('⚠️ 用户未登录，跳过观看记录');
      }
    } catch (e) {
      print('❌ 处理观看数据异常: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFav = await FavoriteService.isFavorite(_currentVideo.id); // 使用 _currentVideo
      print('收藏状态检查结果: $isFav');

      setState(() {
        _isFavorited = isFav;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      print('检查收藏状态失败: $e');
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
        return;
      }

      setState(() {
        _isFavorited = !_isFavorited;
      });

      final success = await FavoriteService.toggleFavorite(
        _currentVideo.id, // 使用 _currentVideo
        !_isFavorited
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorited ? '❤️ 已添加收藏' : '♡ 已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        setState(() {
          _isFavorited = !_isFavorited;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    } catch (e) {
      print('切换收藏状态失败: $e');
      setState(() {
        _isFavorited = !_isFavorited;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请重试')),
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _currentVideo.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white, // 确保标题是白色
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData( // 添加这一行
          color: Colors.white, // 明确设置返回按钮为白色
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Chewie(controller: _chewieController!),
                ),
                _buildVideoInfo(),
              ],
            ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentVideo.title, // 使用 _currentVideo
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentVideo.viewsCount} 次观看', // 使用 _currentVideo
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!_isCheckingFavorite)
                Container(
                  decoration: BoxDecoration(
                    color: _isFavorited ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited ? Colors.red : Colors.grey,
                      size: 24,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
            ],
          ),

          // 添加标签显示区域
          if (_currentVideo.tags.isNotEmpty) ...[ // 使用 _currentVideo
            const SizedBox(height: 12),
            _buildTags(),
          ],

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 16),
          Text(
            _currentVideo.description.isNotEmpty // 使用 _currentVideo
                ? _currentVideo.description
                : '暂无视频描述',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 构建标签组件
  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: _currentVideo.tags.map((tag) { // 使用 _currentVideo
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Text(
            '#$tag',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}