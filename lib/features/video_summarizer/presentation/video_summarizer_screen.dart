import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';

class VideoSummarizerScreen extends StatefulWidget {
  const VideoSummarizerScreen({super.key});

  @override
  State<VideoSummarizerScreen> createState() => _VideoSummarizerScreenState();
}

class _VideoSummarizerScreenState extends State<VideoSummarizerScreen> {
  static const _mlBaseUrl = 'http://172.16.130.166:5003';
  static const _boxName = 'video_summaries';

  final _picker = ImagePicker();
  final _urlController = TextEditingController();
  late final http.Client _longClient = IOClient(
    HttpClient()..connectionTimeout = const Duration(minutes: 10)
      ..idleTimeout = const Duration(minutes: 10),
  );

  XFile? _selectedVideo;
  bool _processing = false;
  String? _error;
  Map<String, dynamic>? _textResult;
  bool _showSaved = false;
  List<Map<String, dynamic>> _savedSummaries = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _longClient.close();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    final box = Hive.box<Map>(_boxName);
    setState(() {
      _savedSummaries = box.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
        ..sort((a, b) =>
            (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    });
  }

  Future<void> _saveSummary() async {
    if (_textResult == null) return;
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    final box = Hive.box<Map>(_boxName);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, {
      'id': id,
      'title': _textResult!['title'] ?? 'Untitled',
      'summary': _textResult!['summary'] ?? '',
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _loadSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary saved!')),
      );
    }
  }

  Future<void> _deleteSummary(String id) async {
    final box = Hive.box<Map>(_boxName);
    await box.delete(id);
    await _loadSaved();
  }

  void _reset() {
    setState(() {
      _selectedVideo = null;
      _processing = false;
      _error = null;
      _textResult = null;
      _urlController.clear();
    });
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
        _error = null;
        _textResult = null;
      });
    }
  }

  Future<void> _summarizeFile() async {
    if (_selectedVideo == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$_mlBaseUrl/text-summarize');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
          await http.MultipartFile.fromPath('video', _selectedVideo!.path));
      final streamed = await _longClient.send(request).timeout(
            const Duration(minutes: 10),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        setState(() => _textResult = jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        setState(() => _error = body['error'] ?? 'Summarization failed');
      }
    } catch (e) {
      setState(() => _error = 'Connection error: Make sure the ML server is running on port 5003');
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _summarizeUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _processing = true;
      _error = null;
      _textResult = null;
    });

    try {
      final response = await _longClient.post(
        Uri.parse('$_mlBaseUrl/url-summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url, 'mode': 'text'}),
      ).timeout(const Duration(minutes: 10));

      if (response.statusCode == 200) {
        setState(() => _textResult = jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        setState(() => _error = body['error'] ?? 'Failed');
      }
    } on http.ClientException {
      setState(() => _error = 'Connection error: Make sure the ML server is running on port 5003');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showSaved ? 'Saved Summaries' : 'Video Summarizer'),
        actions: [
          if (_textResult != null && !_showSaved)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise),
              onPressed: _reset,
            ),
          IconButton(
            icon: Icon(
              _showSaved
                  ? PhosphorIconsBold.videoCamera
                  : PhosphorIconsBold.bookmarkSimple,
              size: 22,
            ),
            tooltip: _showSaved ? 'New Summary' : 'Saved Summaries',
            onPressed: () => setState(() => _showSaved = !_showSaved),
          ),
        ],
      ),
      body: _showSaved ? _buildSavedList(theme) : _buildSummarizer(theme),
    );
  }

  Widget _buildSavedList(ThemeData theme) {
    if (_savedSummaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.bookmarkSimple,
                size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text('No saved summaries yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: AppSpacing.xs),
            Text('Summarize a video and tap Save',
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _savedSummaries.length,
      itemBuilder: (context, index) {
        final item = _savedSummaries[index];
        final title = item['title'] as String? ?? 'Untitled';
        final summary = item['summary'] as String? ?? '';
        final createdAt = item['createdAt'] as String? ?? '';
        final date = DateTime.tryParse(createdAt);
        final dateLabel = date != null
            ? '${date.day}/${date.month}/${date.year}'
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AntCard(
            elevation: AntCardElevation.soft,
            onTap: () => _showSavedDetail(item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsBold.filmSlate,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(dateLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => _deleteSummary(item['id'] as String),
                      child: Icon(PhosphorIconsRegular.trash,
                          size: 16, color: theme.colorScheme.error),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 50 + index * 40),
              duration: 300.ms,
            );
      },
    );
  }

  void _showSavedDetail(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(item['title'] as String? ?? '',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(item['summary'] as String? ?? '',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarizer(ThemeData theme) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input options
          if (_textResult == null) ...[
            // Upload file
            Text('Upload a Video', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: _processing ? null : _pickVideo,
              child: AntCard(
                elevation: AntCardElevation.soft,
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: _selectedVideo != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsBold.filmSlate,
                                  size: 32, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  _selectedVideo!.name,
                                  style: theme.textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(PhosphorIconsRegular.uploadSimple,
                                  size: 36,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: AppSpacing.xs),
                              Text('Tap to select video',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            if (_selectedVideo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _processing ? null : _summarizeFile,
                  icon: _processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(PhosphorIconsBold.sparkle, size: 18),
                  label: Text(_processing ? 'Processing...' : 'Summarize'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),

            // OR divider
            Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('OR', style: theme.textTheme.labelSmall),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // YouTube URL
            Text('YouTube URL', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                prefixIcon: const Icon(PhosphorIconsRegular.youtubeLogo, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _processing ? null : _summarizeUrl,
                child: Text(_processing ? 'Processing...' : 'Summarize from URL'),
              ),
            ),
          ],

          // Error
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AntCard(
              elevation: AntCardElevation.flat,
              color: AppColors.errorContainer,
              child: Row(
                children: [
                  const Icon(PhosphorIconsBold.warning, size: 18, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(_error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],

          // Text result
          if (_textResult != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _TextSummaryResult(data: _textResult!),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saveSummary,
                icon: const Icon(PhosphorIconsBold.bookmarkSimple, size: 18),
                label: const Text('Save Summary'),
              ),
            ),
          ],

          // Processing indicator
          if (_processing) ...[
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text('Analyzing video with ML models...',
                      style: theme.textTheme.bodySmall),
                  Text('This may take a minute',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _TextSummaryResult extends StatelessWidget {
  const _TextSummaryResult({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = data['title'] as String? ?? '';
    final summary = data['summary'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(title, style: theme.textTheme.titleLarge)
              .animate().fadeIn(duration: 400.ms),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(summary, style: theme.textTheme.bodyMedium)
              .animate().fadeIn(delay: 100.ms, duration: 400.ms),
        ],
      ],
    );
  }
}
