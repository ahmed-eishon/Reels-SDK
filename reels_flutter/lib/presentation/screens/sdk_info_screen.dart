import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:reels_flutter/core/pigeon_generated.dart';
import 'package:reels_flutter/core/services/access_token_service.dart';
import 'package:reels_flutter/core/di/injection_container.dart';

/// SDK Info and Debug Screen
///
/// Shows all data passed from native to Flutter:
/// - Access token
/// - Collect context data
/// - SDK version and info
/// - Platform details
class SdkInfoScreen extends StatefulWidget {
  final CollectData? collectData;

  const SdkInfoScreen({
    super.key,
    this.collectData,
  });

  @override
  State<SdkInfoScreen> createState() => _SdkInfoScreenState();
}

class _SdkInfoScreenState extends State<SdkInfoScreen> {
  String? _accessToken;
  bool _isLoadingToken = false;
  String? _tokenError;
  bool _tokenTested = false;

  // Performance tracking
  double _currentFps = 0.0;
  int _memoryUsageMB = 0;
  Timer? _performanceTimer;
  final List<Duration> _frameTimes = [];
  int _frameCount = 0;

  // Collect context expansion state
  bool _isCollectExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
    _startPerformanceTracking();
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAccessToken() async {
    setState(() {
      _isLoadingToken = true;
      _tokenError = null;
    });

    try {
      final tokenService = sl<AccessTokenService>();
      final token = await tokenService.getAccessToken();

      setState(() {
        _accessToken = token;
        _isLoadingToken = false;
        _tokenTested = true;
      });
    } catch (e) {
      setState(() {
        _tokenError = e.toString();
        _isLoadingToken = false;
        _tokenTested = true;
      });
    }
  }

  void _startPerformanceTracking() {
    // Track frame rendering for FPS calculation
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _onFrame();
    });

    // Update performance metrics every second
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        // Calculate FPS from frame count
        _currentFps = _frameCount.toDouble();
        _frameCount = 0;

        // Get memory usage (iOS only, approximate)
        try {
          final info = ProcessInfo.currentRss;
          _memoryUsageMB = (info / (1024 * 1024)).round();
        } catch (e) {
          _memoryUsageMB = 0;
        }
      });
    });
  }

  void _onFrame() {
    if (!mounted) return;

    _frameCount++;
    final now = DateTime.now();
    _frameTimes.add(Duration(milliseconds: now.millisecondsSinceEpoch));

    // Keep only last 60 frames
    if (_frameTimes.length > 60) {
      _frameTimes.removeAt(0);
    }

    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _onFrame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'SDK Info & Debug',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Access Token Section
          _buildSectionHeader('Access Token', Icons.vpn_key),
          _AccessTokenCard(
            onLoadToken: _loadAccessToken,
            accessToken: _accessToken,
            isLoading: _isLoadingToken,
            tokenError: _tokenError,
            tokenTested: _tokenTested,
          ),
          const SizedBox(height: 24),

          // Collect Data Section
          _buildSectionHeader('Collect Context', Icons.collections_bookmark),
          _buildCollectDataCard(),
          const SizedBox(height: 24),

          // Performance Metrics Section
          _buildSectionHeader('Performance Metrics', Icons.speed),
          _buildPerformanceMetricsCard(),
          const SizedBox(height: 24),

          // Platform Information Section
          _buildSectionHeader('Platform Information', Icons.phone_android),
          _buildPlatformInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCollectDataCard() {
    final hasData = widget.collectData != null;

    return InkWell(
      onTap: hasData
          ? () {
              setState(() {
                _isCollectExpanded = !_isCollectExpanded;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasData ? Colors.green : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: !hasData
            ? Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No collect data available',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Open reels from a collect to see data',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapsible header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Collect Data Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _isCollectExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),

                  // Collapsed state - show quick summary
                  if (!_isCollectExpanded) ...[
                    const SizedBox(height: 12),
                    Text(
                      'ID: ${widget.collectData!.id}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.collectData!.name != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Name: ${widget.collectData!.name}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Tap to view all details',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Expanded state - show all fields
                  if (_isCollectExpanded) ...[
                    const SizedBox(height: 16),
                    _buildDataField('ID', widget.collectData!.id),
                    if (widget.collectData!.name != null)
                      _buildDataField('Name', widget.collectData!.name!),
                    if (widget.collectData!.content != null)
                      _buildDataField('Content', widget.collectData!.content!),
                    if (widget.collectData!.userName != null)
                      _buildDataField('User Name', widget.collectData!.userName!),
                    if (widget.collectData!.likes != null)
                      _buildDataField(
                        'Likes',
                        widget.collectData!.likes.toString(),
                      ),
                    if (widget.collectData!.comments != null)
                      _buildDataField(
                        'Comments',
                        widget.collectData!.comments.toString(),
                      ),
                    if (widget.collectData!.recollects != null)
                      _buildDataField(
                        'Recollects',
                        widget.collectData!.recollects.toString(),
                      ),
                    if (widget.collectData!.isLiked != null)
                      _buildDataField(
                        'Is Liked',
                        widget.collectData!.isLiked! ? 'Yes' : 'No',
                      ),
                    if (widget.collectData!.isCollected != null)
                      _buildDataField(
                        'Is Collected',
                        widget.collectData!.isCollected! ? 'Yes' : 'No',
                      ),
                    if (widget.collectData!.itemName != null)
                      _buildDataField('Item Name', widget.collectData!.itemName!),
                    if (widget.collectData!.trackingTag != null)
                      _buildDataField(
                        'Tracking Tag',
                        widget.collectData!.trackingTag!,
                      ),
                    if (widget.collectData!.imageUrl != null)
                      _buildDataField('Image URL', widget.collectData!.imageUrl!),
                    if (widget.collectData!.itemImageUrl != null)
                      _buildDataField(
                        'Item Image URL',
                        widget.collectData!.itemImageUrl!,
                      ),
                    if (widget.collectData!.userProfileImage != null)
                      _buildDataField(
                        'User Profile Image',
                        widget.collectData!.userProfileImage!,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to collapse',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildPerformanceMetricsCard() {
    // Determine FPS health color
    Color fpsColor = Colors.green;
    if (_currentFps < 30) {
      fpsColor = Colors.red;
    } else if (_currentFps < 50) {
      fpsColor = Colors.orange;
    }

    // Determine memory health color
    Color memoryColor = Colors.green;
    if (_memoryUsageMB > 500) {
      memoryColor = Colors.red;
    } else if (_memoryUsageMB > 300) {
      memoryColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Real-time Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.auto_graph,
                color: Colors.blue,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // FPS Meter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'FPS',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Text(
                      _currentFps.toStringAsFixed(0),
                      style: TextStyle(
                        color: fpsColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentFps / 60).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade800,
                          valueColor: AlwaysStoppedAnimation<Color>(fpsColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Memory Usage
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Memory',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  _memoryUsageMB > 0 ? '${_memoryUsageMB} MB' : 'N/A',
                  style: TextStyle(
                    color: memoryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Frame count
          _buildDataField(
            'Frame Count',
            _frameTimes.length.toString(),
          ),

          const SizedBox(height: 12),
          Text(
            'Target: 60 FPS for smooth playback',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 2),
      ),
      child: Column(
        children: [
          _buildDataField('Platform', Theme.of(context).platform.name),
          _buildDataField(
            'Screen Size',
            '${MediaQuery.of(context).size.width.toInt()} x ${MediaQuery.of(context).size.height.toInt()}',
          ),
          _buildDataField(
            'Pixel Ratio',
            MediaQuery.of(context).devicePixelRatio.toStringAsFixed(2),
          ),
          _buildDataField(
            'Text Scale',
            MediaQuery.of(context).textScaleFactor.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Widget _buildDataField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateful widget for Access Token card to prevent page flickering
class _AccessTokenCard extends StatelessWidget {
  final VoidCallback onLoadToken;
  final String? accessToken;
  final bool isLoading;
  final String? tokenError;
  final bool tokenTested;

  const _AccessTokenCard({
    required this.onLoadToken,
    required this.accessToken,
    required this.isLoading,
    required this.tokenError,
    required this.tokenTested,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokenTested
              ? (accessToken != null ? Colors.green : Colors.red)
              : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Access Token Status',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: onLoadToken,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Status indicator
          Row(
            children: [
              Icon(
                tokenTested
                    ? (accessToken != null ? Icons.check_circle : Icons.error)
                    : Icons.pending,
                color: tokenTested
                    ? (accessToken != null ? Colors.green : Colors.red)
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tokenTested
                    ? (accessToken != null ? 'Token Available' : 'Token Error')
                    : 'Not Tested',
                style: TextStyle(
                  color: tokenTested
                      ? (accessToken != null ? Colors.green : Colors.red)
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Token value or error
          if (tokenError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade800),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tokenError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (accessToken != null)
            Builder(
              builder: (context) {
                final token = accessToken!;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Token Value',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            color: Colors.blue,
                            onPressed: () => _copyToClipboard(
                              context,
                              token,
                              'Access token',
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        token,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Length: ${token.length} characters',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          else if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Loading token...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Tap refresh to test token',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
