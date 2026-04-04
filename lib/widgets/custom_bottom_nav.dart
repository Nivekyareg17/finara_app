import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF10B981);

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        if (index == selectedIndex) return; // evita recargar la misma pantalla

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, "/home");
            break;
          case 1:
            Navigator.pushReplacementNamed(context, "/news");
            break;
          case 2:
            Navigator.pushReplacementNamed(context, "/daiko_ai");
            break;
          case 3:
            Navigator.pushReplacementNamed(context, "/wallet");
            break;
          case 4:
            Navigator.pushReplacementNamed(context, "/profile");
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      unselectedItemColor: const Color(0xFF64748B),
      selectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      unselectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "HOME"),
        BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined), label: "NEWS"),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "DAIKO"),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined), label: "WALLET"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: "PROFILE"),
      ],
    );
  }
}
