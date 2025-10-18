import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ivideo/features/video/video_player_page.dart';
import 'package:ivideo/shared/models/video_model.dart';

class VideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback? onTap;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getProxiedImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) {
      return _getPlaceholderImage();
    }

    if (originalUrl.contains('hdslb.com') ||
        originalUrl.contains('bilibili') ||
        originalUrl.contains('googleapis')) {
      return 'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}';
    }

    return originalUrl;
  }

  String _getPlaceholderImage() {
    return 'https://corsproxy.io/?https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatViews(int views) {
    if (views >= 10000) {
      return '${(views / 10000).toStringAsFixed(1)}万';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}千';
    }
    return '$views';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _animationController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VideoPlayerPage(video: widget.video),
                              ),
                            );
                          },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildThumbnail(),
                          _buildInfoSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: _getProxiedImageUrl(widget.video.thumbnailUrl),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFFF5F5F5),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFF6428)),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFF5F5F5),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
          if (_isHovered)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Icon(Icons.play_circle_filled, size: 56, color: Colors.white),
                ),
              ),
            ),
          if (widget.video.duration > 0)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _formatDuration(widget.video.duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.2),
                ),
              ),
            ),
          if (widget.video.isFeatured)
            Positioned(
              top: 8,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6428),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                ),
                child: const Text(
                  '推荐',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _formatViews(widget.video.viewsCount),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 2,
                height: 2,
                decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
              ),
              Flexible(
                child: Text(
                  widget.video.videoType,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (widget.video.tags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '${widget.video.tags.length}个标签',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
