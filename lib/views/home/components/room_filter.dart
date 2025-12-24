import 'package:flutter/material.dart';

class RoomFilter extends StatefulWidget {
  final Function(String) onFilter;
  
  const RoomFilter({super.key, required this.onFilter});

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: 'Filter by room number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: widget.onFilter,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _filterController.clear();
              widget.onFilter('');
            },
          ),
        ],
      ),
    );
  }
}