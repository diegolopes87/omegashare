import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omegashare/models/user.dart';
import 'package:omegashare/pages/home.dart';
import 'package:omegashare/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.camera, maxHeight: 675, maxWidth: 960);

    setState(() {
      this.file = file;
    });
  }

  handleImageFromGallery() async {
    print(currentUser.photoUrl);
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) => SimpleDialog(
              title: Text('Criar um post'),
              children: <Widget>[
                SimpleDialogOption(
                  child: Text('Foto da câmera'),
                  onPressed: handleTakePhoto,
                ),
                SimpleDialogOption(
                  child: Text('Foto da galeria'),
                  onPressed: handleImageFromGallery,
                ),
                SimpleDialogOption(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ));
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            "assets/images/upload.svg",
            height: 260.0,
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: RaisedButton(
              onPressed: () => selectImage(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text('Selecione a imagem', style: TextStyle(color: Colors.white, fontSize: 16.0)),
              color: Colors.deepOrangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostOnFirestore(
      mediaUrl: mediaUrl,
      caption: captionController.text,
      location: locationController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId= Uuid().v4();
    });
  }

  createPostOnFirestore({String mediaUrl, String location, String caption}) {
    postsRef.document(currentUser.id).collection("userPosts").document(postId).setData({
      "postId": postId,
      "ownerId": currentUser.id,
      "username": currentUser.username,
      "mediaUrl": mediaUrl,
      "caption": caption,
      "location": location,
      "timestamp": timestamp,
      "likes":{},
    });
  }


  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask = storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: () => clearImage(),
        ),
        backgroundColor: Colors.white,
        title: Text('Criar post', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text('Postar', style: TextStyle(color: Colors.blueAccent, fontSize: 20.0)),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : SizedBox.shrink(),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl),
              ),
              title: Container(
                width: 250.0,
                child: TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                    hintText: 'Escreva algo...',
                    border: InputBorder.none,
                  ),
                ),
              )),
          Divider(
            height: 2.0,
          ),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35,
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(hintText: 'Local', border: InputBorder.none),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: RaisedButton.icon(
                onPressed: () => print('oi'),
                icon: Icon(
                  Icons.my_location,
                  color: Colors.white,
                ),
                label: Text('Localização atual', style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                color: Colors.lightBlueAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
