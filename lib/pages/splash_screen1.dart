import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});
    

@override
  State<StatefulWidget> createState() {
    return _SplashScreen1State();
  }
}

class _SplashScreen1State extends State<SplashScreen1> {  
  double? _deviceWidth;
  double? _deviceHeight;  

  Widget _threeDotsNavigation(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (TapGestureRecognizer instance) {
            instance.onTapDown = (TapDownDetails details) {
              _handleTap(details.globalPosition);
            };
          },
        ),
      },
      child: SizedBox(
        width: 200,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.more_horiz, size: 20, color: Colors.amber),
            Icon(Icons.more_horiz, size: 20, color: Colors.grey),
            Icon(Icons.more_horiz, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    final tapPosition = position;
    int index = 0;
    if (tapPosition.dx > 50 && tapPosition.dx < 100) {
      index = 0;
    } else if (tapPosition.dx > 100 && tapPosition.dx < 150) {
      index = 1;
    } else if (tapPosition.dx > 150 && tapPosition.dx < 200) {
      index = 2;
    }
    _navigateToNextScreen(index);
  }

  void _navigateToNextScreen(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/splash1');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/splash2');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/splash3');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
  _deviceWidth = MediaQuery.of(context).size.width;
  _deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: _deviceWidth,
            height: _deviceHeight,
            color: Colors.white,
          ),
          // Top Circular Icon
      Positioned(
        top: -_deviceWidth! * 0.25,
        left: -_deviceWidth! * 0.25,
        child: _circularIcon(Colors.teal),
      ),
      // Bottom Circular Icon
      Positioned(
        bottom: -_deviceWidth! * 0.25,
        right: -_deviceWidth! * 0.25,
        child: _circularIcon(Colors.amber),
      ),
      //Center logo
      Center(
        child: Image.asset('assets/images/Group 2.png'),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: _threeDotsNavigation(context),
      )
        ],
      ),
    );    
  }

    

   // Widget to create circular decorations
  Widget _circularIcon(Color color) {
    return Container(
      width: _deviceWidth! * 0.5, // Full size of the circle
      height: _deviceWidth! * 0.5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}