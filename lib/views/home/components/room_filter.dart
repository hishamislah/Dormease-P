import 'package:flutter/material.dart';

class RoomFilter extends StatefulWidget {
  final Function(String) onFilter;
  final VoidCallback? onAddRoom;
  
  const RoomFilter({super.key, required this.onFilter, this.onAddRoom});

  @override
  State<RoomFilter> createState() => _RoomFilterState();
}

class _RoomFilterState extends State<RoomFilter> {
  final TextEditingController _filterController = TextEditingController();
  
  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _filterController,
                decoration: InputDecoration(
                  hintText: 'Search by room number...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _filterController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _filterController.clear();
                            widget.onFilter('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  widget.onFilter(value);
                  setState(() {});
                },
              ),
            ),
          ),
          if (widget.onAddRoom != null) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: widget.onAddRoom,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

