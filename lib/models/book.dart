import 'package:firebase_database/firebase_database.dart';

class Book {
  String key;
  String description;
  String title;
  String userId;

  Book(this.description, this.title, this.userId);

  Book.fromMap(Map<String, dynamic> snapshot, String documentID)
      : key = documentID,
        description = snapshot.containsKey('description')
            ? snapshot['description']
            : null,
        title = snapshot.containsKey('title') ? snapshot['title'] : null,
        userId = snapshot.containsKey('user_id') ? snapshot['user_id'] : null;

  toJson() {
    return {"description": description, "title": title, "user_id": userId};
  }
}
