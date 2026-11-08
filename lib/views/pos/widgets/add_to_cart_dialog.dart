import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';

class AddToCartModal extends ConsumerStatefulWidget {
  final ProductModel product;

  const AddToCartModal({super.key, required this.product});

  static Future<void> show(BuildContext context, {required ProductModel product}) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AddToCartModal(product: product),
      );
    } else {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AddToCartModal(product: product),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AddToCartModal> createState() => _AddToCartModalState();
}

class _AddToCartModalState extends ConsumerState<AddToCartModal> {
  int _quantity = 1;
  bool _isFirstInput = true;
  String? _stockWarning;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.stock > 0 ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartItems = ref.read(cartProvider).items;
      final existing = cartItems.where((i) => i.productId == widget.product.id).firstOrNull;
      if (existing != null && existing.notes != null) {
        _notesController.text = existing.notes!;
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onNumpadDigit(int digit) {
    if (widget.product.stock <= 0) return;

    int newQty;
    if (_isFirstInput) {
      newQty = digit;
      _isFirstInput = false;
    } else {
      final currentStr = _quantity.toString();
      if (currentStr.length >= 4) return; // Prevent unreasonable numbers
      newQty = int.parse('$currentStr$digit');
    }

    if (newQty > widget.product.stock) {
      newQty = widget.product.stock;
      setState(() {
        _stockWarning = 'Maksimal stok tercapai (${widget.product.stock} item)';
      });
    } else {
      setState(() {
        _stockWarning = null;
      });
    }

    if (newQty < 1) newQty = 1;

    setState(() {
      _quantity = newQty;
    });
  }

  void _onNumpadBackspace() {
    if (widget.product.stock <= 0) return;

    final currentStr = _quantity.toString();
    if (currentStr.length <= 1) {
      setState(() {
        _quantity = 1;
        _isFirstInput = true;
        _stockWarning = null;
      });
    } else {
      final newStr = currentStr.substring(0, currentStr.length - 1);
      setState(() {
        _quantity = int.tryParse(newStr) ?? 1;
        _stockWarning = null;
      });
    }
  }

  void _onNumpadClear() {
    setState(() {
      _quantity = 1;
      _isFirstInput = true;
      _stockWarning = null;
    });
  }

  void _increment() {
    if (_quantity < widget.product.stock) {
      setState(() {
        _quantity++;
        _isFirstInput = false;
        _stockWarning = null;
      });
    } else {
      setState(() {
        _stockWarning = 'Maksimal stok tercapai (${widget.product.stock} item)';
      });
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
        _isFirstInput = false;
        _stockWarning = null;
      });
    }
  }

  void _addPreset(int amount) {
    int target = _quantity + amount;
    if (target > widget.product.stock) {
      target = widget.product.stock;
      setState(() {
        _stockWarning = 'Maksimal stok tercapai (${widget.product.stock} item)';
      });
    } else {
      setState(() {
        _stockWarning = null;
      });
    }
    setState(() {
      _quantity = target;
      _isFirstInput = false;
    });
  }

  void _setExactMax() {
    setState(() {
      _quantity = widget.product.stock;
      _isFirstInput = false;
      _stockWarning = 'Mengambil semua sisa stok';
    });
  }

  void _submitAddToCart() {
    if (_quantity <= 0 || widget.product.stock <= 0) return;

    final note = _notesController.text.trim();
    ref.read(cartProvider.notifier).addOrUpdateItemWithQuantity(
      widget.product,
      _quantity,
      notes: note.isEmpty ? null : note,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$_quantity× ${widget.product.name} berhasil ditambahkan ke keranjang!',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final category = catalogState.categories.cast<dynamic>().firstWhere(
          (c) => c.id == widget.product.categoryId,
          orElse: () => null,
        );

    final subtotal = widget.product.price * _quantity;
    final isLowStock = widget.product.stock > 0 && widget.product.stock <= 5;
    final isOutOfStock = widget.product.stock <= 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header Modal
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.add_shopping_cart_rounded, color: AppColors.accentOrange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tambah ke Keranjang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Product Info Card (Image, Name, Price, Stock)
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: Colors.white,
                        child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                            ? Image.network(
                                widget.product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Icon(
                                  Icons.fastfood_rounded,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                Icons.fastfood_rounded,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title, Category & Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                CurrencyFormatter.format(widget.product.price),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentOrange,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? AppColors.errorLight
                                      : (isLowStock ? AppColors.accentOrangeLight : AppColors.successLight),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isOutOfStock
                                      ? 'Stok Habis'
                                      : (isLowStock
                                          ? 'Sisa ${widget.product.stock}'
                                          : 'Stok: ${widget.product.stock}'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isOutOfStock
                                        ? AppColors.error
                                        : (isLowStock ? AppColors.accentOrangeDark : AppColors.success),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity & Live Subtotal Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      // Subtotal info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subtotal Produk',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(subtotal),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stepper controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _quantity > 1 ? _decrement : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _quantity > 1 ? AppColors.surfaceMuted : AppColors.surfaceMuted.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 18,
                                color: _quantity > 1 ? AppColors.textDark : AppColors.textMuted,
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 50),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentOrange,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _quantity < widget.product.stock ? _increment : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _quantity < widget.product.stock ? AppColors.accentOrange : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: _quantity < widget.product.stock ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Stock Warning message if any
              if (_stockWarning != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentOrangeDark),
                      const SizedBox(width: 6),
                      Text(
                        _stockWarning!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentOrangeDark,
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick preset chips (+1, +2, +5, +10, Semua)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('+1', () => _addPreset(1)),
                      const SizedBox(width: 6),
                      _buildPresetChip('+2', () => _addPreset(2)),
                      const SizedBox(width: 6),
                      _buildPresetChip('+5', () => _addPreset(5)),
                      const SizedBox(width: 6),
                      _buildPresetChip('+10', () => _addPreset(10)),
                      const SizedBox(width: 6),
                      _buildPresetChip(
                        'Semua (${widget.product.stock})',
                        _setExactMax,
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Notes / Catatan Pesanan
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primaryNavy),
                        SizedBox(width: 6),
                        Text(
                          'Catatan / Request Khusus (Opsional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Tanpa es, manis sedang, pedas...',
                        prefixIcon: Icon(Icons.sticky_note_2_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildNoteChip('Tanpa Es'),
                          const SizedBox(width: 6),
                          _buildNoteChip('Less Sugar'),
                          const SizedBox(width: 6),
                          _buildNoteChip('Pedas'),
                          const SizedBox(width: 6),
                          _buildNoteChip('Bungkus'),
                          const SizedBox(width: 6),
                          _buildNoteChip('Sedikit Es'),
                          const SizedBox(width: 6),
                          _buildNoteChip('Pisah Sambal'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Custom On-Screen Numpad Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: const [
                    Icon(Icons.dialpad_rounded, size: 15, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Text(
                      'Keypad Input Cepat Jumlah',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Custom UI Numpad Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildNumpadButton('1', () => _onNumpadDigit(1)),
                          const SizedBox(width: 8),
                          _buildNumpadButton('2', () => _onNumpadDigit(2)),
                          const SizedBox(width: 8),
                          _buildNumpadButton('3', () => _onNumpadDigit(3)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildNumpadButton('4', () => _onNumpadDigit(4)),
                          const SizedBox(width: 8),
                          _buildNumpadButton('5', () => _onNumpadDigit(5)),
                          const SizedBox(width: 8),
                          _buildNumpadButton('6', () => _onNumpadDigit(6)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildNumpadButton('7', () => _onNumpadDigit(7)),
                          const SizedBox(width: 8),
                          _buildNumpadButton('8', () => _onNumpadDigit(8)),
                          const SizedBox(width: 8),
                          _buildNumpadButton('9', () => _onNumpadDigit(9)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildNumpadButton(
                            'C',
                            _onNumpadClear,
                            bgColor: AppColors.errorLight,
                            textColor: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          _buildNumpadButton('0', () => _onNumpadDigit(0)),
                          const SizedBox(width: 8),
                          _buildNumpadButton(
                            '⌫',
                            _onNumpadBackspace,
                            bgColor: AppColors.surface,
                            textColor: AppColors.primaryNavy,
                            icon: Icons.backspace_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Action CTA Button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Semantics(
                  identifier: 'btn_tambah_ke_keranjang',
                  child: ElevatedButton(
                  onPressed: (isOutOfStock || _quantity <= 0) ? null : _submitAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surfaceMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_shopping_cart_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        isOutOfStock
                            ? 'Stok Tidak Tersedia'
                            : 'Tambah ($_quantity) • ${CurrencyFormatter.format(subtotal)}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, {bool isHighlight = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.accentOrangeLight : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlight ? AppColors.accentOrange : AppColors.border,
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.accentOrangeDark : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadButton(
    String label,
    VoidCallback onTap, {
    Color? bgColor,
    Color? textColor,
    IconData? icon,
  }) {
    return Expanded(
      child: Material(
        color: bgColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: icon != null
                ? Icon(icon, size: 18, color: textColor ?? AppColors.textDark)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor ?? AppColors.textDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteChip(String noteText) {
    return InkWell(
      onTap: () {
        final current = _notesController.text.trim();
        if (current.isEmpty) {
          _notesController.text = noteText;
        } else if (!current.contains(noteText)) {
          _notesController.text = '$current, $noteText';
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '+ $noteText',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryNavy,
          ),
        ),
      ),
    );
  }
}
