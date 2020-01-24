import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:perseus/models/book.dart';
import 'package:perseus/service/authentication.dart';

enum AuthStatus {
  NOT_DETERMINED,
  NOT_LOGGED_IN,
  LOGGED_IN,
}

class BooksPage extends StatefulWidget {
  BooksPage({Key key, this.auth, this.userId}) : super(key: key);

  final BaseAuth auth;
  final String userId;

  @override
  _BooksPageState createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  final firestoreDb = Firestore.instance;
  Stream<QuerySnapshot> bookStream;

  String _userId = "";
  List<Book> bookList = List();
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.auth.getCurrentUser().then((user) {
      setState(() {
        if (user != null) {
          _userId = user?.uid;
        }
        authStatus =
            user?.uid == null ? AuthStatus.NOT_LOGGED_IN : AuthStatus.LOGGED_IN;
      });
      bookStream = Firestore.instance
          .collection('books')
          .where("user_id", isEqualTo: _userId)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FireStore Demo'),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: _buildBody(context),
      ), //center
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddBookDialog(context);
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  void createRecord(String title, String description) async {
    await firestoreDb
        .collection("books")
        .add({'title': title, 'description': description, 'user_id': _userId});
  }

  void getData() {
    firestoreDb
        .collection("books")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) => print('${f.data}}'));
    });
  }

  void updateData() {
    try {
      firestoreDb
          .collection('books')
          .document('1')
          .updateData({'description': 'Head First Flutter'});
    } catch (e) {
      print(e.toString());
    }
  }

  void deleteData() {
    try {
      firestoreDb.collection('books').document('1').delete();
    } catch (e) {
      print(e.toString());
    }
  }

  Widget _showBookList(List<DocumentSnapshot> documents) {
    bookList = getListFromSnapshot(documents);
    return ListView.builder(
        shrinkWrap: true,
        itemCount: bookList.length,
        itemBuilder: (context, index) {
          String title = bookList[index].title ?? 'Não informado';
          String description = bookList[index].description ?? 'Não informado';
          return ListTile(
            title: Text(title),
            subtitle: Text(description),
            onTap: () {
              //TODO show item in another page
            },
          );
        });
  }

  void showAddBookDialog(BuildContext context) async {
    _titleController.clear();
    _descriptionController.clear();
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: new Column(
              children: <Widget>[
                new Expanded(
                    child: new TextField(
                  controller: _titleController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 3,
                  decoration: new InputDecoration(
                    labelText: 'Book title',
                  ),
                )),
                new Expanded(
                    child: new TextField(
                  controller: _descriptionController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 3,
                  decoration: new InputDecoration(
                    labelText: 'Some book description',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    createRecord(_titleController.text.toString(),
                        _descriptionController.text.toString());
                    Navigator.pop(context);
                  })
            ],
          );
        });
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: bookStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _showBookList(snapshot.data.documents);
      },
    );
  }

  List<Book> getListFromSnapshot(List<DocumentSnapshot> documents) {
    return documents.map((item) => Book.fromMap(item.data)).toList();
  }
}
