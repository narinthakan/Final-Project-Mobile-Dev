// lib/utils/seed_data.dart
import 'dart:math';
import '../services/pb_service.dart';

class SeedData {
  static final _random = Random();
  static final pb = PBService();

  static List<String> roomTypes = ['Single', 'Double', 'Suite', 'Deluxe'];
  static List<String> statuses = ['Available', 'Occupied', 'Maintenance'];

  static Future<void> seed100Rooms() async {
    print('🌱 Starting to seed 100 rooms...');
    
    int created = 0;

    for (int i = 1; i <= 100; i++) {
      try {
        final floor = (i ~/ 100) + 1;
        final roomNum = (i % 100).toString().padLeft(2, '0');
        final roomNumber = '$floor$roomNum';
        final roomType = roomTypes[_random.nextInt(roomTypes.length)];
        final status = statuses[_random.nextInt(statuses.length)];
        final price = _generatePrice(roomType);

        final body = {
          'room_number': roomNumber,
          'room_type': roomType,
          'price': price,
          'status': status,
        };

        await pb.client.collection('rooms').create(body: body);
        created++;
        
        if (i % 10 == 0) {
          print('✅ Created $i/100 rooms...');
        }
      } catch (e) {
        print('❌ Failed to create room $i: $e');
      }

      if (i % 20 == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    print('🎉 Created $created rooms!');
  }

  static Future<void> seedSampleRooms() async {
    print('🌱 Creating 10 sample rooms...');
    
    final sampleRooms = [
      {'number': '101', 'type': 'Single', 'price': 500.0, 'status': 'Available'},
      {'number': '102', 'type': 'Single', 'price': 500.0, 'status': 'Occupied'},
      {'number': '103', 'type': 'Double', 'price': 800.0, 'status': 'Available'},
      {'number': '104', 'type': 'Double', 'price': 800.0, 'status': 'Available'},
      {'number': '105', 'type': 'Suite', 'price': 1500.0, 'status': 'Available'},
      {'number': '201', 'type': 'Single', 'price': 550.0, 'status': 'Maintenance'},
      {'number': '202', 'type': 'Double', 'price': 850.0, 'status': 'Occupied'},
      {'number': '203', 'type': 'Suite', 'price': 1600.0, 'status': 'Available'},
      {'number': '204', 'type': 'Deluxe', 'price': 2000.0, 'status': 'Available'},
      {'number': '205', 'type': 'Deluxe', 'price': 2000.0, 'status': 'Occupied'},
    ];

    for (var room in sampleRooms) {
      try {
        final body = {
          'room_number': room['number'],
          'room_type': room['type'],
          'price': room['price'],
          'status': room['status'],
        };
        
        await pb.client.collection('rooms').create(body: body);
        print('✅ Created room ${room['number']}');
      } catch (e) {
        print('❌ Failed: $e');
      }
    }
    
    print('🎉 Sample rooms created!');
  }

  static Future<void> clearAllRooms() async {
    print('🗑️ Clearing all rooms...');
    
    try {
      final result = await pb.client.collection('rooms').getFullList();
      
      for (var record in result) {
        await pb.client.collection('rooms').delete(record.id);
      }
      
      print('✅ Deleted ${result.length} rooms');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  static double _generatePrice(String roomType) {
    switch (roomType) {
      case 'Single':
        return 500.0 + _random.nextInt(200);
      case 'Double':
        return 800.0 + _random.nextInt(300);
      case 'Suite':
        return 1500.0 + _random.nextInt(500);
      case 'Deluxe':
        return 2000.0 + _random.nextInt(1000);
      default:
        return 500.0;
    }
  }
}