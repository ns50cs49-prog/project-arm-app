import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A circular avatar that lets the signed-in user pick and upload their own
/// profile photo. Shows the current [photoUrl] (or a placeholder icon) plus
/// a small camera badge; tapping it opens the image picker, uploads the
/// result to Firebase Storage at [storagePath], then calls [onUploaded]
/// with the resulting download URL so the caller can persist it (e.g. to
/// the matching Firestore doc).
class ProfilePhotoAvatar extends StatefulWidget {
  const ProfilePhotoAvatar({
    super.key,
    required this.photoUrl,
    required this.storagePath,
    required this.onUploaded,
    this.radius = 42,
  });

  final String photoUrl;
  final String storagePath;
  final ValueChanged<String> onUploaded;
  final double radius;

  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
    } catch (_) {
      _showMessage('เปิดตัวเลือกรูปภาพไม่สำเร็จ');
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instance.ref(widget.storagePath);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: picked.mimeType ?? 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      if (mounted) widget.onUploaded(url);
    } catch (_) {
      if (mounted) _showMessage('อัปโหลดรูปโปรไฟล์ไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.radius * 2;
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: const Color(0xffdef7f5),
            backgroundImage: widget.photoUrl.isEmpty
                ? null
                : NetworkImage(widget.photoUrl),
            child: widget.photoUrl.isEmpty
                ? Icon(
                    Icons.person_rounded,
                    size: widget.radius,
                    color: const Color(0xff159ea3),
                  )
                : null,
          ),
          if (_uploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: .35),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: const Color(0xff13a2ac),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _pickAndUpload,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only circular avatar for showing someone else's profile photo (e.g.
/// in the admin's doctor/patient list rows) — no upload affordance.
class ProfilePhotoView extends StatelessWidget {
  const ProfilePhotoView({super.key, required this.photoUrl, this.radius = 21});

  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xffe8fafa),
      backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
      child: photoUrl.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: radius,
              color: const Color(0xff1aaab3),
            )
          : null,
    );
  }
}
