import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/announcement_provider.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _hoveredAnnouncementId;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementProvider>(context, listen: false)
          .fetchAnnouncements();
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 200,
        imageQuality: 85,
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = imageBytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  void _showAddAnnouncementDialog() {
    final authService = Provider.of<AuthService>(context, listen: true);
    if (!authService.isAdmin() && !authService.canManageAnnouncements()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duyuru ekleme yetkiniz yok!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AddAnnouncementDialog();
      },
    );
  }

  // Image URL'leri güvenli şekilde parse eden helper fonksiyon
  List<String> _parseImageUrls(dynamic imageUrlData) {
    if (imageUrlData == null) return [];
    
    if (imageUrlData is List) {
      // Zaten bir liste ise, her elemanı String'e çevir
      return imageUrlData.map((url) => url.toString()).toList();
    } else if (imageUrlData is String) {
      // Tek bir String ise, içinde array notation varsa parse et
      if (imageUrlData.startsWith('{') && imageUrlData.endsWith('}')) {
        // PostgreSQL array format: {url1,url2,url3}
        final content = imageUrlData.substring(1, imageUrlData.length - 1);
        if (content.isEmpty) return [];
        return content.split(',').map((url) => url.trim()).toList();
      } else {
        // Normal string ise tek eleman olarak döndür
        return [imageUrlData];
      }
    }
    
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final announcementProvider = Provider.of<AnnouncementProvider>(context);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 0, 0), // Açık mavi arka plan

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0B2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: announcementProvider.isLoading &&
                announcementProvider.announcements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Duyurular yükleniyor...',
                      style: TextStyle(
                        color: Color(0xFF6A1B9A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFF6A1B9A),
                backgroundColor: Colors.black,
                onRefresh: () =>
                    announcementProvider.fetchAnnouncements(forceRefresh: true),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: announcementProvider.announcements.length,
                    itemBuilder: (context, index) {
                      final announcement =
                          announcementProvider.announcements[index];
                      final announcementId = announcement['id'].toString();
                      final isSeen = announcement['is_seen'] ?? false;
                      final createdAt = DateTime.parse(announcement['created_at']);
                      final imageUrls = _parseImageUrls(announcement['image_url']);
                      final authorName = announcement['author_name'] ??
                          announcement['username'] ??
                          announcement['author_email'] ??
                          'Bilinmeyen Yazar';

                      return MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _hoveredAnnouncementId = announcementId;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _hoveredAnnouncementId = null;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF2D1B69).withOpacity(0.9),
                                const Color(0xFF1A0B2E).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6A1B9A).withOpacity(
                                  _hoveredAnnouncementId == announcementId ? 0.15 : 0.08
                                ),
                                blurRadius: _hoveredAnnouncementId == announcementId ? 20 : 10,
                                offset: const Offset(0, 4),
                                spreadRadius: _hoveredAnnouncementId == announcementId ? 2 : 0,
                              ),
                            ],
                            border: Border.all(
                              color: isSeen 
                                ? const Color(0xFF8E24AA).withOpacity(0.3)
                                : const Color(0xFF9C27B0),
                              width: isSeen ? 1 : 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (!isSeen) {
                                  announcementProvider.markAsSeen(announcementId);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // Okunmamış duyuru için gradient efekt
                                  if (!isSeen)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          gradient: LinearGradient(
                                            begin: Alignment.topRight,
                                            end: Alignment.bottomLeft,
                                            colors: [
                                              const Color(0xFF9C27B0).withOpacity(0.05),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Başlık
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12, 
                                            vertical: 6
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6A1B9A),
                                              Color(0xFF8E24AA),
                                            ],
                                          ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            announcement['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Görsel varsa göster
                                        if (imageUrls.isNotEmpty) ...[
                                          GestureDetector(
                                            onTap: () => _showImageGalleryDialog(context, imageUrls, 0),
                                            child: Center(
                                              child: Container(
                                                height: 200,
                                                width: 300,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color.fromARGB(255, 162, 175, 185).withOpacity(0.2),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      CachedNetworkImage(
                                                        imageUrl: imageUrls.first,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) => Container(
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                Color.fromARGB(255, 151, 170, 187).withOpacity(0.1),
                                                                Color.fromARGB(255, 147, 164, 177).withOpacity(0.1),
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child: CircularProgressIndicator(
                                                              valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 158, 173, 187)),
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget: (context, url, error) => Container(
                                                          color: Colors.grey.shade200,
                                                          child: const Icon(Icons.error, color: Colors.red),
                                                        ),
                                                      ),
                                                      if (imageUrls.length > 1)
                                                        Positioned(
                                                          right: 12,
                                                          bottom: 12,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              gradient: const LinearGradient(
                                                                colors: [
                                                                  Color(0xFF1E88E5),
                                                                  Color(0xFF42A5F5),
                                                                ],
                                                              ),
                                                              borderRadius: BorderRadius.circular(20),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors.black.withOpacity(0.3),
                                                                  blurRadius: 8,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Text(
                                                              '+${imageUrls.length - 1}',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        
                                        // İçerik
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1E88E5).withOpacity(0.1),
                            ),
                          ),
                          child: Linkify(
                            onOpen: (link) => _openLink(link.url),
                            text: announcement['content'],
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.white,
                            ),
                            linkStyle: const TextStyle(
                              color: Color(0xFF1E88E5),
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Alt bilgiler
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, 
                                            vertical: 12
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF1E88E5).withOpacity(0.05),
                                                const Color(0xFF42A5F5).withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1E88E5),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        authorName,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF1E88E5),
                                                        ),
                                                      ),
                                                      Text(
                                                        timeago.format(createdAt, locale: 'tr'),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFF1E88E5),
                                                      Color(0xFF42A5F5),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    _showSeenByDialog(announcementId);
                                                  },
                                                  icon: const Icon(
                                                    Icons.people_alt_outlined,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                  label: const Text(
                                                    'Görenler',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, 
                                                      vertical: 8
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Silme butonu (admin için)
                                  if (authService.isAdmin() &&
                                      _hoveredAnnouncementId == announcementId)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade500,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete, 
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: () => _confirmDelete(context, announcement),
                                          tooltip: 'Duyuruyu Sil',
                                        ),
                                      ),
                                    ),
                                  
                                  // Okunmamış işareti
                                  if (!isSeen)
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, 
                                          vertical: 4
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5722),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF5722).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'YENİ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  void _showImageGalleryDialog(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        final pageController = PageController(initialPage: initialIndex);
        double currentPage = initialIndex.toDouble();

        return StatefulBuilder(
          builder: (context, setState) {
            return Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    if (currentPage > 0) {
                      pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                    if (currentPage < imageUrls.length - 1) {
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PhotoViewGallery.builder(
                      itemCount: imageUrls.length,
                      pageController: pageController,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index.toDouble();
                        });
                      },
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: CachedNetworkImageProvider(imageUrls[index]),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 3,
                          heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
                          initialScale: PhotoViewComputedScale.contained,
                        );
                      },
                      scrollPhysics: const BouncingScrollPhysics(),
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      loadingBuilder: (context, event) => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.black.withOpacity(0.5)),
                          shape: MaterialStateProperty.all(const CircleBorder()),
                        ),
                      ),
                    ),
                    if (imageUrls.length > 1) ...[
                      Positioned(
                        bottom: 30,
                        child: DotsIndicator(
                          dotsCount: imageUrls.length,
                          position: currentPage,
                          decorator: DotsDecorator(
                            color: Colors.grey.shade600,
                            activeColor: Colors.white,
                            size: const Size.square(10.0),
                            activeSize: const Size(20.0, 10.0),
                            activeShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                      // Sol ok butonu
                      Positioned(
                        left: 20,
                        top: MediaQuery.of(context).size.height / 2 - 25,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                          onPressed: currentPage > 0 ? () {
                            pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } : null,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.black.withOpacity(0.5)),
                            shape: MaterialStateProperty.all(const CircleBorder()),
                          ),
                        ),
                      ),
                      // Sağ ok butonu
                      Positioned(
                        right: 20,
                        top: MediaQuery.of(context).size.height / 2 - 25,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                          onPressed: currentPage < imageUrls.length - 1 ? () {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } : null,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.black.withOpacity(0.5)),
                            shape: MaterialStateProperty.all(const CircleBorder()),
                          ),
                        ),
                      ),
                    ],
                    // Sayfa numarası gösterici
                    if (imageUrls.length > 1)
                      Positioned(
                        top: 60,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${currentPage.round() + 1} / ${imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    _showImageGalleryDialog(context, [imageUrl], 0);
  }

  void _showSeenByDialog(String announcementId) async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Duyuruyu Görenler'),
            content: Container(
              width: double.maxFinite,
              height: 400,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(DateTime.now().millisecondsSinceEpoch), // Her seferinde yeni bir key
                future: Provider.of<AnnouncementProvider>(context, listen: false)
                    .getAllUsersWithSeenStatus(announcementId),
                builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }
                
                final users = snapshot.data ?? [];
                
                if (users.isEmpty) {
                  return const Center(
                    child: Text('Henüz hiç kullanıcı bulunmuyor.'),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    setDialogState(() {});
                  },
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final fullName = user['name'] as String? ?? 
                                     user['email'] as String? ?? 
                                     'Bilinmeyen Kullanıcı';
                      final seenAt = user['seen_at'] as String?;
                      final hasSeen = seenAt != null; // seen_at varsa görülmüş demek
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty
                              ? NetworkImage(user['avatar_url'] as String)
                              : null,
                          onBackgroundImageError: user['avatar_url'] != null 
                              ? (exception, stackTrace) {
                                  // Resim yüklenemezse harf avatarına geç
                                  print('Avatar yüklenemedi: $exception');
                                }
                              : null,
                          child: user['avatar_url'] == null || user['avatar_url'].toString().isEmpty
                              ? Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(fullName),
                        subtitle: hasSeen && seenAt != null
                            ? Text(
                                'Görüldü: ${_formatDateTime(DateTime.parse(seenAt))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              )
                            : Text(
                                'Henüz görülmedi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasSeen) ...[
                              // Çift tik - okuyanlar için
                              const Icon(
                                Icons.done,
                                size: 16,
                                color: Color.fromARGB(191, 197, 202, 1),
                              ),
                              const Icon(
                                Icons.done,
                                size: 16,
                                color: Color.fromRGBO(191, 197, 202, 1),
                              ),
                            ] else ...[
                              // Tek tik - okumayanlar için
                              Icon(
                                Icons.done,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Dialog'u yenile
                  setDialogState(() {});
                },
                child: const Text('Yenile'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Silmeyi Onayla'),
          content: const Text('Bu duyuruyu silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                final announcementId = announcement['id'];
                final imageUrls = _parseImageUrls(announcement['image_url']);
                Provider.of<AnnouncementProvider>(context, listen: false)
                    .deleteAnnouncement(announcementId, imageUrls);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openLink(String? url) async {
    if (url == null) return;

    // Güvenlik onay dialog'u göster
    final bool? shouldOpen = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dış Bağlantı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bu bağlantıya yönlendirilmek istediğinizden emin misiniz?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Aç'),
            ),
          ],
        );
      },
    );

    // Kullanıcı "Aç" seçtiyse linki aç
    if (shouldOpen == true) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Link açılamadı: $url')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Geçersiz link: $url')),
          );
        }
      }
    }
  }
}

class AddAnnouncementDialog extends StatefulWidget {
  @override
  _AddAnnouncementDialogState createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<AddAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Uint8List> _imageBytesList = [];
  List<String> _imageNames = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 90, // Yüksek kalite
      );

      if (pickedFiles.isNotEmpty) {
        List<Uint8List> newBytesList = [];
        List<String> newNamesList = [];
        
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          // Dosya boyutu kontrolü (5MB limit)
          if (bytes.lengthInBytes <= 5 * 1024 * 1024) {
            newBytesList.add(bytes);
            newNamesList.add(file.name);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${file.name} dosyası çok büyük (Max: 5MB)'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
        
        setState(() {
          // Mevcut görsellere yeni görselleri ekle (üzerine yazma)
          _imageBytesList.addAll(newBytesList);
          _imageNames.addAll(newNamesList);
        });
        
        if (mounted && newBytesList.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newBytesList.length} yeni görsel eklendi. Toplam: ${_imageBytesList.length}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel seçilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Duyuru Ekle'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  maxLength: 256,
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                  validator: (value) =>
                      value!.isEmpty ? 'Başlık boş olamaz' : null,
                ),
                TextFormField(
                  maxLength: 256,
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: 'İçerik'),
                  maxLines: 4,
                  validator: (value) =>
                      value!.isEmpty ? 'İçerik boş olamaz' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: Text('Görsel Seç (${_imageBytesList.length})'),
                    ),
                    if (_imageBytesList.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _imageBytesList.clear();
                            _imageNames.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, color: Colors.red),
                        label: const Text('Tümünü Sil', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
                if (_imageBytesList.isNotEmpty)
                  Container(
                    height: 120,
                    margin: const EdgeInsets.only(top: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageBytesList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _imageBytesList[index], 
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _imageBytesList.removeAt(index);
                                      _imageNames.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (_imageBytesList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${_imageBytesList.length} görsel seçildi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  print("🔘 'Ekle' butonuna tıklandı.");
                  if (_formKey.currentState!.validate()) {
                    print("✅ Form doğrulandı, yükleme başlıyor...");
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      await Provider.of<AnnouncementProvider>(context,
                              listen: false)
                          .addAnnouncement(
                        _titleController.text,
                        _contentController.text,
                        _imageBytesList.isNotEmpty ? _imageBytesList : null,
                        _imageNames.isNotEmpty ? _imageNames : null,
                      );
                      // Duyuru eklendikten sonra listeyi yenile
                      if (mounted) {
                        Provider.of<AnnouncementProvider>(context, listen: false)
                            .fetchAnnouncements(forceRefresh: true);
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Duyuru eklenemedi: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ekle'),
        ),
      ],
    );
  }
}