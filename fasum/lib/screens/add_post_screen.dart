import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// import 'package:firebase_auth/firebase_auth.dart'
class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});
  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}
class _AddPostScreen1State extends State<AddPostScreen1> {
  File? _image;
  String? _base64Image;
  final TextEditingController _descriptionController =
  TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double? _latitude;
  double? _longitude;
  String? _aiCategory;
  String? _aiDescription;
  bool _isGenerating = false;
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        // await _generateDescriptionWithAI();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }
  Future<void> _getlocation() async{
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled){
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location services are disabled.');
      }
      try {
        final possition = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(Duration(seconds: 10));
        setState(() {
          _latitude = possition.latitude;
          _longitude = possition.longitude;
        });
      } catch (e) {
        debugPrint('Gagal nebdapatkan Lokasi: $e');
        setState(() {
          _latitude = null;
          _longitude = null;
        });

        Future<void> _submitPost() async {
          if (_base64Image == null || _descriptionController.text.isEmpty)
            return;

          setState(() => _isUploading = true);

          final now = DateTime.now().toIso8601String();
          final uid = FirebaseAuth.instance.currentUser?.uid;

          if (uid == null) {
            setState(() => _isUploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pengguna tidak ditemukan')),
            );
            return;
          }
          try {
            await _getlocation();

            //ambil nama lengkap dari koleksi user
            final userDoc = await FirebaseFirestore.instance.collection('user')
                .doc(uid)
                .get();
            final fullName = userDoc.data()?['fullName'] ?? 'Tanpa Nama';
            await FirebaseFirestore.instance.collection('post').add({
              'image': _base64Image,
              'description': _descriptionController.text,
              'createdAt': now,
              'latitude': _latitude,
              'longitude': _longitude,
              'fullName': fullName, //<-----Tambhakan ini
              'userId': uid,
            });
            if (!mounted) return;
            Navigator.pop(context);
          } catch (e) {
            debugPrint('Upload failed: $e');
            if (!mounted) return;
            setState(() => _isUploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menggungah Postingan')),
            );
          }
        }
      }
  }

  }
  Future<void> _generateDescriptionWithAI() async {
    if (_image == null) return;
    setState(() => _isGenerating = true);
    try {
      final model = GenerativeModel(
          model = 'gemini-1.5-pro',
          apiKey = ''
      );

      final imageBytes = await _image!.readAsBytes();
      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(
          'Berdasarkan foto ini, identifikasi satu kategori utama kerusakan fasilitas umum ''dari daftar berikut: Jalan Rusak, Marka pudar, Lampu mati, Trotoar rusak'
              'Rambu Rusak, Jembatan Rusak,Sampah Menumpuk, Saluran Tersembut, Sungai tercemar' 'Sampah Sungai, Pohon Tumbang, Taman Rusak, Fasilitas Rusak, Pipa Bocor,'
              'Vadalisme, Banjir, dan Lainnya.'
              'pilih kategori yang paling dominan atau paling mendesak untuk dilaporkan.''Buat deskripsi singkat untuk laporan perbaikan , dan tambahkan permohonan perbaikan.'
              'Fokus pada kerusakan yang terlihat dan hindari spkulasi.\n\n'
              'Format output yang diinginkan:\n'
              'Kategori: [satu kategori yang dipilih]\n'
              'Deskripsi: [deskripsi singkat]',
        ),
      ]);

      final response = await model.generateContent([content]);
      final aiText = response.text;
      print("AI TEXT: $aiText");

      if (aiText != null && aiText.isNotEmpty) {
        final lines = aiText.trim().split('\n');
        String? category;
        String? description;

        for (var line in lines) {
          final lower = line.toLowerCase();
          if (lower.stratWith('kategori')) {
            category = line.substring(9).trim();
          } else if (lower.startsWith('keterangan')) {
            description - line.substring(10).trim();
          } else if (lower.startsWith('keterangan')) {
            description - line.substring(11).trim();
          }

          description ??= aiText.trim();

          setState(() {
            _aiCategory = category ?? 'Tidak Diketahui';
            _aiDescription = description!;
            _descriptionController.text = _aiDescription;
          });
        }
      } catch (e) {
      debugPrint('Failed to generate AI description: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
      }
    }

  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _aiCategory = null;
          _aiDescription = null;
          _descriptionController.clear();
        });
        await _compressAndEncodeImage();
        await _generateDescriptionWithAI()
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMassenger.of(
          
        )
      }
    }
  }
  }
  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );
      if (compressedImage == null) return;
      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image:$e')));
        }
        }
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Post')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                _image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _image!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Add a brief description...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24,),
            ElevatedButton(onPressed: () {}, child: Text('Post')),
          ],
        ),
      ),
    );
  }
}