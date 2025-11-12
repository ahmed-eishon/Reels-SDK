import 'package:flutter/material.dart';
import 'package:reels_flutter/core/pigeon_generated.dart';
import 'package:reels_flutter/domain/entities/video_entity.dart';

/// Bottom overlay with video description and user info
///
/// Features:
/// - Username with verification badge
/// - Video description text
/// - Hashtags extracted from description
/// - Audio/music info
/// - Expandable description for long text
/// - Audio mute/unmute control
/// - User profile click handling
/// - Uses collect data from native when available
class VideoDescription extends StatefulWidget {
  final VideoEntity video;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback? onUserProfileClick;
  final CollectData? collectData;

  const VideoDescription({
    super.key,
    required this.video,
    required this.isMuted,
    required this.onToggleMute,
    this.onUserProfileClick,
    this.collectData,
  });

  @override
  State<VideoDescription> createState() => _VideoDescriptionState();
}

class _VideoDescriptionState extends State<VideoDescription> {
  bool _isExpanded = false;
  static const int _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username
        _buildUsername(),
        const SizedBox(height: 8),

        // Description with expand/collapse
        _buildDescription(),
        const SizedBox(height: 12),

        // Audio/Music info
        _buildAudioInfo(),
      ],
    );
  }

  Widget _buildUsername() {
    // Use collect data if available, otherwise fall back to video data
    final userName = widget.collectData?.userName ?? widget.video.user.name;
    final avatarUrl = widget.collectData?.userProfileImage ?? widget.video.user.avatarUrl;

    print('[ReelsSDK-Flutter] VideoDescription._buildUsername()');
    print('[ReelsSDK-Flutter] - collectData != null: ${widget.collectData != null}');
    if (widget.collectData != null) {
      print('[ReelsSDK-Flutter] - collectData.userName: ${widget.collectData!.userName}');
      print('[ReelsSDK-Flutter] - collectData.userProfileImage: ${widget.collectData!.userProfileImage}');
    }
    print('[ReelsSDK-Flutter] - Using userName: $userName');
    print('[ReelsSDK-Flutter] - Using avatarUrl: $avatarUrl');

    return GestureDetector(
      onTap: widget.onUserProfileClick,
      child: Row(
        children: [
          // Avatar on the left
          CircleAvatar(
            radius: 16,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            backgroundColor: Colors.grey.shade800,
            child: avatarUrl.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 8),
          // Username with overflow handling (marquee effect)
          Expanded(
            child: _MarqueeText(
              text: '@$userName',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8), // Padding on right
        ],
      ),
    );
  }

  Widget _buildDescription() {
    // Build description from collect data if available, otherwise use video description
    String description;
    if (widget.collectData != null) {
      final name = widget.collectData!.name ?? '';
      final content = widget.collectData!.content ?? '';

      print('[ReelsSDK-Flutter] VideoDescription._buildDescription()');
      print('[ReelsSDK-Flutter] - collectData.name: "$name"');
      print('[ReelsSDK-Flutter] - collectData.content: "$content"');

      if (name.isNotEmpty && content.isNotEmpty) {
        description = '$name\n\n$content';
      } else if (name.isNotEmpty) {
        description = name;
      } else if (content.isNotEmpty) {
        description = content;
      } else {
        description = widget.video.description;
      }
      print('[ReelsSDK-Flutter] - Using description: "$description"');
    } else {
      description = widget.video.description;
      print('[ReelsSDK-Flutter] VideoDescription._buildDescription() - No collectData, using video description');
    }

    final hasLongDescription = description.length > 100;

    return GestureDetector(
      onTap: hasLongDescription
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
      child: _isExpanded
          ? Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8),
                      ],
                    ),
                    children: [
                      TextSpan(text: _parseDescription(description)),
                    ],
                  ),
                ),
              ),
            )
          : RichText(
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
                children: [
                  TextSpan(text: _parseDescription(description)),
                  if (hasLongDescription)
                    TextSpan(
                      text: ' more',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _parseDescription(String text) {
    // In a real app, this would parse hashtags and mentions
    // For now, just return the text
    return text;
  }

  Widget _buildAudioInfo() {
    return GestureDetector(
      onTap: () {
        widget.onToggleMute();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isMuted ? 'Audio unmuted' : 'Audio muted'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.isMuted ? Icons.volume_off : Icons.music_note,
              size: 16,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
              ],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.isMuted
                    ? 'Audio muted'
                    : 'Original Audio - ${widget.video.user.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marquee text widget that scrolls when text overflows
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({
    required this.text,
    required this.style,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  void _checkOverflow() {
    if (!mounted) return;

    // Check if text is overflowing
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final availableWidth = renderBox.size.width;
      _isOverflowing = textPainter.width > availableWidth;

      if (_isOverflowing && mounted) {
        _startScrolling();
      }
    }
  }

  void _startScrolling() async {
    if (!mounted || !_scrollController.hasClients) return;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 30).toInt()),
        curve: Curves.linear,
      );

      if (mounted && _scrollController.hasClients) {
        await Future.delayed(const Duration(seconds: 1));
        await _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: (maxScroll * 30).toInt()),
          curve: Curves.linear,
        );
        _startScrolling(); // Loop
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
