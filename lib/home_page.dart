import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageController = PageController();
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demo"),
      ),
      body: PageView(
        controller: _pageController,
        children: [
          Center(child: Text("page 1")),
          Center(child: Text("page 2")),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
                selectedItemColor: Colors.red,
                unselectedItemColor: Colors.yellow,
                selectedLabelStyle: TextStyle(color: Colors.red),
                unselectedLabelStyle: TextStyle(color: Colors.yellow))),
        child: BottomNavigationBar(
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            // selectedLabelStyle: TextStyle(color: Colors.red),
            currentIndex: _currentIndex,
            onTap: (index) {
              _currentIndex = index;
              _pageController.jumpToPage(index);
              setState(() {});
            },
            unselectedLabelStyle: TextStyle(color: Colors.blue),
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Person')
            ]),
      ),
    );
  }
}
