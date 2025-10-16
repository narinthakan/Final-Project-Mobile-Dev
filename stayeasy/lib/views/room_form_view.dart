import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/room.dart';
import '../controllers/room_controller.dart';
import '../services/pb_service.dart';
import 'room_list_view.dart';

class RoomFormView extends StatefulWidget {
  final Room? room;
  const RoomFormView({super.key, this.room});

  @override
  State<RoomFormView> createState() => _RoomFormViewState();
}

class _RoomFormViewState extends State<RoomFormView> {
  final formKey = GlobalKey<FormState>();
  final roomNumberCtrl = TextEditingController();
  final roomTypeCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String status = 'Available';

  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;

  final c = Get.find<RoomController>();

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      roomNumberCtrl.text = widget.room!.roomNumber;
      roomTypeCtrl.text = widget.room!.roomType;
      priceCtrl.text = widget.room!.price.toString();
      status = widget.room!.status;
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
      });
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

    final room = Room(
      id: widget.room?.id ?? const Uuid().v4(),
      roomNumber: roomNumberCtrl.text,
      roomType: roomTypeCtrl.text,
      price: double.tryParse(priceCtrl.text) ?? 0,
      status: status,
      imageUrl: widget.room?.imageUrl,
    );

    http.MultipartFile? imageFile;
    if (_imageBytes != null && _imageName != null) {
      imageFile = http.MultipartFile.fromBytes(
        'image',
        _imageBytes!,
        filename: _imageName!,
      );
    }

    if (widget.room == null) {
      await c.addRoom(room, imageFile: imageFile);
    } else {
      await c.updateRoom(room, imageFile: imageFile);
    }

    await c.fetchRooms();
    Get.offAll(() => const RoomListView());

    Get.snackbar(
      'Success',
      widget.room == null ? 'Room added successfully' : 'Room updated successfully',
      backgroundColor: const Color(0xFF7BC67E),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null ? 'Add Room' : 'Edit Room'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : (widget.room?.imageUrl != null &&
                              widget.room!.imageUrl!.isNotEmpty)
                          ? Image.network(
                              widget.room!.getImageUrl(PBService.baseUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined,
                                      size: 64, color: Colors.grey),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined,
                              size: 64, color: Color(0xFF89CFF0)),
                ),
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: roomNumberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter room number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: roomTypeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room Type',
                  prefixIcon: Icon(Icons.king_bed_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Please enter room type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                items: ['Available', 'Occupied', 'Maintenance']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => status = v!),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(widget.room == null
                      ? 'Add Room'
                      : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
