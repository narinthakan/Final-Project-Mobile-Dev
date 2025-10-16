# StayEasy — Final Project (Mobile Application Development)


StayEasy เป็นแอปพลิเคชันสำหรับจัดการห้องพัก (Room Management System) พัฒนาโดยใช้ Flutter เป็นส่วนหน้าของแอป และ PocketBase เป็น backend แบบเรียลไทม์

สรุปความสามารถหลัก
- จัดการข้อมูลห้อง: เพิ่ม แก้ไข ลบ รายละเอียดห้อง (ชื่อ, รายละเอียด, ราคา, สถานะ)
- อัปโหลดและแสดงรูปภาพของห้อง
- ค้นหาและกรองรายการห้องตามสถานะหรือคำค้น
- สื่อสารแบบเรียลไทม์กับ PocketBase เพื่ออัปเดตข้อมูลทันที

โครงสร้างโปรเจค (ไฮไลท์ไฟล์/โฟลเดอร์สำคัญ)
- `lib/main.dart` — จุดเริ่มต้นของแอป
- `lib/controllers/room_controller.dart` — ควบคุม logic ของการจัดการห้อง
- `lib/models/room.dart` — โมเดลข้อมูลห้อง
- `lib/services/pb_service.dart` — การเชื่อมต่อและเรียกใช้งาน PocketBase
- `lib/views/room_list_view.dart` — หน้ารายการห้อง
- `lib/views/room_form_view.dart` — ฟอร์มเพิ่ม/แก้ไขห้อง
- `lib/utils/seed_data.dart` — ข้อมูลตัวอย่าง (seeds)

เทคโนโลยีที่ใช้
- Flutter (Dart)
- PocketBase (local / remote service for realtime DB + file storage)
- Android / iOS / Web / Desktop (ขยายได้ตามการตั้งค่า Flutter)

การติดตั้งและรัน (developer)
1. ติดตั้ง
```powershell
flutter pub get
```
2. เริ่มรัน PocketBase Server
```text
เปิดอีกหน้าต่าง Terminal แล้วรันคำสั่ง:

./pocketbase serve

หรือบน Windows:

pocketbase.exe serve
```
3. สร้าง Collection ชื่อ rooms

สร้างฟิลด์ตามนี้:

ชื่อฟิลด์	ชนิดข้อมูล	คำอธิบาย
room_number	Text	หมายเลขห้อง
room_type	Text	ประเภทห้อง (Single, Double, Suite...)
price	Number	ราคาต่อคืน
status	Text	สถานะห้อง (Available / Occupied / Maintenance)
image	File	รูปภาพของห้อง


4. รันแอป StayEasy
```powershell
flutter run
```


5. ภาพรวมระบบและฟังก์ชันการทำงาน
 ฟังก์ชันหลัก

แสดงรายการห้องพักทั้งหมดในระบบ

เพิ่ม/แก้ไข/ลบห้องได้ (CRUD)

อัปโหลดภาพห้องพักผ่าน PocketBase

ค้นหาห้องตามหมายเลขหรือประเภท

กรองสถานะห้อง (Available, Occupied, Maintenance)

ปุ่ม “Seed Data” สำหรับสร้างข้อมูลตัวอย่างอัตโนมัติ

ลบข้อมูลทั้งหมดในคลิกเดียว (Clear All)


โค้ดสำคัญ
 Model: Room

```dart
class Room {
  final String id;
  final String roomNumber;
  final String roomType;
  final double price;
  final String status;
  final String? imageUrl;

  factory Room.fromRecord(Map<String, dynamic> rec) {
    return Room(
      id: rec['id'],
      roomNumber: rec['room_number'] ?? '',
      roomType: rec['room_type'] ?? '',
      price: (rec['price'] ?? 0).toDouble(),
      status: rec['status'] ?? '',
      imageUrl: rec['image'],
    );
  }

  String? getImageUrl(String baseUrl) {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return '$baseUrl/api/files/rooms/$id/$imageUrl';
  }
}
```


