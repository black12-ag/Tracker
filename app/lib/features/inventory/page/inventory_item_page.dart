import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class InventoryItemPage extends ConsumerStatefulWidget {
  const InventoryItemPage({
    required this.profile,
    super.key,
    this.existingItem,
  });

  final AppProfile profile;
  final Map<String, dynamic>? existingItem;

  @override
  ConsumerState<InventoryItemPage> createState() => _InventoryItemPageState();
}

class _InventoryItemPageState extends ConsumerState<InventoryItemPage> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _unitTypeController;
  late final TextEditingController _boughtPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _descriptionController;
  final List<XFile> _newImages = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?['name'] as String? ?? '');
    _unitTypeController = TextEditingController(
      text: item?['unit_type'] as String? ?? '',
    );
    _boughtPriceController = TextEditingController(
      text: ((item?['bought_price'] as num?)?.toDouble() ?? 0) == 0
          ? ''
          : ((item?['bought_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    _sellingPriceController = TextEditingController(
      text: ((item?['selling_price'] as num?)?.toDouble() ?? 0) == 0
          ? ''
          : ((item?['selling_price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: item?['description'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitTypeController.dispose();
    _boughtPriceController.dispose();
    _sellingPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
            ],
          ),
        );
      },
    );

    if (option == null) {
      return;
    }

    if (option == 'camera') {
      final image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        setState(() => _newImages.add(image));
      }
      return;
    }

    final images = await _picker.pickMultiImage();
    if (mounted && images.isNotEmpty) {
      setState(() => _newImages.addAll(images));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _unitTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and unit type are required.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final item = await ref.read(trackerRepositoryProvider).saveInventoryItem(
            itemId: widget.existingItem?['id'] as String?,
            createdBy: widget.profile.id,
            name: _nameController.text,
            unitType: _unitTypeController.text,
            boughtPrice: double.tryParse(_boughtPriceController.text.trim()) ?? 0,
            sellingPrice:
                double.tryParse(_sellingPriceController.text.trim()) ?? 0,
            description: _descriptionController.text,
            images: _newImages,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(item);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImages = ((widget.existingItem?['images'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingItem == null ? 'Inventory Item' : 'Edit Item'),
        backgroundColor: AppColors.mintSoft,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Images (up to 5)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Upload Image'),
                ),
                if (existingImages.isNotEmpty || _newImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final image in existingImages)
                        _ImageChip(label: image['storage_path'] as String? ?? 'Saved'),
                      for (final image in _newImages) _ImageChip(label: image.name),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSurfaceCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Product name',
                  hintText: 'Enter product name',
                  prefixIcon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _unitTypeController,
                  label: 'Unit type',
                  hintText: 'Bottle, box, liter, piece',
                  prefixIcon: Icons.straighten_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _boughtPriceController,
                        label: 'Bought price',
                        hintText: '0',
                        prefixIcon: Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _sellingPriceController,
                        label: 'Selling price',
                        hintText: '0',
                        prefixIcon: Icons.price_change_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hintText: 'Optional item details',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Save',
            isBusy: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ImageChip extends StatelessWidget {
  const _ImageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
