import 'package:flutter/material.dart';

Container circularProgress(){
  return Container(
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.grey),
      )
  );
}
Container linearProgress(){
  return Container(
      padding: EdgeInsets.only(bottom: 10.0),
      child: LinearProgressIndicator(
        backgroundColor: Colors.purple[100],
        valueColor: AlwaysStoppedAnimation(Colors.purple.withOpacity(0.8)),
      )
  );
}