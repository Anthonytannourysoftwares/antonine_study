import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/ant_card.dart';
import '../../../data/api/api_client.dart';

final _itemsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/lost-found');
  return (response['items'] as List).cast<Map<String, dynamic>>();
});

class LostFoundScreen extends ConsumerStatefulWidget {
  const LostFoundScreen({super.key});

  @override
  ConsumerState<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends ConsumerState<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(_itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lost Items'),
            Tab(text: 'Found Items'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportDialog(context),
        icon: const Icon(PhosphorIconsBold.plus),
        label: const Text('Report'),
      ),
      body: itemsAsync.when(
        data: (items) {
          final lostItems =
              items.where((i) => i['type'] == 'lost').toList();
          final foundItems =
              items.where((i) => i['type'] == 'found').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ItemList(items: lostItems, emptyLabel: 'No lost items reported', onRefresh: () => ref.invalidate(_itemsProvider)),
              _ItemList(
                  items: foundItems, emptyLabel: 'No found items reported', onRefresh: () => ref.invalidate(_itemsProvider)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.wifiSlash,
                  size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load items', style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(_itemsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String type = 'lost';
    XFile? pickedImage;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report an Item', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'lost', label: Text('I Lost')),
                    ButtonSegment(value: 'found', label: Text('I Found')),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) =>
                      setSheetState(() => type = v.first),
                ),
                const SizedBox(height: AppSpacing.md),

                // Image picker
                GestureDetector(
                  onTap: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: ctx,
                      builder: (c) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(PhosphorIconsRegular.camera),
                              title: const Text('Take Photo'),
                              onTap: () =>
                                  Navigator.pop(c, ImageSource.camera),
                            ),
                            ListTile(
                              leading: const Icon(PhosphorIconsRegular.image),
                              title: const Text('Choose from Gallery'),
                              onTap: () =>
                                  Navigator.pop(c, ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (source == null) return;
                    final img = await picker.pickImage(
                      source: source,
                      imageQuality: 70,
                      maxWidth: 1200,
                    );
                    if (img != null) {
                      setSheetState(() => pickedImage = img);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      image: pickedImage != null
                          ? DecorationImage(
                              image: FileImage(File(pickedImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: pickedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIconsRegular.camera,
                                size: 36,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Add a photo',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                  onPressed: () =>
                                      setSheetState(() => pickedImage = null),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    hintText: 'e.g. Blue backpack',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Color, brand, distinguishing features...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g. Building A, Room 301',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                StatefulBuilder(
                  builder: (context, setButtonState) {
                    bool submitting = false;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          setButtonState(() => submitting = true);
                          try {
                            final api = ref.read(apiClientProvider);
                            await api.postMultipart(
                              '/lost-found',
                              fields: {
                                'type': type,
                                'title': titleCtrl.text.trim(),
                                'description': descCtrl.text.trim(),
                                'location': locationCtrl.text.trim(),
                              },
                              filePath: pickedImage?.path,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            ref.invalidate(_itemsProvider);
                          } catch (e) {
                            setButtonState(() => submitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                        child: submitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, required this.emptyLabel, required this.onRefresh});
  final List<Map<String, dynamic>> items;
  final String emptyLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: theme.textTheme.bodyLarge),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final imageUrl = item['image_url'] as String?;
        final hasImage = imageUrl != null && imageUrl.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AntCard(
            elevation: AntCardElevation.soft,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      '${ApiClient.baseUrl}${imageUrl!.replaceFirst('/api', '')}',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),

                // Content
                Padding(
                  padding: AppSpacing.paddingAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item['resolved'] == true
                                  ? AppColors.tertiary.withValues(alpha: 0.12)
                                  : (item['type'] == 'lost'
                                          ? AppColors.error
                                          : AppColors.tertiary)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['resolved'] == true
                                  ? 'RESOLVED'
                                  : item['type'] == 'lost'
                                      ? 'LOST'
                                      : 'FOUND',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: item['resolved'] == true
                                    ? AppColors.tertiary
                                    : item['type'] == 'lost'
                                        ? AppColors.error
                                        : AppColors.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(item['created_at']),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item['title'] ?? '',
                        style: theme.textTheme.titleSmall,
                      ),
                      if ((item['description'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(item['description'],
                            style: theme.textTheme.bodySmall),
                      ],
                      if ((item['location'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(PhosphorIconsRegular.mapPin,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              item['location'],
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item['resolved'] != true) ...[
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: _ResolveButton(
                            itemId: item['id'] as String,
                            onResolved: onRefresh,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms),
        );
      },
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ResolveButton extends StatefulWidget {
  const _ResolveButton({required this.itemId, required this.onResolved});
  final String itemId;
  final VoidCallback onResolved;

  @override
  State<_ResolveButton> createState() => _ResolveButtonState();
}

class _ResolveButtonState extends State<_ResolveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : () async {
        setState(() => _loading = true);
        try {
          final api = ApiClient();
          await api.put('/lost-found/${widget.itemId}/resolve');
          widget.onResolved();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
      icon: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(PhosphorIconsBold.checkCircle, size: 16),
      label: Text(_loading ? 'Resolving...' : 'Mark as Found'),
    );
  }
}

