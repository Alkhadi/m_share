import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile.dart';
import '../services/contact_service.dart';
import '../services/share_service.dart';

/// Edit form for Profile with avatar/background pickers, add contact
/// integration and the ability to share a captured profile card or a
/// custom image to multiple recipients.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final Profile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late Profile _editable;
  final _formKey = GlobalKey<FormState>();
  final _previewKey = GlobalKey();

  final ImagePicker _picker = ImagePicker();

  final List<String> _defaultAvatars = const [
    'assets/images/avatars/alkhadi.png',
    'assets/images/avatars/mariatou.png',
    'assets/images/avatars/avatar_business.png',
  ];

  final List<String> _defaultBackgrounds = const [
    'assets/images/backgrounds/amz.jpg',
    'assets/images/backgrounds/abstract_wave.jpg',
    'assets/images/backgrounds/gradient_sky.jpg',
    'assets/images/backgrounds/gradient_sand.jpg',
    'assets/images/backgrounds/pattern_dots.jpg',
    'assets/images/backgrounds/texture_paper.jpg',
    'assets/images/backgrounds/city_soft.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _editable = Profile.fromMap(widget.profile.toMap());
  }

  Future<void> _pickAvatarFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (file != null) setState(() => _editable.avatarPath = file.path);
  }

  Future<void> _pickAvatarFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    if (file != null) setState(() => _editable.avatarPath = file.path);
  }

  Future<void> _pickAvatarFromAssets() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Default Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _defaultAvatars.length,
            itemBuilder: (_, i) {
              final asset = _defaultAvatars[i];
              return GestureDetector(
                onTap: () {
                  setState(() => _editable.avatarPath = asset);
                  Navigator.pop(ctx);
                },
                child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (file != null) {
      setState(() {
        _editable.backgroundPath = file.path;
        _editable.backgroundColor = null;
      });
    }
  }

  Future<void> _pickBackgroundFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    if (file != null) {
      setState(() {
        _editable.backgroundPath = file.path;
        _editable.backgroundColor = null;
      });
    }
  }

  Future<void> _pickBackgroundFromAssets() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Default Background'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _defaultBackgrounds.length,
            itemBuilder: (_, i) {
              final asset = _defaultBackgrounds[i];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _editable.backgroundPath = asset;
                    _editable.backgroundColor = null;
                  });
                  Navigator.pop(ctx);
                },
                child: Image.asset(asset, fit: BoxFit.cover),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundColour() async {
    Color selected = _editable.backgroundColor ?? Colors.grey.shade200;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Background Colour'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selected,
            onColorChanged: (c) => selected = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {
                _editable.backgroundColor = selected;
                _editable.backgroundPath = null;
              });
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_editable);
    }
  }

  Widget _formField({
    required String label,
    required String initial,
    TextInputType? type,
    required ValueChanged<String> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initial,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Future<void> _showAddContact() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        bool business = false;
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return AlertDialog(
              title: const Text('Add New Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: business,
                          onChanged: (v) => setStateDialog(() {
                            business = v ?? false;
                          }),
                        ),
                        const Text('Business Contact'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await ContactService.saveContact(
                      name: name,
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      address: addressCtrl.text.trim(),
                      business: business,
                    );
                    if (!ctx2.mounted) return;
                    ScaffoldMessenger.of(ctx2).showSnackBar(
                      const SnackBar(
                        content: Text('Contact saved successfully'),
                      ),
                    );
                    Navigator.pop(ctx2);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Uint8List?> _capturePreview() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareProfileImage() async {
    final bytes = await _capturePreview();
    if (bytes == null) return;
    final svc = ShareService(profile: _editable);
    await svc.shareImageBytes(bytes, suggestedName: 'profile_card.png');
  }

  Future<void> _shareCustomImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    final svc = ShareService(profile: _editable);
    await svc.shareImageBytes(
      bytes,
      suggestedName:
          'custom_image_${DateTime.now().millisecondsSinceEpoch}.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(
                    key: _previewKey,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            _editable.backgroundColor ?? Colors.grey.shade200,
                        image: _editable.backgroundPath != null
                            ? DecorationImage(
                                image: _editable.backgroundPath!
                                        .startsWith('assets/')
                                    ? AssetImage(_editable.backgroundPath!)
                                        as ImageProvider<Object>
                                    : FileImage(
                                        File(_editable.backgroundPath!),
                                      ) as ImageProvider<Object>,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: _editable.avatarPath != null
                              ? (_editable.avatarPath!.startsWith('assets/')
                                  ? AssetImage(_editable.avatarPath!)
                                      as ImageProvider<Object>
                                  : FileImage(File(_editable.avatarPath!))
                                      as ImageProvider<Object>)
                              : null,
                          child: _editable.avatarPath == null
                              ? Text(
                                  _editable.fullName.isNotEmpty
                                      ? _editable.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Avatar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickAvatarFromAssets,
                          icon: const Icon(Icons.image_search),
                          label: const Text('Default'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickAvatarFromGallery,
                          icon: const Icon(Icons.photo),
                          label: const Text('Gallery'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickAvatarFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Background',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickBackgroundFromAssets,
                          icon: const Icon(Icons.image_search),
                          label: const Text('Default'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickBackgroundFromGallery,
                          icon: const Icon(Icons.photo),
                          label: const Text('Gallery'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _pickBackgroundFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _pickBackgroundColour,
                    icon: const Icon(Icons.color_lens),
                    label: const Text('Pick Colour'),
                  ),
                  const SizedBox(height: 24),
                  _formField(
                    label: 'Full Name',
                    initial: _editable.fullName,
                    onChanged: (v) => _editable.fullName = v,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Name cannot be empty'
                        : null,
                  ),
                  _formField(
                    label: 'Role',
                    initial: _editable.role,
                    onChanged: (v) => _editable.role = v,
                  ),
                  _formField(
                    label: 'Address',
                    initial: _editable.address,
                    onChanged: (v) => _editable.address = v,
                  ),
                  _formField(
                    label: 'Phone',
                    initial: _editable.phone,
                    type: TextInputType.phone,
                    onChanged: (v) => _editable.phone = v,
                  ),
                  _formField(
                    label: 'Email',
                    initial: _editable.email,
                    type: TextInputType.emailAddress,
                    onChanged: (v) => _editable.email = v,
                  ),
                  _formField(
                    label: 'Website',
                    initial: _editable.website,
                    type: TextInputType.url,
                    onChanged: (v) => _editable.website = v,
                  ),
                  _formField(
                    label: 'Wellbeing Link',
                    initial: _editable.wellbeingLink,
                    type: TextInputType.url,
                    onChanged: (v) => _editable.wellbeingLink = v,
                  ),
                  _formField(
                    label: 'Sort Code',
                    initial: _editable.bankSortCode,
                    onChanged: (v) => _editable.bankSortCode = v,
                  ),
                  _formField(
                    label: 'Account Number',
                    initial: _editable.bankAccountNumber,
                    onChanged: (v) => _editable.bankAccountNumber = v,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddContact,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add New Contact'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Image / Share',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareProfileImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Share Profile Image'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareCustomImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Share Custom Image'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                  SizedBox(height: bottomInset + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
