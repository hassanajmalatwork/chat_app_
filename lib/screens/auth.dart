import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<StatefulWidget> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _formkey = GlobalKey<FormState>();
  var _isenteredemail = '';
  var _isenteredPassword = '';
  var _islogin = true;
  var _enteredUsername = '';
  File? _selectedImage;
  var _isAuthenticating = false;
  void _submit() async {
    final isValid = _formkey.currentState!.validate();

    if (!isValid || !_islogin && _selectedImage == null) {
      return;
    }

    _formkey.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_islogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _isenteredemail, password: _isenteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _isenteredemail, password: _isenteredPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc('userCredentials.user!.uid')
            .set({
          'username': _enteredUsername,
          'email': _isenteredemail,
          'image_url': imageUrl
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'Email-already-in-use') {
        //...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message ?? 'Authentication failed'),
      ));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                  margin: EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_islogin)
                                UserImagePicker(
                                  onPickImage: (pickdeImage) {
                                    _selectedImage = pickdeImage;
                                  },
                                ),
                              TextFormField(
                                decoration: InputDecoration(labelText: 'Email'),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      !value.contains('@')) {
                                    return 'Please enter a valid email adress';
                                  }
                                },
                                onSaved: (value) {
                                  _isenteredemail = value!;
                                },
                              ),
                              if (!_islogin)
                                TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'Username'),
                                  enableSuggestions: false,
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        value.trim().length < 4) {
                                      return 'Please Enter a valid username (atleast 4 character long).';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredUsername = value!;
                                  },
                                ),
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: 'Password'),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 6) {
                                    return 'Password must be 6 character long';
                                  }
                                },
                                onSaved: (value) {
                                  _isenteredPassword = value!;
                                },
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              if (_isAuthenticating)
                                const CircularProgressIndicator(),
                              if (!_isAuthenticating)
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer),
                                  child: Text(_islogin ? 'Login' : 'Sign up'),
                                ),
                              if (!_isAuthenticating)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _islogin = !_islogin;
                                    });
                                  },
                                  child: Text(_islogin
                                      ? 'Create an account'
                                      : 'I already have an account'),
                                )
                            ],
                          ),
                        )),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
