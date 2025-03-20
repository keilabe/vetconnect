import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vetconnect/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    return _LoginPageState();

  }

}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  double? _deviceHeight;
  double? _deviceWidth;

  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(        
        toolbarHeight: 100, 
        leading: Icon(Icons.arrow_back_ios_new, color: Colors.black),         
        title: Text(
          "Vet Connect",
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),       
       centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/cow_vet.png'),
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
        ),
        backgroundColor: Colors.white,
       elevation: 0,
       actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: IconButton(
              onPressed: (){}, 
              icon: Icon(Icons.question_mark_rounded, color: Colors.black, size: 20),
            ),
          )
       ],
      ),
      body: Container(
        height: _deviceHeight,
        width: _deviceWidth,
        child: SingleChildScrollView(
        child: Column(
          children: [
            _loginPageWelcomeTextAndForm(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _loginPageWelcomeTextAndForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: _deviceHeight! * 0.03),
            Text(
              "Welcome Back!",
              textAlign: TextAlign.center,    
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: 'PlusJakartaSans'
              ),
            ),
            SizedBox(height: _deviceHeight! * 0.04),
            _emailTextField(),
            SizedBox(height: _deviceHeight! * 0.02),
            _passwordTextField(),
            SizedBox(height: _deviceHeight! * 0.04),
            _loginButtonWithOtherPlatforms(),
            SizedBox(height: _deviceHeight! * 0.04),
            _loginButton(),
            SizedBox(height: _deviceHeight! * 0.02),
            _forgotPasswordButton(),
            SizedBox(height: _deviceHeight! * 0.02),
            _registerButton(),
            SizedBox(height: _deviceHeight! * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _emailTextField() {
    return Container(
      width: double.infinity,
      child: TextFormField(
        key: ValueKey('email'),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.email, color: Colors.black),
          hintText: "Email...",
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        validator: (value) {
          print('Validating email: $value');
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
        onSaved: (value) {
          print('Saving email: $value');
          email = value;
        },
      ),
    );
  }

  Widget _passwordTextField() {
    return Container(
      width: double.infinity,
      child: TextFormField(
        key: ValueKey('password'),
        obscureText: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          hintText: "Password...",
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        validator: (value) {
          print('Validating password: ${value?.length ?? 0} characters');
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        onSaved: (value) {
          print('Saving password: ${value?.length ?? 0} characters');
          password = value;
        },
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          "Login",
      style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

Widget _loginButtonWithOtherPlatforms() {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          _loginButtonWithApple(),
          SizedBox(height: 10),
          _loginButtonWithGoogle(),
          SizedBox(height: 10),
          _loginButtonWithFacebook(),
        ],
      ),
    );
  }

  Widget _loginButtonWithGoogle() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (){},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Color.fromRGBO(73, 110, 106, 0.2),
          fixedSize: Size.fromHeight(55), 
        ),
        child: Stack(
          children: [
            Positioned(
              left: 30, 
              top: 0,
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/google.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Icon(Icons.g_mobiledata, color: Colors.black, size: 28);
                  },
                ),
              ),
            ),
            Center(
              child: Text(
                "Login with Google",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Colors.black
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButtonWithFacebook() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (){},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Color.fromRGBO(58, 99, 237, 1),
          fixedSize: Size.fromHeight(55), 
        ),
        child: Stack(
          children: [
            Positioned(
              left: 30,
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.center,
                child: Icon(Icons.facebook_outlined, color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                "Login with Facebook",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButtonWithApple() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (){},
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.teal,
          fixedSize: Size.fromHeight(55),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 30, 
              top: 0,
              bottom: 0,
              child: Container(
                alignment: Alignment.center,
                child: Icon(Icons.apple, color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                "Login with Apple",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _forgotPasswordButton() {
    return Container(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: (){},
        child: Text(
          "Forgot Password?",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _registerButton() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "DON'T HAVE AN ACCOUNT? ",            
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
          TextSpan(
            text: "SIGN UP",
            style: TextStyle(
              color: Colors.teal,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // navigate to register page
              Navigator.pushNamed(context, '/register');
              },
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    print('Login process started');
    
    if (_loginFormKey.currentState?.validate() ?? false) {
      print('Form validation passed');
      _loginFormKey.currentState?.save();
      print('Email: $email'); // Don't log password for security
      
      try {
        print('Attempting Firebase authentication...');
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ),
        );

        // Firebase Authentication
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        print('Firebase authentication successful');
        print('User ID: ${userCredential.user?.uid}');
        print('User email: ${userCredential.user?.email}');

        // Close loading indicator
        Navigator.pop(context);
        
        if (userCredential.user != null) {
          print('Setting user as logged in...');
          // Set user as logged in
          await UserService.setUserLoggedIn(true);
          print('User logged in status updated successfully');
          
          // Navigate to home page
          if (mounted) {
            print('Navigating to home page...');
            Navigator.pushReplacementNamed(context, '/homepage');
          } else {
            print('Widget not mounted, navigation cancelled');
          }
        } else {
          print('User credential is null after successful authentication');
        }
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth Exception: ${e.code}');
        print('Error message: ${e.message}');
        // Close loading indicator
        Navigator.pop(context);
        
        // Show error message
        if (mounted) {
          String errorMessage = 'An error occurred';
          if (e.code == 'user-not-found') {
            errorMessage = 'No user found with this email';
          } else if (e.code == 'wrong-password') {
            errorMessage = 'Wrong password provided';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Invalid email address';
          }
          print('Showing error message: $errorMessage');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('Widget not mounted, error message not shown');
        }
      } catch (e) {
        print('Unexpected error during login: $e');
        print('Error type: ${e.runtimeType}');
        // Close loading indicator
        Navigator.pop(context);
        
        // Show error message
        if (mounted) {
          print('Showing generic error message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('Widget not mounted, error message not shown');
        }
      }
    } else {
      print('Form validation failed');
    }
  }
}