import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'header.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, titleText: 'Omega Share'),
    );
  }
}
