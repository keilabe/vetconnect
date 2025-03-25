import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vetconnect/pages/splash_screen1.dart';
import 'package:vetconnect/pages/splash_screen2.dart';

class SplashScreen3 extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _SplashScreen3State();
  }
}

double? _deviceHeight;
double? _deviceWidth;

class _SplashScreen3State extends State<SplashScreen3> {
  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Center(
            child: Image.asset('assets/images/Group 2.png'),
          ),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Group 2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          _TextContainer(),                    
        ],
      ),
    );
  }

  Widget _TextContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        _textTitle(),
        _textSubtitle(),
      ],
    );
  }

  Widget _textTitle() {
    return Text(
      "Bringing Pet Owners Together with Trusted Veterinarians",
      textAlign: TextAlign.center,
      maxLines: 2,
      softWrap: true,
      style: TextStyle(
        fontWeight: FontWeight.w400,        
        fontSize: 22,
      ),
    );
  }

  Widget _textSubtitle() {
    return Text(
      "Discover the finest care for your beloved pets.",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 17,
      ),
    );
  }

  Widget _beginYourJourney() {
    return MaterialButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      textColor: Colors.white,
      hoverColor: Colors.amber,
      color: Colors.teal,
      minWidth: _deviceWidth! * 0.70,
      height: _deviceHeight! * 0.06,
      child: Text(
        "Begin Your Journey"
      ),
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
      child: Container(
        width: 200,
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.more_horiz, size: 20, color: Colors.grey),
            Icon(Icons.more_horiz, size: 20, color: Colors.grey),
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
