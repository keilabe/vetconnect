import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});


  @override
  createState() {
    return _SplashScreen2State();
  }
}

class _SplashScreen2State extends State<SplashScreen2> {
  double? _deviceWidth;
  double? _deviceHeight;
 
  @override
  Widget build(BuildContext context) {
    _deviceWidth = MediaQuery.of(context).size.width;
    _deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [ 
          Center(
            child: Image.asset('assets/images/Group 2.png'),
          ),
          
          _textContainer(),

          
        ],
      ),
    );
  }

  Widget _textContainer() {
    return SizedBox(
      width: _deviceWidth! * 0.8,
      child: Column(
        children: [
          _introText(),
          SizedBox(height: _deviceHeight! * 0.35),
          _reccomendationText(),
          SizedBox(height: _deviceHeight! * 0.02),
          _threeDotsNavigation(),
        ],
      ),
    );
  }

  Widget _introText() {
    return Text(
            "Get Veterinary Help Anytime, Anywhere!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.teal,              
            ),
          );
  }

  Widget _reccomendationText() {
    return Text(
      "Find and book nearby veterinarians easily to keep your livestock healthy and productive.",
      style: TextStyle(        
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: Colors.teal,    
      ),
      textAlign: TextAlign.center,
      maxLines: 4,
      softWrap: true,
    );
  }

  Widget _threeDotsNavigation() {
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
}
