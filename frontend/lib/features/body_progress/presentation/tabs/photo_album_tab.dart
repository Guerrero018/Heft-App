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
  final Set<int> _selectedIds = {};
  bool _compareMode = false;

  List<BodyMeasureEntry> get _photos {
    final list = widget.entries.where((e) => e.hasPhoto).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void _toggleSelect(BodyMeasureEntry entry) {
    setState(() {
      if (_selectedIds.contains(entry.id)) {
        _selectedIds.remove(entry.id);
      } else if (_selectedIds.length < 2) {
        _selectedIds.add(entry.id);
      } else {
        _selectedIds.clear();
        _selectedIds.add(entry.id);
      }
    });
  }

  void _openCompare() {
    if (_selectedIds.length != 2) return;
    final selected = _photos.where((e) => _selectedIds.contains(e.id)).toList();
    if (selected.length != 2) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoCompareScreen(
          before: selected[0],
          after: selected[1],
        ),
      ),
    );
  }

  void _openGallery(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoGalleryScreen(
          photos: _photos,
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
    if (_photos.isEmpty) {
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
                      ? 'Selecciona 2 fotos (${_selectedIds.length}/2)'
                      : '${_photos.length} fotos en tu línea temporal',
                  style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _compareMode = !_compareMode;
                    _selectedIds.clear();
                  });
                },
                icon: Icon(_compareMode ? Icons.close : Icons.compare, size: 18),
                label: Text(_compareMode ? 'Cancelar' : 'Comparar'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
        if (_compareMode && _selectedIds.length == 2)
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
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final entry = _photos[index];
              final isSelected = _selectedIds.contains(entry.id);
              final isFirst = index == _photos.length - 1;
              final isLatest = index == 0;

              return GestureDetector(
                onTap: () {
                  if (_compareMode) {
                    _toggleSelect(entry);
                  } else {
                    _openGallery(index);
                  }
                },
                onLongPress: () {
                  if (!_compareMode) {
                    setState(() {
                      _compareMode = true;
                      _selectedIds.add(entry.id);
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
                          imageUrl: entry.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppTheme.cardColor),
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
                            top: 8,
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
  final List<BodyMeasureEntry> photos;
  final int initialIndex;
  final void Function(BodyMeasureEntry a, BodyMeasureEntry b) onCompare;

  const _PhotoGalleryScreen({
    required this.photos,
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
                final current = widget.photos[_controller.page?.round() ?? 0];
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
              itemCount: widget.photos.length,
              itemBuilder: (_, i) {
                final e = widget.photos[i];
                return InteractiveViewer(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: e.photoUrl!,
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
                      final e = widget.photos[i.clamp(0, widget.photos.length - 1)];
                      return Text(
                        '${DateFormat('d MMMM yyyy', 'es').format(e.date)} · ${e.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.photos.length,
                      itemBuilder: (_, i) {
                        final e = widget.photos[i];
                        final selected = _compareWith?.id == e.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _compareWith = selected ? null : e;
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
                                imageUrl: e.photoUrl!,
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
