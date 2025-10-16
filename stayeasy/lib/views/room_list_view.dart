import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/room_controller.dart';
import '../services/pb_service.dart';
import '../utils/seed_data.dart';
import 'room_form_view.dart';

class RoomListView extends StatefulWidget {
  const RoomListView({super.key});

  @override
  State<RoomListView> createState() => _RoomListViewState();
}

class _RoomListViewState extends State<RoomListView> with TickerProviderStateMixin {
  final c = Get.put(RoomController());
  final searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
    Future.delayed(Duration.zero, () => c.fetchRooms());
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('StayEasy',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                Text('Room Management',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => c.fetchRooms(),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF6366F1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) async {
              if (value == 'seed_100') {
                _showLoadingDialog();
                await SeedData.seed100Rooms();
                Get.back();
                c.fetchRooms();
                _ok('✨ 100 rooms created successfully!');
              } else if (value == 'seed_sample') {
                _showLoadingDialog();
                await SeedData.seedSampleRooms();
                Get.back();
                c.fetchRooms();
                _ok('✨ Sample rooms created!');
              } else if (value == 'clear_all') {
                _confirmClearAll();
              }
            },
            itemBuilder: (context) => [
              _menuItem('seed_sample', Icons.add_circle_outline_rounded, 'Create 10 Samples', const Color(0xFF10B981)),
              _menuItem('seed_100', Icons.dataset_rounded, 'Create 100 Rooms', const Color(0xFF6366F1)),
              const PopupMenuDivider(),
              _menuItem('clear_all', Icons.delete_sweep_rounded, 'Clear All Rooms', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const RoomFormView()),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Room', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Obx(() {
          if (c.loading.value) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }
          return Column(
            children: [
              const SizedBox(height: 110),
              _searchBar(),
              _filterChips(),
              _statsBar(),
              Expanded(
                child: c.filteredRooms.isEmpty ? _emptyState() : _roomGrid(),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---------- UI Components ----------

  PopupMenuItem<String> _menuItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 3))],
        ),
        child: TextField(
          controller: searchController,
          onChanged: (v) => c.setSearch(v),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search rooms by number or type...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Obx(() => c.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF9CA3AF), size: 18),
                    onPressed: () {
                      searchController.clear();
                      c.setSearch('');
                    },
                  )
                : const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    final filters = [
      {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFF6366F1)},
      {'name': 'Available', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
      {'name': 'Occupied', 'icon': Icons.person_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'Maintenance', 'icon': Icons.build_rounded, 'color': const Color(0xFFEF4444)},
    ];
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          return Obx(() {
            final selected = c.selectedFilter.value == f['name'];
            final color = f['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                onTap: () => c.setFilter(f['name'] as String),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? Colors.transparent : const Color(0xFFE5E7EB)),
                    boxShadow: [
                      if (selected) BoxShadow(color: color.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(f['icon'] as IconData, size: 18, color: selected ? Colors.white : color),
                      const SizedBox(width: 6),
                      Text(
                        f['name'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF1E1E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _statsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Found ${c.filteredRooms.length} rooms',
                style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (c.searchQuery.value.isNotEmpty || c.selectedFilter.value != 'All')
              TextButton.icon(
                onPressed: () {
                  searchController.clear();
                  c.setSearch('');
                  c.setFilter('All');
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.white),
                label: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white.withOpacity(0.18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ✅ Grid (รูป 70% / ข้อมูล 30%)
  Widget _roomGrid() {
    final w = MediaQuery.of(context).size.width;
    final cols = w < 900 ? 2 : 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.66,
        ),
        itemCount: c.filteredRooms.length,
        itemBuilder: (_, i) {
          final r = c.filteredRooms[i];
          final img = r.getImageUrl(PBService.baseUrl) ?? 'https://picsum.photos/seed/${r.id}/600/400';
          return _roomCard(r, img);
        },
      ),
    );
  }

  /// ✅ การ์ดห้องพัก (ภาพ 70%)
  Widget _roomCard(room, String img) {
    final statusColor = _statusColor(room.status);
    final statusIcon = _statusIcon(room.status);

    return GestureDetector(
      onTap: () => Get.to(() => RoomFormView(room: room)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูป (70%)
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                    child: Image.network(
                      img,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            room.status,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ข้อมูล (30%)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room ${room.roomNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E1E2E))),
                    const SizedBox(height: 4),
                    Text(room.roomType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('฿${room.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF6366F1))),
                        IconButton(
                          onPressed: () => _confirmDelete(room.id),
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF6366F1)),
            SizedBox(height: 16),
            Text('No rooms found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('Try adjusting your filters or search query', style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
          ],
        ),
      );

  // ---------- Helpers ----------

  Color _statusColor(String s) => {
        'available': const Color(0xFF10B981),
        'occupied': const Color(0xFFF59E0B),
        'maintenance': const Color(0xFFEF4444)
      }[s.toLowerCase()] ?? const Color(0xFF6366F1);

  IconData _statusIcon(String s) => {
        'available': Icons.check_circle_rounded,
        'occupied': Icons.person_rounded,
        'maintenance': Icons.build_rounded
      }[s.toLowerCase()] ?? Icons.info_rounded;

  void _showLoadingDialog() => Get.dialog(
        const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        barrierDismissible: false,
      );

  void _ok(String msg) => Get.snackbar(
        'Success',
        msg,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

  void _confirmClearAll() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Rooms?'),
        content: const Text('This will permanently delete all rooms.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Get.back();
              _showLoadingDialog();
              await SeedData.clearAllRooms();
              Get.back();
              c.fetchRooms();
              Get.snackbar('Deleted', '🗑️ All rooms cleared successfully',
                  backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room'),
        content: const Text('Are you sure you want to delete this room?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              c.deleteRoom(id);
              Get.back();
              Get.snackbar('Deleted', 'Room deleted successfully',
                  backgroundColor: const Color(0xFFEF4444), colorText: Colors.white);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
