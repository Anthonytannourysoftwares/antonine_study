import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../data/api/api_client.dart';
import '../../../data/repositories/study_repository.dart';

class CourseMaterialsScreen extends ConsumerWidget {
  const CourseMaterialsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  final String courseId;
  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BrowseFolder(
      courseId: courseId,
      courseName: courseName,
      subPath: '',
    );
  }
}

class _BrowseFolder extends StatefulWidget {
  const _BrowseFolder({
    required this.courseId,
    required this.courseName,
    required this.subPath,
  });

  final String courseId;
  final String courseName;
  final String subPath;

  @override
  State<_BrowseFolder> createState() => _BrowseFolderState();
}

class _BrowseFolderState extends State<_BrowseFolder> {
  List<String> _folders = [];
  List<Map<String, dynamic>> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pathParam = widget.subPath.isNotEmpty
          ? '?path=${Uri.encodeComponent(widget.subPath)}'
          : '';
      final url =
          '${ApiClient.baseUrl}/courses/${widget.courseId}/browse$pathParam';
      debugPrint('BROWSE URL: $url');
      final response = await http.get(Uri.parse(url));
      debugPrint('BROWSE STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _folders = (data['folders'] as List).cast<String>();
          _files = (data['files'] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not load materials';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('BROWSE ERROR: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _title {
    if (widget.subPath.isEmpty) return widget.courseName;
    final parts = widget.subPath.split('/');
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: AppSpacing.paddingAllXl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.wifiSlash,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.tonal(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _folders.isEmpty && _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.folderOpen,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.md),
                          Text('Empty folder',
                              style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: AppSpacing.screenPadding,
                      itemCount: _folders.length + _files.length,
                      itemBuilder: (context, index) {
                        if (index < _folders.length) {
                          return _FolderCard(
                            name: _folders[index],
                            index: index,
                            onTap: () {
                              final newPath = widget.subPath.isEmpty
                                  ? _folders[index]
                                  : '${widget.subPath}/${_folders[index]}';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _BrowseFolder(
                                    courseId: widget.courseId,
                                    courseName: widget.courseName,
                                    subPath: newPath,
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        final fileIndex = index - _folders.length;
                        final file = _files[fileIndex];
                        final filePath = widget.subPath.isEmpty
                            ? file['name'] as String
                            : '${widget.subPath}/${file['name']}';

                        return _FileCard(
                          courseId: widget.courseId,
                          fileName: file['name'] as String,
                          filePath: filePath,
                          fileSize: file['size'] as int,
                          index: fileIndex,
                        );
                      },
                    ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.name,
    required this.index,
    required this.onTap,
  });

  final String name;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AntCard(
        elevation: AntCardElevation.soft,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(PhosphorIconsBold.folder,
                  size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(PhosphorIconsRegular.caretRight,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 50 + index * 30),
          duration: 300.ms,
        );
  }
}

class _FileCard extends StatefulWidget {
  const _FileCard({
    required this.courseId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.index,
  });
  final String courseId;
  final String fileName;
  final String filePath;
  final int fileSize;
  final int index;

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard> {
  static const _mlBaseUrl = 'http://172.16.130.166:5003';
  bool _downloading = false;
  bool _summarizing = false;

  IconData _iconForFile(String name) {
    final l = name.toLowerCase();
    if (l.endsWith('.pdf')) return PhosphorIconsRegular.filePdf;
    if (l.endsWith('.jpg') || l.endsWith('.jpeg') || l.endsWith('.png'))
      return PhosphorIconsRegular.image;
    if (l.endsWith('.zip')) return PhosphorIconsRegular.fileZip;
    if (l.endsWith('.docx') || l.endsWith('.doc'))
      return PhosphorIconsRegular.fileDoc;
    if (l.endsWith('.xlsx') || l.endsWith('.xls'))
      return PhosphorIconsRegular.fileXls;
    if (l.endsWith('.pptx') || l.endsWith('.ppsm'))
      return PhosphorIconsRegular.filePpt;
    if (l.endsWith('.c') ||
        l.endsWith('.java') ||
        l.endsWith('.py') ||
        l.endsWith('.cs') ||
        l.endsWith('.js') ||
        l.endsWith('.m') ||
        l.endsWith('.php'))
      return PhosphorIconsRegular.fileCode;
    return PhosphorIconsRegular.file;
  }

  Color _colorForFile(String name) {
    final l = name.toLowerCase();
    if (l.endsWith('.pdf')) return AppColors.error;
    if (l.endsWith('.jpg') || l.endsWith('.jpeg') || l.endsWith('.png'))
      return AppColors.tertiary;
    if (l.endsWith('.zip')) return AppColors.warning;
    if (l.endsWith('.xlsx') || l.endsWith('.xls')) return AppColors.tertiary;
    return AppColors.primary;
  }

  String _displayName(String name) {
    return name.replaceAll('_', ' ').replaceAll(RegExp(r'\.[^.]+$'), '').trim();
  }

  String _extension(String name) {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openFile() async {
    setState(() => _downloading = true);

    try {
      final folder = widget.filePath.contains('/')
          ? widget.filePath.substring(0, widget.filePath.lastIndexOf('/'))
          : '';
      final url =
          '${ApiClient.baseUrl}/courses/${widget.courseId}/download?folder=${Uri.encodeComponent(folder)}&file=${Uri.encodeComponent(widget.fileName)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.fileName}');
        await file.writeAsBytes(response.bodyBytes);
        await OpenFilex.open(file.path);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  bool get _isPdf => widget.fileName.toLowerCase().endsWith('.pdf');

  Future<void> _summarizePdf() async {
    setState(() => _summarizing = true);
    try {
      // Download the PDF from the backend
      final folder = widget.filePath.contains('/')
          ? widget.filePath.substring(0, widget.filePath.lastIndexOf('/'))
          : '';
      final downloadUrl =
          '${ApiClient.baseUrl}/courses/${widget.courseId}/download?folder=${Uri.encodeComponent(folder)}&file=${Uri.encodeComponent(widget.fileName)}';
      final pdfResponse = await http.get(Uri.parse(downloadUrl));
      if (pdfResponse.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download PDF')),
          );
        }
        return;
      }

      // Send to ML API
      final longClient = IOClient(
        HttpClient()..connectionTimeout = const Duration(minutes: 2),
      );
      final uri = Uri.parse('$_mlBaseUrl/pdf-summarize');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'pdf',
        pdfResponse.bodyBytes,
        filename: widget.fileName,
      ));
      final streamed = await longClient.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _showSummarySheet(data);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Summarization failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _summarizing = false);
    }
  }

  void _showSummarySheet(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(PhosphorIconsBold.sparkle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('AI Summary', style: theme.textTheme.titleMedium)),
                  FilledButton.icon(
                    onPressed: () async {
                      final repo = StudyRepository();
                      await repo.init();
                      await repo.saveFlashcard(
                        title: data['title'] as String? ?? '',
                        summary: data['summary'] as String? ?? '',
                        fileName: widget.fileName,
                        pages: data['pages'] as int? ?? 0,
                        totalWords: data['total_words'] as int? ?? 0,
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Saved to Flashcards')),
                        );
                      }
                    },
                    icon: const Icon(PhosphorIconsBold.floppyDisk, size: 16),
                    label: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['title'] as String? ?? '',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                data['summary'] as String? ?? '',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _InfoChip(label: '${data['pages'] ?? 0} pages'),
                  const SizedBox(width: 8),
                  _InfoChip(label: '${data['total_words'] ?? 0} words'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForFile(widget.fileName);
    final color = _colorForFile(widget.fileName);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AntCard(
        elevation: AntCardElevation.soft,
        onTap: _downloading ? null : _openFile,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(widget.fileName),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_extension(widget.fileName)}  ${_formatSize(widget.fileSize)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_isPdf && !_downloading)
              _summarizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : GestureDetector(
                      onTap: _summarizePdf,
                      child: Icon(PhosphorIconsBold.sparkle,
                          size: 20, color: AppColors.primary),
                    ),
            if (_isPdf && !_downloading) const SizedBox(width: 12),
            if (_downloading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(PhosphorIconsRegular.arrowSquareOut,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 50 + widget.index * 30),
          duration: 300.ms,
        );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.primary,
      )),
    );
  }
}
