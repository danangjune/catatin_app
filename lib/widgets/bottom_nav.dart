import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({Key? key, required this.currentIndex})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Tambah height container
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BottomAppBar(
          height: 80, // Sesuaikan height bottomAppBar
          notchMargin: 8,
          shape: CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_rounded, 'Home', '/'),
              _buildNavItem(
                context,
                1,
                Icons.savings_rounded,
                'Tabungan',
                '/savings',
              ),
              SizedBox(width: 40),
              _buildNavItem(
                context,
                2,
                Icons.assessment_rounded,
                'Evaluasi',
                '/evaluation',
              ),
              _buildNavItem(
                context,
                3,
                Icons.history_rounded,
                'Riwayat',
                '/history',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String route,
  ) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ), // Kurangi vertical padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              MainAxisAlignment.center, // Tambah ini untuk posisi tengah
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF20BF55) : Colors.grey,
              size: 24,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Color(0xFF20BF55) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
