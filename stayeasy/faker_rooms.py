from faker import Faker
import random
import requests
import json

# ✅ URL ของ PocketBase API
POCKETBASE_URL = "http://127.0.0.1:8090/api/collections/rooms/records"

# ✅ สร้าง Faker object
fake = Faker()

# ✅ ตัวเลือกจำลอง
room_types = ["Single", "Double", "Suite", "Deluxe"]
statuses = ["Available", "Occupied", "Maintenance"]

# ✅ สร้างข้อมูลจำลอง 100 รายการ
rooms_data = []
for i in range(100):
    data = {
        "room_number": str(100 + i),                      # หมายเลขห้อง 100–199
        "room_type": random.choice(room_types),           # ประเภทห้อง
        "price": round(random.uniform(1000, 10000), 2),   # ราคาสุ่ม
        "status": random.choice(statuses),                # สถานะห้อง
        "imageUrl": f"https://picsum.photos/seed/{i}/400/300"  # รูปจำลองจาก picsum
    }
    rooms_data.append(data)

# ✅ แสดงข้อมูลตัวอย่างก่อนอัปโหลด
print("🚀 Preview sample data:")
print(json.dumps(rooms_data[:5], indent=2, ensure_ascii=False))

# ✅ ส่งข้อมูลเข้า PocketBase
print("\n📤 Uploading to PocketBase...")
success = 0
fail = 0

for room in rooms_data:
    response = requests.post(POCKETBASE_URL, json=room)
    if response.status_code == 200:
        success += 1
        print(f"✅ Added Room {room['room_number']} ({room['room_type']})")
    else:
        fail += 1
        print(f"❌ Failed to add Room {room['room_number']}: {response.text}")

print(f"\n🎉 Completed! Success: {success}, Failed: {fail}")
