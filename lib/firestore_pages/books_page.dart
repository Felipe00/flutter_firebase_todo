import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
          showAddBookDialog(context, null);
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

  void updateData(Book book) {
    try {
      firestoreDb
          .collection('books')
          .where('user_id', isEqualTo: _userId)
          .reference()
          .document(book.key)
          .updateData({'description': book.description, 'title': book.title});
    } catch (e) {
      print(e.toString());
    }
  }

  void deleteData(String key) {
    try {
      firestoreDb
          .collection('books')
          .where('user_id', isEqualTo: _userId)
          .reference()
          .document(key)
          .delete();
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
          String key = bookList[index].key ??
              DateTime.now().millisecondsSinceEpoch.toString();
          String title = bookList[index].title ?? 'Não informado';
          String description = bookList[index].description ?? 'Não informado';
          return Dismissible(
            direction: DismissDirection.startToEnd,
            onDismissed: (direction) async {
              deleteData(key);
            },
            key: Key(key),

            background: Container(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                color: Colors.red),
            child: ListTile(
              title: Text(title),
              subtitle: Text(description),
              onTap: () {
                showAddBookDialog(context, bookList[index]);
              },
            ),
          );
        });
  }

  void showAddBookDialog(BuildContext context, Book book) async {
    String btnConfirm = "Save";
    if (book == null) {
      _titleController.clear();
      _descriptionController.clear();
    } else {
      btnConfirm = "Update";
      _titleController.text = book.title;
      _descriptionController.text = book.description;
    }
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Book title',
                  ),
                )),
                Expanded(
                    child: TextField(
                  controller: _descriptionController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Some book description',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              FlatButton(
                  child: Text(btnConfirm),
                  onPressed: () {
                    if (book == null) {
                      createRecord(_titleController.text.toString(),
                          _descriptionController.text.toString());
                    } else {
                      book.title = _titleController.text.toString();
                      book.description = _descriptionController.text.toString();
                      updateData(book);
                    }
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
    return documents
        .map((item) => Book.fromMap(item.data, item.documentID))
        .toList();
  }
}
