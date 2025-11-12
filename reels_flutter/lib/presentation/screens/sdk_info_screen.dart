import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.collectData != null ? Colors.green : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: widget.collectData == null
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
                // Header with copy button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collect Data from Native',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Collect data fields
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
