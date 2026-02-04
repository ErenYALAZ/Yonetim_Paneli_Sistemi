import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:ornek_flutter_web/theme/app_theme.dart';

class AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final Function(String) onOpenLink;
  final Function(String) onShowSeenBy;
  final Function(Map<String, dynamic>) onDelete;
  final Function(List<String>, int) onShowGallery;
  final bool isAdmin;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    required this.onOpenLink,
    required this.onShowSeenBy,
    required this.onDelete,
    required this.onShowGallery,
    required this.isAdmin,
  }) : super(key: key);

  List<String> _parseImageUrls(dynamic imageUrlData) {
    if (imageUrlData == null) return [];
    
    if (imageUrlData is String) {
      return [imageUrlData];
    } else if (imageUrlData is List) {
      return imageUrlData.map((url) => url.toString()).toList();
    }
    
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final title = announcement['title'] as String? ?? 'Başlıksız Duyuru';
    final content = announcement['content'] as String? ?? '';
    final createdAt = announcement['created_at'] != null
        ? DateTime.parse(announcement['created_at'] as String)
        : DateTime.now();
    final authorName = announcement['author_name'] as String? ?? 'Bilinmeyen';
    final isSeen = announcement['is_seen'] as bool? ?? false;
    final imageUrls = _parseImageUrls(announcement['image_url']);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSeen 
                ? [AppTheme.darkSurface, AppTheme.darkSurface]
                : [AppTheme.darkSurface, Color(0xFF1A365D)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: isSeen ? AppTheme.darkBorder : AppTheme.primaryColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {}, // Duyuru detayı için
              splashColor: AppTheme.primaryColor.withOpacity(0.1),
              highlightColor: AppTheme.primaryColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: AppTheme.lightText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isSeen)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'YENİ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.5, end: 0),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imageUrls.isNotEmpty) ...[                      
                      GestureDetector(
                        onTap: () => onShowGallery(imageUrls, 0),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.1),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrls[0],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) => const Center(
                                    child: Icon(Icons.error, color: Colors.red, size: 40),
                                  ),
                                ),
                              ),
                              if (imageUrls.length > 1)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.photo_library,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${imageUrls.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                    ],
                    Linkify(
                      onOpen: (link) => onOpenLink(link.url),
                      text: content,
                      style: Theme.of(context).textTheme.bodyMedium,
                      linkStyle: TextStyle(color: AppTheme.secondaryColor),
                      options: const LinkifyOptions(humanize: false),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: Theme.of(context).textTheme.labelLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      timeago.format(createdAt, locale: 'tr'),
                                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                        color: AppTheme.disabledText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => onDelete(announcement),
                                tooltip: 'Sil',
                              ),
                            TextButton.icon(
                              icon: Icon(
                                isSeen ? Icons.visibility : Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: const Text('Görenler'),
                              onPressed: () => onShowSeenBy(announcement['id']),
                              style: TextButton.styleFrom(
                                foregroundColor: isSeen ? AppTheme.secondaryColor : AppTheme.disabledText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}