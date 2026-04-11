import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

class JournalFormScreen extends StatefulWidget {
  const JournalFormScreen({super.key});

  @override
  State<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends State<JournalFormScreen> {

  final formKey = GlobalKey<FormState>();

  final titleC = TextEditingController();
  final descC = TextEditingController();

  File? imageFile;
  Uint8List? webImage;

  /// PICK IMAGE SUPPORT WEB + ANDROID
  Future pick(ImageSource source) async {

    try {

      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: source,
        imageQuality: 75,
      );

      if (picked == null) return;

      /// WEB
      if (kIsWeb) {

        final bytes = await picked.readAsBytes();

        setState(() {

          webImage = bytes;

          imageFile = null;

        });

      }

      /// ANDROID / IOS
      else {

        final file = File(picked.path);

        setState(() {

          imageFile = file;

          webImage = null;

        });

      }

    } catch (e) {

      debugPrint("error pick image: $e");

    }
  }

  void chooseImage() {

    showModalBottomSheet(

      context: context,

      builder: (_) {

        return Padding(

          padding: const EdgeInsets.all(20),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Text(

                "Upload Foto",

                style: TextStyle(

                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(

                children: [

                  Expanded(
                    child: imgBtn(
                      LucideIcons.camera,
                      "Kamera",
                      () {

                        Navigator.pop(context);

                        pick(ImageSource.camera);

                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: imgBtn(
                      LucideIcons.image,
                      "Galeri",
                      () {

                        Navigator.pop(context);

                        pick(ImageSource.gallery);

                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget imgBtn(

    IconData icon,

    String label,

    VoidCallback onTap,

  ) {

    return InkWell(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(

          color: const Color(0xffeef2ff),

          borderRadius: BorderRadius.circular(18),
        ),

        child: Column(

          children: [

            Icon(

              icon,

              size: 28,

              color: const Color(0xff4f46e5),
            ),

            const SizedBox(height: 8),

            Text(

              label,

              style: const TextStyle(

                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void submit() {

    if (!formKey.currentState!.validate()) return;

    if (imageFile == null && webImage == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text("foto wajib diupload"),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text("jurnal berhasil disimpan"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xfff8fafc),

      appBar: AppBar(

        title: const Text(

          "Tulis Jurnal",

          style: TextStyle(

            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.white,

        foregroundColor: const Color(0xff0f172a),

        elevation: 0,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Form(

          key: formKey,

          child: Column(

            children: [

              /// FOTO
              InkWell(

                onTap: chooseImage,

                child: Container(

                  height: 200,

                  width: double.infinity,

                  decoration: BoxDecoration(

                    color: const Color(0xffeef2ff),

                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: previewImage(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(

                controller: titleC,

                decoration: inputStyle(

                  "Judul kegiatan",

                  LucideIcons.fileText,
                ),

                validator: (v) =>
                    v!.isEmpty ? "wajib diisi" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(

                controller: descC,

                maxLines: 5,

                decoration: inputStyle(

                  "Deskripsi kegiatan",

                  LucideIcons.clipboard,
                ),

                validator: (v) =>
                    v!.isEmpty ? "wajib diisi" : null,
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,

                child: ElevatedButton(

                  onPressed: submit,

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(0xff4f46e5),

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),

                    shape: RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(

                    "Simpan Jurnal",

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,
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

  Widget previewImage() {

    if (webImage != null) {

      return ClipRRect(

        borderRadius: BorderRadius.circular(24),

        child: Image.memory(

          webImage!,

          fit: BoxFit.cover,
        ),
      );
    }

    if (imageFile != null) {

      return ClipRRect(

        borderRadius: BorderRadius.circular(24),

        child: Image.file(

          imageFile!,

          fit: BoxFit.cover,
        ),
      );
    }

    return const Column(

      mainAxisAlignment: MainAxisAlignment.center,

      children: [

        Icon(

          LucideIcons.image,

          size: 50,

          color: Color(0xff6366f1),
        ),

        SizedBox(height: 10),

        Text("upload foto kegiatan"),
      ],
    );
  }

  InputDecoration inputStyle(

    String label,

    IconData icon,

  ) {

    return InputDecoration(

      labelText: label,

      prefixIcon: Icon(

        icon,

        color: const Color(0xff6366f1),
      ),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(

        borderRadius:
            BorderRadius.circular(18),

        borderSide: BorderSide.none,
      ),
    );
  }
}