import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    return _RegisterPageState();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  String? _fullName;
  String? _phoneNumber;
  String? _email;
  String? _password;
  String? _userType;
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
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
      body: SingleChildScrollView(
        child: _registerForm(),
      ),
    );
  }

  Widget _registerForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(height: 30),
            Text(
              "Create Your Account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFamily: 'PlusJakartaSans',
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please fill in the form to continue",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 30),
            _buildTextField(
              labelText: 'Full Name',
              icon: Icons.person,
              onSaved: (value) => _fullName = value,
              validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              onSaved: (value) => _phoneNumber = value,
              validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              onSaved: (value) => _email = value,
              validator: (value) => !value!.contains('@') ? 'Enter a valid email' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Password',
              icon: Icons.lock,
              obscureText: true,
              onSaved: (value) => _password = value,
              validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              labelText: 'Confirm Password',
              icon: Icons.lock,
              obscureText: true,
              onSaved: (_) {},
              validator: (value) => value != _password ? 'Passwords do not match' : null,
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'User Type',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                items: ['Farmer', 'Veterinarian'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Please select a user type' : null,
                onChanged: (value) {
                  setState(() {
                    _userType = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I agree to the Terms and Conditions',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _agreedToTerms) {
                    _formKey.currentState!.save();
                    // Handle form submission
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "ALREADY HAVE AN ACCOUNT? ",            
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                  ),
                  TextSpan(
                    text: "LOGIN",
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
  }) {
    return Container(
      width: double.infinity,
      child: TextFormField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.black),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}