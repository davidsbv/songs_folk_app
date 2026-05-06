import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../app_branding.dart';
import '../core/supabase_config.dart';
import '../models/app_appearance.dart';
import '../repositories/app_appearance_repository.dart';
import '../services/admin_upload_service.dart';

/// Panel admin: colores y fondo global (Supabase). El modo claro/oscuro es local por usuario.
class AdminAppearanceScreen extends StatefulWidget {
  const AdminAppearanceScreen({super.key});

  @override
  State<AdminAppearanceScreen> createState() => _AdminAppearanceScreenState();
}

class _AdminAppearanceScreenState extends State<AdminAppearanceScreen> {
  final AppAppearanceRepository _repo = AppAppearanceRepository();
  final AdminUploadService _uploadService = AdminUploadService();
  final _accentCtrl = TextEditingController();
  final _scaffoldCtrl = TextEditingController();
  final _fontCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  double _overlay = 0.35;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _error;

  void _onHexFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _accentCtrl.addListener(_onHexFieldsChanged);
    _scaffoldCtrl.addListener(_onHexFieldsChanged);
    _fontCtrl.addListener(_onHexFieldsChanged);
    _load();
  }

  @override
  void dispose() {
    _accentCtrl.removeListener(_onHexFieldsChanged);
    _scaffoldCtrl.removeListener(_onHexFieldsChanged);
    _fontCtrl.removeListener(_onHexFieldsChanged);
    _accentCtrl.dispose();
    _scaffoldCtrl.dispose();
    _fontCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final a = await _repo.fetchPublic();
      if (!mounted) return;
      _accentCtrl.text = a.accentSeedHex ?? '';
      _scaffoldCtrl.text = a.scaffoldBackgroundHex ?? '';
      _fontCtrl.text = a.fontColorHex ?? '';
      _imageCtrl.text = a.backgroundImageUrl ?? '';
      setState(() {
        _overlay = a.backgroundOverlayOpacity;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String? _validateHex(String? value, {required bool allowEmpty}) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : 'Indica un color en hexadecimal.';
    }
    if (!isValidHexColor(value.trim())) {
      return 'Formato invalido (ej. #6750A4 o 6750A4).';
    }
    return null;
  }

  String _colorToHexRgb(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  Future<void> _openRgbColorPicker({
    required TextEditingController controller,
    required String title,
    required Color colorIfInvalidHex,
  }) async {
    Color pickerColor = parseHexColor(controller.text.trim()) ?? colorIfInvalidHex;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (c) => setDialogState(() => pickerColor = c),
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  pickerAreaHeightPercent: 0.72,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    controller.text = _colorToHexRgb(pickerColor);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  Widget _hexColorRow({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String dialogTitle,
    required Color pickerFallback,
  }) {
    final parsed = parseHexColor(controller.text.trim());
    final empty = controller.text.trim().isEmpty;
    final scheme = Theme.of(context).colorScheme;
    final previewFill = parsed ?? scheme.surfaceContainerHighest;

    void openPicker() {
      if (_saving || _uploadingImage) return;
      _openRgbColorPicker(
        controller: controller,
        title: dialogTitle,
        colorIfInvalidHex: pickerFallback,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Elegir color',
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: (_saving || _uploadingImage) ? null : openPicker,
                  ),
                ),
                validator: (v) => _validateHex(v, allowEmpty: true),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Ver y elegir color',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_saving || _uploadingImage) ? null : openPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: previewFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: !empty && parsed == null
                        ? Icon(Icons.help_outline, color: scheme.error)
                        : empty
                            ? Icon(Icons.layers_outlined, color: scheme.onSurfaceVariant)
                            : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final appearance = AppAppearance(
        accentSeedHex: _accentCtrl.text.trim().isEmpty ? null : _accentCtrl.text.trim(),
        scaffoldBackgroundHex: _scaffoldCtrl.text.trim().isEmpty ? null : _scaffoldCtrl.text.trim(),
        fontColorHex: _fontCtrl.text.trim().isEmpty ? null : _fontCtrl.text.trim(),
        backgroundImageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        backgroundOverlayOpacity: _overlay,
      );
      await _repo.upsert(appearance);
      if (!mounted) return;
      await AppBranding.of(context).refreshAppearance();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apariencia guardada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadBackgroundImage() async {
    if (_uploadingImage || _saving) return;
    setState(() => _uploadingImage = true);
    try {
      final url = await _uploadService.pickAndUploadAppearanceBackground();
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() => _imageCtrl.text = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida. Pulsa guardar para aplicarla a todos.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _removeBackgroundImage() async {
    if (_uploadingImage || _saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar imagen de fondo'),
        content: const Text(
          'Se borrara la imagen de Supabase Storage y se quitara de la apariencia global.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      await _uploadService.deleteAppearanceBackgroundImage();
      _imageCtrl.clear();
      final appearance = AppAppearance(
        accentSeedHex: _accentCtrl.text.trim().isEmpty ? null : _accentCtrl.text.trim(),
        scaffoldBackgroundHex: _scaffoldCtrl.text.trim().isEmpty ? null : _scaffoldCtrl.text.trim(),
        fontColorHex: _fontCtrl.text.trim().isEmpty ? null : _fontCtrl.text.trim(),
        backgroundImageUrl: null,
        backgroundOverlayOpacity: _overlay,
      );
      await _repo.upsert(appearance);
      if (!mounted) return;
      await AppBranding.of(context).refreshAppearance();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen de fondo eliminada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar imagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _restoreDefaultColors() async {
    if (_saving || _uploadingImage) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar colores por defecto'),
        content: const Text(
          'Se restableceran color de acento, fondo y fuente a los valores originales de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _accentCtrl.clear();
      _scaffoldCtrl.clear();
      _fontCtrl.clear();
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia global')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Estos valores los ven todos los usuarios al abrir la app. '
                          'El modo claro u oscuro lo elige cada usuario en la pantalla principal.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        _hexColorRow(
                          controller: _accentCtrl,
                          label: 'Color de acento (hex)',
                          hint: '#6750A4 o paleta',
                          dialogTitle: 'Color de acento',
                          pickerFallback: Colors.deepPurpleAccent,
                        ),
                        _hexColorRow(
                          controller: _scaffoldCtrl,
                          label: 'Color de fondo sin imagen (hex)',
                          hint: 'Vacío = color por defecto del tema',
                          dialogTitle: 'Color de fondo',
                          pickerFallback: Theme.of(context).colorScheme.surface,
                        ),
                        _hexColorRow(
                          controller: _fontCtrl,
                          label: 'Color de fuente (hex)',
                          hint: 'Vacío = color por defecto del tema',
                          dialogTitle: 'Color de fuente',
                          pickerFallback: Theme.of(context).colorScheme.onSurface,
                        ),
                        TextFormField(
                          controller: _imageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL imagen de fondo',
                            hintText: 'Sube un archivo o pega una URL publica',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: (_saving || _uploadingImage) ? null : _uploadBackgroundImage,
                            icon: _uploadingImage
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(_uploadingImage ? 'Subiendo...' : 'Subir imagen a Supabase Storage'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: (_saving || _uploadingImage || _imageCtrl.text.trim().isEmpty)
                                ? null
                                : _removeBackgroundImage,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar imagen de fondo'),
                          ),
                        ),
                        Text(
                          'Se guarda en el bucket $supabaseStorageBucket como appearance/app-background (sustituye la anterior).',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Opacidad del velo sobre la imagen (${(_overlay * 100).round()}%)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Slider(
                          value: _overlay,
                          min: 0,
                          max: 1,
                          divisions: 20,
                          onChanged: _saving ? null : (v) => setState(() => _overlay = v),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _restoreDefaultColors,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restaurar colores por defecto'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Guardar en Supabase'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
