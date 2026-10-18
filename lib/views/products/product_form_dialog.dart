import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/product_model.dart';
import '../../providers/catalog_provider.dart';
import '../../services/supabase_service.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormDialog({super.key, this.productToEdit});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String? _selectedCategoryId;
  bool _isSubmitting = false;

  // Local storage image picking state
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.name;
      _priceController.text = p.price.toStringAsFixed(0);
      _stockController.text = p.stock.toString();
      _imageUrlController.text = p.imageUrl ?? '';
      _selectedCategoryId = p.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromStorage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar dari galeri: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.category_rounded, color: AppColors.accentOrange, size: 20),
            SizedBox(width: 8),
            Text('Tambah Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama Kategori Baru',
            prefixIcon: Icon(Icons.label_outline, size: 18),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = catController.text.trim();
              if (name.isNotEmpty) {
                await ref.read(catalogProvider.notifier).addCategory(name);
                final categories = ref.read(catalogProvider).categories;
                final newlyAdded = categories.where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;
                if (newlyAdded != null) {
                  setState(() {
                    _selectedCategoryId = newlyAdded.id;
                  });
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      String? imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();

      // If user selected an image file from storage, upload it to Supabase Storage
      if (_selectedImageBytes != null) {
        final uploaded = await SupabaseService.instance.uploadProductImage(
          _selectedImageBytes!,
          _selectedImageName ?? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (uploaded != null) {
          imageUrl = uploaded;
        }
      }

      if (widget.productToEdit != null) {
        final updated = widget.productToEdit!.copyWith(
          name: name,
          price: price,
          stock: stock,
          categoryId: _selectedCategoryId,
          imageUrl: imageUrl,
        );
        await ref.read(catalogProvider.notifier).updateProduct(updated);
      } else {
        final newProduct = ProductModel(
          id: '',
          name: name,
          price: price,
          stock: stock,
          categoryId: _selectedCategoryId,
          imageUrl: imageUrl,
        );
        await ref.read(catalogProvider.notifier).addProduct(newProduct);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productToEdit != null ? 'Produk diperbarui!' : 'Produk baru ditambahkan!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan produk: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final isEditing = widget.productToEdit != null;

    final validCategories = catalogState.categories.where((c) => c.id != 'all').toList();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Product Name
                  const Text('Nama Produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Contoh: Kopi Susu Gula Aren'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),

                  // Category Dropdown + Add Category Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      InkWell(
                        onTap: _showAddCategoryDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add_rounded, size: 15, color: AppColors.accentOrange),
                              SizedBox(width: 3),
                              Text(
                                '+ Tambah Kategori',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accentOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(hintText: 'Pilih Kategori'),
                    items: validCategories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                  const SizedBox(height: 14),

                  // Price & Stock Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Harga Jual (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '0', prefixText: 'Rp '),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Harga wajib';
                                if (double.tryParse(v) == null) return 'Angka tidak valid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jumlah Stok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '0'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Stok wajib';
                                if (int.tryParse(v) == null) return 'Angka tidak valid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Foto Produk (Upload from Storage / Gallery or URL)
                  const Text('Foto Produk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  // Image Preview & Upload Button Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        if (_selectedImageBytes != null) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => setState(() {
                                      _selectedImageBytes = null;
                                      _selectedImageName = null;
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ] else if (_imageUrlController.text.trim().isNotEmpty) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _imageUrlController.text.trim(),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('Gagal memuat URL Gambar', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Button to pick image from local gallery/storage
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickImageFromStorage,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.accentOrange, width: 1.2),
                              foregroundColor: AppColors.accentOrangeDark,
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: Text(
                              _selectedImageBytes != null
                                  ? 'Ganti Foto dari Galeri'
                                  : 'Upload Foto dari Galeri / Penyimpanan',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Optional URL Field fallback
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            hintText: 'Atau masukkan URL foto (opsional)...',
                            prefixIcon: Icon(Icons.link_rounded, size: 18),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentOrange),
                        child: _isSubmitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
