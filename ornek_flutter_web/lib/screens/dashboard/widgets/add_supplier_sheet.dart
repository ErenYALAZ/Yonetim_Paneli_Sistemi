import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/supplier_tedarikci_model.dart';
import '../../../providers/supplier_tedarikci_provider.dart';

class AddSupplierSheet extends StatefulWidget {
  final SupplierTedarikci? supplier;

  const AddSupplierSheet({super.key, this.supplier});

  @override
  _AddSupplierSheetState createState() => _AddSupplierSheetState();
}

class _AddSupplierSheetState extends State<AddSupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  XFile? _imageFile;
  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _companyNameController =
        TextEditingController(text: widget.supplier?.companyName ?? '');
    _nameController =
        TextEditingController(text: widget.supplier?.supplierName ?? '');
    _emailController =
        TextEditingController(text: widget.supplier?.contactEmail ?? '');
    _phoneController =
        TextEditingController(text: widget.supplier?.contactPhone ?? '');
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
    });
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final supplierData = SupplierTedarikci(
        id: widget.supplier?.id ?? '',
        userId: '',
        companyName: _companyNameController.text,
        supplierName: _nameController.text,
        contactEmail: _emailController.text,
        contactPhone: _phoneController.text,
        profileImageUrl: widget.supplier?.profileImageUrl,
      );

      try {
        final provider = Provider.of<SupplierTedarikciProvider>(context, listen: false);
        if (_isEditing) {
          await provider.updateSupplier(supplierData, _imageFile);
        } else {
          await provider.addSupplier(supplierData, _imageFile);
        }

        if (mounted) Navigator.of(context).pop();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${_isEditing ? 'Güncelleme' : 'Ekleme'} başarısız oldu.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the image to display
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      backgroundImage = NetworkImage(_imageFile!.path); // For web
    } else if (_isEditing &&
        widget.supplier!.profileImageUrl != null &&
        widget.supplier!.profileImageUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(widget.supplier!.profileImageUrl!);
    }

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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_isEditing ? 'Tedarikçiyi Düzenle' : 'Yeni Tedarikçi Ekle',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF8B5CF6),
                      backgroundImage: backgroundImage,
                      child: backgroundImage == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                maxLength: 256,
                controller: _companyNameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Şirket Adı',
                  labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
              ),
              TextFormField(
                maxLength: 256,
                controller: _nameController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir ad soyad girin.';
                  }
                  return null;
                },
              ),
              TextFormField(
                maxLength: 256,
                controller: _emailController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                maxLength: 256,
                controller: _phoneController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  labelStyle: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.8),
                    ),
                    child: Text('İptal', style: GoogleFonts.poppins()),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Güncelle' : 'Kaydet',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _submitData,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}