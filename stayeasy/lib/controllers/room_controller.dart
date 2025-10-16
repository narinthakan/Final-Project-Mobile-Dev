import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import '../services/pb_service.dart';

class RoomController extends GetxController {
  final PBService pb = PBService();

  // ✅ ตัวแปร observable สำหรับจัดการสถานะ
  final rooms = <Room>[].obs;
  final loading = false.obs;
  final searchQuery = ''.obs;
  final selectedFilter = 'All'.obs;

  // ✅ ดึงข้อมูลทั้งหมดจาก PocketBase
  Future<void> fetchRooms() async {
    try {
      loading.value = true;
      final result = await pb.client.collection('rooms').getList(
        page: 1,
        perPage: 100,
        sort: '-created',
      );

      rooms.value = result.items.map((rec) {
        final data = rec.data;
        data['id'] = rec.id;
        return Room.fromRecord(data);
      }).toList();

      print('✅ Loaded ${rooms.length} rooms from PocketBase');
    } catch (e) {
      print('❌ Error fetching rooms: $e');
    } finally {
      loading.value = false;
    }
  }

  // ✅ เพิ่มห้องใหม่ (พร้อมอัปโหลดรูป)
  Future<void> addRoom(Room room, {http.MultipartFile? imageFile}) async {
    try {
      final body = {
        'room_number': room.roomNumber,
        'room_type': room.roomType,
        'price': room.price,
        'status': room.status,
      };

      final List<http.MultipartFile> files =
          imageFile != null ? [imageFile] : <http.MultipartFile>[];

      final rec = await pb.client.collection('rooms').create(
        body: body,
        files: files,
      );

      final newRoom = Room.fromRecord({
        ...rec.data,
        'id': rec.id,
      });

      rooms.insert(0, newRoom);

      print('✅ Added room: ${newRoom.roomNumber}');
      print('🖼️ Uploaded image file: ${newRoom.imageUrl}');
    } catch (e) {
      print('❌ Error adding room: $e');
    }
  }

  // ✅ อัปเดตห้อง (พร้อมอัปโหลดรูปใหม่)
  Future<void> updateRoom(Room room, {http.MultipartFile? imageFile}) async {
    try {
      final body = {
        'room_number': room.roomNumber,
        'room_type': room.roomType,
        'price': room.price,
        'status': room.status,
      };

      final List<http.MultipartFile> files =
          imageFile != null ? [imageFile] : <http.MultipartFile>[];

      final rec = await pb.client.collection('rooms').update(
        room.id,
        body: body,
        files: files,
      );

      final updatedRoom = Room.fromRecord({
        ...rec.data,
        'id': rec.id,
      });

      final index = rooms.indexWhere((r) => r.id == room.id);
      if (index != -1) {
        rooms[index] = updatedRoom;
      }

      print('✅ Updated room: ${updatedRoom.roomNumber}');
      print('🖼️ Updated image file: ${updatedRoom.imageUrl}');
    } catch (e) {
      print('❌ Error updating room: $e');
    }
  }

  // ✅ ลบห้อง
  Future<void> deleteRoom(String id) async {
    try {
      await pb.client.collection('rooms').delete(id);
      rooms.removeWhere((r) => r.id == id);
      print('🗑️ Deleted room: $id');
    } catch (e) {
      print('❌ Error deleting room: $e');
    }
  }

  // ✅ ตั้งค่าการกรองและค้นหา
  void setFilter(String filter) => selectedFilter.value = filter;
  void setSearch(String query) => searchQuery.value = query;

  // ✅ Getter สำหรับกรองรายการ
  List<Room> get filteredRooms {
    // แปลง RxList เป็น List ก่อนกรอง
    List<Room> filtered = rooms.toList();

    // 🔹 กรองตามสถานะห้อง (Available, Occupied, Maintenance)
    if (selectedFilter.value != 'All') {
      filtered = filtered
          .where((r) =>
              r.status.toLowerCase() == selectedFilter.value.toLowerCase())
          .toList();
    }

    // 🔹 ค้นหาจากหมายเลขห้องหรือประเภท
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((r) =>
              r.roomNumber
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()) ||
              r.roomType
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}
