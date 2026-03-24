import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/layout/app_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_error_view.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_loading_view.dart';
import 'package:liquid_soap_tracker/core/utils/app_uuid.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/controller/product_setup_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/buttons/save_product_setup_button.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/sections/product_setup_editor_section.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/sheets/add_product_size_sheet.dart';

class ProductSetupPage extends ConsumerStatefulWidget {
  const ProductSetupPage({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<ProductSetupPage> createState() => _ProductSetupPageState();
}

class _ProductSetupPageState extends ConsumerState<ProductSetupPage> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _defaultCostController = TextEditingController();
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _lowStockControllers = {};
  final ImagePicker _imagePicker = ImagePicker();
  final List<ProductSizeSetting> _workingSizes = [];
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _initialized = false;
  String? _productImagePath;
  String? _productImageUrl;

  void _ensureControllers(ProductSizeSetting size) {
    _priceControllers.putIfAbsent(
      size.id,
      () => TextEditingController(
        text: size.unitPrice == null ? '' : size.unitPrice!.toStringAsFixed(2),
      ),
    );
    _lowStockControllers.putIfAbsent(
      size.id,
      () => TextEditingController(text: size.lowStockThreshold.toString()),
    );
  }

  void _syncControllers(ProductSetupBundle bundle) {
    if (_initialized) {
      return;
    }

    _productNameController.text = bundle.productName;
    _defaultCostController.text = (bundle.defaultCostPerLiter ?? 0)
        .toStringAsFixed(2);
    _productImagePath = bundle.productImagePath;
    _productImageUrl = bundle.productImageUrl;

    for (final size in bundle.sizes) {
      _ensureControllers(size);
    }
    _workingSizes
      ..clear()
      ..addAll(bundle.sizes)
      ..sort((a, b) => a.liters.compareTo(b.liters));

    _initialized = true;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _defaultCostController.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    for (final controller in _lowStockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProductImage(ImageSource source) async {
    setState(() => _isUploadingImage = true);
    try {
      final file = await _imagePicker.pickImage(source: source, imageQuality: 88);
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';
      final uploaded = await ref
          .read(productRepositoryProvider)
          .uploadProductImage(bytes: bytes, fileExtension: extension);

      if (!mounted) {
        return;
      }

      setState(() {
        _productImagePath = uploaded.$1;
        _productImageUrl = uploaded.$2;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo uploaded.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickProductImage(source);
    }
  }

  Future<void> _showAddSizeSheet() async {
    final draft = await showModalBottomSheet<AddProductSizeDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AddProductSizeSheet(existingSizes: _workingSizes),
    );
    if (draft == null || !mounted) {
      return;
    }

    final size = ProductSizeSetting(
      id: AppUuid.v4(),
      label: draft.label,
      liters: draft.liters,
      lowStockThreshold: draft.lowStockThreshold,
      active: true,
      unitPrice: draft.unitPrice,
    );

    _ensureControllers(size);
    if (draft.unitPrice == null) {
      _priceControllers[size.id]!.clear();
    } else {
      _priceControllers[size.id]!.text = draft.unitPrice!.toStringAsFixed(2);
    }
    _lowStockControllers[size.id]!.text = draft.lowStockThreshold.toString();

    setState(() {
      _workingSizes
        ..add(size)
        ..sort((a, b) => a.liters.compareTo(b.liters));
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('New size added. Save product to keep it.')));
  }

  Future<void> _save(ProductSetupBundle bundle) async {
    setState(() => _isSaving = true);
    try {
      final updatedSizes = _workingSizes
          .map(
            (size) => size.copyWith(
              lowStockThreshold:
                  int.tryParse(_lowStockControllers[size.id]!.text.trim()) ??
                  size.lowStockThreshold,
              unitPrice:
                  _priceControllers[size.id]!.text.trim().isEmpty
                  ? null
                  : double.tryParse(_priceControllers[size.id]!.text.trim()),
            ),
          )
          .toList();

      final result = await ref
          .read(productRepositoryProvider)
          .saveSetup(
            productName: _productNameController.text.trim().isEmpty
                ? bundle.productName
                : _productNameController.text.trim(),
            defaultCostPerLiter:
                double.tryParse(_defaultCostController.text.trim()) ?? 0,
            sizes: updatedSizes,
            productImagePath: _productImagePath,
            productImageUrl: _productImageUrl,
          );
      await ref.read(offlineSyncServiceProvider).refreshPendingCount();

      ref
        ..invalidate(productSetupBundleProvider)
        ..invalidate(dashboardBundleProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
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
    final bundleAsync = ref.watch(productSetupBundleProvider);

    return bundleAsync.when(
      data: (bundle) {
        _syncControllers(bundle);
        final readOnly = !widget.profile.isOwner;
        return AppPageScaffold(
          title: 'Product',
          subtitle: readOnly
              ? 'See the photo, sizes, and current stock.'
              : 'Update the photo, sizes, stock, prices, and cost.',
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                )
              : null,
          child: Column(
            children: [
              ProductSetupEditorSection(
                sizes: _workingSizes,
                productNameController: _productNameController,
                defaultCostController: _defaultCostController,
                priceControllers: _priceControllers,
                lowStockControllers: _lowStockControllers,
                readOnly: readOnly,
                productImageUrl: _productImageUrl ?? bundle.productImageUrl,
                onUploadImage: readOnly ? null : _showImageSourcePicker,
                onAddSize: readOnly ? null : _showAddSizeSheet,
                isUploadingImage: _isUploadingImage,
              ),
              if (!readOnly) ...[
                const SizedBox(height: 18),
                SaveProductSetupButton(
                  onPressed: () => _save(bundle),
                  isBusy: _isSaving,
                ),
              ],
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: AppLoadingView(message: 'Loading product...')),
      error: (error, stackTrace) => Scaffold(
        body: AppErrorView(
          title: 'Product unavailable',
          message: error.toString(),
          actionLabel: 'Reload',
          onPressed: () => ref.invalidate(productSetupBundleProvider),
        ),
      ),
    );
  }
}
