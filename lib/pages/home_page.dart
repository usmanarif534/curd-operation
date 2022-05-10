import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? file;
  FirebaseStorage storage = FirebaseStorage.instance;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String url = '';
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');
  int counter = 0;

  // pick image
  Future pickAndUploadImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    file = File(pickedFile!.path);
    Reference ref = storage.ref("images/image" + counter.toString());
    counter++;
    UploadTask task = ref.putFile(file!);
    var dowurl =
        await task.whenComplete(() async => await ref.getDownloadURL());
    return url = dowurl.toString();
    // print('URL:=>' + url);
  }

  // create/update product
  Future<void> createOrUpdate(DocumentSnapshot? snapshot) async {
    String action = 'create';
    if (snapshot != null) {
      action = 'update';
      nameController.text = snapshot['name'];
      priceController.text = snapshot['price'].toString();
    }
    await showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                )),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product name'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'USD ',
                    labelText: 'Price',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? name = nameController.text;
                    final double? price = double.tryParse(priceController.text);
                    if (name != null && price != null) {
                      if (action == 'create') {
                        await products.add({"name": name, "price": price});
                        nameController.clear();
                        priceController.clear();
                        Navigator.pop(context);
                      }
                      if (action == 'update') {
                        await products
                            .doc(snapshot!.id)
                            .update({"name": name, "price": price});
                        nameController.clear();
                        priceController.clear();
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ],
            ),
          );
        });
  }

  // delete product

  Future<void> deleteProduct(String productID) async {
    await products.doc(productID).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('deleted successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('CRUD Operations'),
        ),
        body: StreamBuilder(
          stream: products.snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> streamSnapshot) {
            if (streamSnapshot.hasData) {
              return ListView.builder(
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot =
                      streamSnapshot.data!.docs[index];
                  return index.isNaN
                      ? const Center(child: Text('add'))
                      : Card(
                          margin: const EdgeInsets.all(10),
                          child: ExpansionTile(
                            childrenPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(documentSnapshot['name']),
                            subtitle: Text(
                                documentSnapshot['price'].toString() + "\$"),
                            leading: CircleAvatar(
                              radius: 30,
                              // backgroundImage: NetworkImage(url),
                              child: file != null
                                  ? CircleAvatar(
                                      backgroundImage: FileImage(file!),
                                    )
                                  : const Icon(Icons.add),
                            ),
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                      onPressed: () async {
                                        pickAndUploadImage();
                                        print('URL=>' + url);
                                      },
                                      icon: const Icon(Icons.add_a_photo)),
                                  SizedBox(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.blue,
                                          onPressed: () {
                                            createOrUpdate(documentSnapshot);
                                          },
                                        ),
                                        const SizedBox(width: 5),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red,
                                          onPressed: () {
                                            deleteProduct(documentSnapshot.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            createOrUpdate(null);
          },
        ));
  }
}
