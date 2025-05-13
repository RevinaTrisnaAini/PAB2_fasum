import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:fasum/screens/add_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Fasum'
          , style: TextStyle(
          color: Colors.green[600],
          fontWeight: FontWeight.bold,)
          ,),
        actions: [
          IconButton(
            onPressed: _showCategoryFlter,
            icon: Icon(Icons.filter_list),
            tooltip: 'filter kategori',
          ),
          IconButton(
            onPressed: () {
              signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body:  (
        onReferces

      )
        child : Card(
        elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shadowColor: Theme.of(context).colorScheme.shadow,
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageBase64 != null)
            ClipRect(
              borderRadius BorderRadius.vertical(
              top: Radius.circular(10),
             ),
             child: Hero(
             tag: heroTag,
             child: Image.memory(
             base64Decode(imageBase64),
             fit: BoxFit.cover,
             width: double.infinity,
    height: 200,
            Padding()
    ),
             )
            )
        ],
      ),
    )
    );
