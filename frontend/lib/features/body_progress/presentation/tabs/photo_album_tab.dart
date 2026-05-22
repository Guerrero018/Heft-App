import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/body_measure_model.dart';
import '../photo_compare_screen.dart';
import '../widgets/body_progress_empty.dart';

class PhotoAlbumTab extends StatefulWidget {
  final List<BodyMeasureEntry> entries;

  const PhotoAlbumTab({super.key, required this.entries});

  @override
  State<PhotoAlbumTab> createState() => _PhotoAlbumTabState();
}

class _PhotoAlbumTabState extends State<PhotoAlbumTab> {
  final Set<int> _selectedEntryIds = {};
  bool _compareMode = false;

  List<AlbumPhotoItem> get _albumItems => flattenAlbumPhotos(widget.entries);

  void _toggleSelect(AlbumPhotoItem item) {
    setState(() {
      if (_selectedEntryIds.contains(item.entryId)) {
        _selectedEntryIds.remove(item.entryId);
      } else if (_selectedEntryIds.length < 2) {
        _selectedEntryIds.add(item.entryId);
      } else {
        _selectedEntryIds.clear();
        _selectedEntryIds.add(item.entryId);
      }
    });
  }

  void _openCompare() {
    if (_selectedEntryIds.length != 2) return;
    final ids = _selectedEntryIds.toList();
    final first = widget.entries.firstWhere((e) => e.id == ids[0]);
    final second = widget.entries.firstWhere((e) => e.id == ids[1]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoCompareScreen(before: first, after: second),
      ),
    );
  }

  void _openGallery(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoGalleryScreen(
          items: _albumItems,
          initialIndex: index,
          onCompare: (a, b) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoCompareScreen(before: a, after: b),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_albumItems.isEmpty) {
      return const BodyProgressEmpty(
        icon: Icons.photo_album_outlined,
        message:
            'Tu álbum está vacío.\nAñade fotos al registrar tu progreso para comparar la evolución.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _compareMode
                      ? 'Selecciona 2 registros (${_selectedEntryIds.length}/2)'
                      : '${_albumItems.length} fotos en tu línea temporal',
                  style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _compareMode = !_compareMode;
                    _selectedEntryIds.clear();
                  });
                },
                icon: Icon(_compareMode ? Icons.close : Icons.compare, size: 18),
                label: Text(_compareMode ? 'Cancelar' : 'Comparar'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
        if (_compareMode && _selectedEntryIds.length == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCompare,
                icon: const Icon(Icons.flip),
                label: const Text('Ver comparación'),
              ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: _albumItems.length,
            itemBuilder: (context, index) {
              final item = _albumItems[index];
              final entry = item.entry;
              final isSelected = _selectedEntryIds.contains(item.entryId);
              final isLatest = index == 0;
              final isFirst = index == _albumItems.length - 1;
              final moreInEntry = entry.photoUrls.length > 1;

              return GestureDetector(
                onTap: () {
                  if (_compareMode) {
                    _toggleSelect(item);
                  } else {
                    _openGallery(index);
                  }
                },
                onLongPress: () {
                  if (!_compareMode) {
                    setState(() {
                      _compareMode = true;
                      _selectedEntryIds.add(item.entryId);
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white10,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: item.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppTheme.cardColor),
                        ),
                        if (moreInEntry)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${item.photoIndex + 1}/${entry.photoUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (isLatest || isFirst)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? AppTheme.primaryColor
                                    : Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isLatest ? 'Actual' : 'Inicio',
                                style: TextStyle(
                                  color: isLatest ? Colors.black : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (isSelected)
                          const Positioned(
                            bottom: 8,
                            right: 8,
                            child: Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateFormat('d MMM yyyy', 'es').format(entry.date),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${entry.weight.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoGalleryScreen extends StatefulWidget {
  final List<AlbumPhotoItem> items;
  final int initialIndex;
  final void Function(BodyMeasureEntry a, BodyMeasureEntry b) onCompare;

  const _PhotoGalleryScreen({
    required this.items,
    required this.initialIndex,
    required this.onCompare,
  });

  @override
  State<_PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<_PhotoGalleryScreen> {
  late final PageController _controller;
  BodyMeasureEntry? _compareWith;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Álbum'),
        actions: [
          if (_compareWith != null)
            TextButton(
              onPressed: () {
                final i = _controller.page?.round() ?? 0;
                final current = widget.items[i.clamp(0, widget.items.length - 1)].entry;
                widget.onCompare(_compareWith!, current);
              },
              child: const Text('Comparar', style: TextStyle(color: AppTheme.primaryColor)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              itemBuilder: (_, i) {
                final item = widget.items[i];
                return InteractiveViewer(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: item.url,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final i = _controller.hasClients
                          ? (_controller.page ?? widget.initialIndex.toDouble()).round()
                          : widget.initialIndex;
                      final item = widget.items[i.clamp(0, widget.items.length - 1)];
                      final e = item.entry;
                      final photoLabel = e.photoUrls.length > 1
                          ? ' · foto ${item.photoIndex + 1}/${e.photoUrls.length}'
                          : '';
                      return Text(
                        '${DateFormat('d MMMM yyyy', 'es').format(e.date)} · ${e.weight.toStringAsFixed(1)} kg$photoLabel',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.items.length,
                      itemBuilder: (_, i) {
                        final item = widget.items[i];
                        final selected = _compareWith?.id == item.entryId;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _compareWith = selected ? null : item.entry;
                            });
                          },
                          child: Container(
                            width: 56,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppTheme.primaryColor : Colors.white24,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: item.url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca una miniatura y pulsa «Comparar» para ver antes/después',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
