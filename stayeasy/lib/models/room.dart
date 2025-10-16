class Room {
  final String id;
  final String roomNumber;
  final String roomType;
  final double price;
  final String status;
  final String? imageUrl; // ฟิลด์รูป

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.price,
    required this.status,
    this.imageUrl,
  });

  // ✅ แปลงข้อมูลจาก PocketBase record
  factory Room.fromRecord(Map<String, dynamic> rec) {
    return Room(
      id: rec['id'],
      roomNumber: rec['room_number'] ?? '',
      roomType: rec['room_type'] ?? '',
      price: (rec['price'] ?? 0).toDouble(),
      status: rec['status'] ?? '',
      imageUrl: rec['image'], // ✅ ใช้ฟิลด์ใหม่ชื่อ image
    );
  }

  // ✅ สร้าง URL สำหรับแสดงภาพ
  String? getImageUrl(String baseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return '$baseUrl/api/files/rooms/$id/$imageUrl';
  }
}
