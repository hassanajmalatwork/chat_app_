import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class newMessege extends StatefulWidget {
  const newMessege({super.key});
  @override
  State<newMessege> createState() {
    return _NewMessegeState();
  }
}

class _NewMessegeState extends State<newMessege> {
  final _messegeController = TextEditingController();
  @override
  void dispose() {
    _messegeController.dispose();
    super.dispose();
  }

  void _submitMessege() async {
    final enteredMessge = _messegeController.text;
    if (enteredMessge.trim().isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    FirebaseFirestore.instance.collection('chat').add({
      'text': enteredMessge,
      'createAT': Timestamp.now(),
      'userID': user.uid,
      'username': userData.data()!['username'],
      'userImage': userData.data()!['image_url'],
    });
    _messegeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        right: 1,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messegeController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(labelText: 'Send a messege...'),
            ),
          ),
          IconButton(
              color: Theme.of(context).colorScheme.primary,
              onPressed: _submitMessege,
              icon: const Icon(Icons.send))
        ],
      ),
    );
  }
}
