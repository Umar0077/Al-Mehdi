import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive font sizes based on screen width
    final fontSize = screenWidth < 320 ? 10.0 : 
                    screenWidth < 375 ? 11.0 : 
                    screenWidth < 414 ? 12.0 : 12.0;
    
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: fontSize),
      unselectedLabelStyle: TextStyle(fontSize: fontSize),
      selectedIconTheme: IconThemeData(size: screenWidth < 320 ? 20 : 24),
      unselectedIconTheme: IconThemeData(size: screenWidth < 320 ? 20 : 24),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Attendance'),
        BottomNavigationBarItem(icon: Icon(Iconsax.user), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}
