import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const ImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late final PageController _page;
  var _showUi = true;

  @override
  void initState() {
    super.initState();
    _page = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showUi
          ? AppBar(
        backgroundColor: Colors.black87,
        title: Text('${_page.hasClients ? _page.page?.round() ?? widget.initialIndex : widget.initialIndex + 1}/${imgs.length}'),
      )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showUi = !_showUi),
        child: PageView.builder(
          controller: _page,
          itemCount: imgs.length,
          itemBuilder: (_, i) {
            final url = imgs[i];
            return Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: 'img-hero-$url',
                  // نستخدم CachedNetworkImage لعرض الصورة
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
