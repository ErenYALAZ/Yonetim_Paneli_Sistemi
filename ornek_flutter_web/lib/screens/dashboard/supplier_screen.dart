import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/supplier_tedarikci_model.dart';
import '../../../providers/supplier_tedarikci_provider.dart';
import 'widgets/add_supplier_sheet.dart';
import 'package:ornek_flutter_web/services/auth_service.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  _SupplierScreenState createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the provider is already loading to avoid multiple requests
      final provider = Provider.of<SupplierTedarikciProvider>(context, listen: false);
      if (!provider.isLoading) {
        provider.fetchAndSetSuppliers();
      }
    });
  }

  void _showAddSupplierSheet(BuildContext context,
      [SupplierTedarikci? supplier]) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAdmin() && !authService.canManageSuppliers()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tedarikçi ekleme/düzenleme yetkiniz yok!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return AddSupplierSheet(supplier: supplier);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierTedarikciProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0A1A),
            Color(0xFF1A0B2E),
            Color(0xFF2D1B3D),
            Color(0xFF3E2A47),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF3B30), Color(0xFFFF006E)],
            ).createShader(bounds),
            child: Text(
              'Tedarikçiler',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      body: Consumer<SupplierTedarikciProvider>(
        builder: (ctx, supplierProvider, _) {
          if (supplierProvider.isLoading && supplierProvider.suppliers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            );
          }

          if (supplierProvider.suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz Tedarikçi Yok! 📦',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk tedarikçinizi eklemek için + butonuna tıklayın',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: supplierProvider.suppliers.length,
            itemBuilder: (ctx, i) {
              final supplier = supplierProvider.suppliers[i];
              return SupplierCard(
                supplier: supplier,
                index: i,
                isAdmin: authService.isAdmin() || authService.canManageSuppliers(),
                onEdit: () => _showAddSupplierSheet(context, supplier),
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Tedarikçiyi Sil'),
                        content: Text(
                            '${supplier.companyName ?? supplier.supplierName} adlı tedarikçiyi silmek istediğinizden emin misiniz?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('İptal'),
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Sil'),
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    try {
                      await Provider.of<SupplierTedarikciProvider>(context,
                              listen: false)
                          .deleteSupplier(
                              supplier.id, supplier.profileImageUrl);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Silme işlemi başarısız oldu.')),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
        ),
        floatingActionButton: (authService.isAdmin() || authService.canManageSuppliers())
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => _showAddSupplierSheet(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              )
            : null,
      ),
    );
  }
}

class SupplierCard extends StatefulWidget {
  final SupplierTedarikci supplier;
  final int index;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SupplierCard(
      {super.key,
      required this.supplier,
      required this.index,
      required this.isAdmin,
      required this.onEdit,
      required this.onDelete});

  @override
  _SupplierCardState createState() => _SupplierCardState();
}

class _SupplierCardState extends State<SupplierCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D1B3D),
              Color(0xFF3E2A47),
              Color(0xFF4A3356),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: _isHovered ? 25 : 15,
              spreadRadius: _isHovered ? 5 : 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            ListTile(
              leading: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: (widget.supplier.profileImageUrl != null &&
                        widget.supplier.profileImageUrl!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          widget.supplier.profileImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                widget.supplier.companyName?.isNotEmpty == true
                                    ? widget.supplier.companyName![0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.supplier.companyName?.isNotEmpty == true
                              ? widget.supplier.companyName![0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              horizontalTitleGap: 10,
              title: Text(
                widget.supplier.companyName ?? 'Şirket Adı Yok',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ad Soyad: ${widget.supplier.supplierName}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                  Text('Telefon: ${widget.supplier.contactPhone ?? 'yok'}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                  Text('Mail: ${widget.supplier.contactEmail ?? 'yok'}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
            if (widget.isAdmin && _isHovered)
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: widget.onEdit,
                        tooltip: 'Düzenle',
                        splashRadius: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                        onPressed: widget.onDelete,
                        tooltip: 'Sil',
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}