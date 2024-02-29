import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notes App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Notes app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title:
              Text(widget.title, style: const TextStyle(color: Colors.white)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showTextInputDialog(
                context: context,
                title: 'Add note',
                style: AdaptiveStyle.iOS,
                textFields: const [
                  DialogTextField(hintText: 'Title'),
                  DialogTextField(hintText: 'Note', maxLines: 10, minLines: 5)
                ]).then((result) async {
              if (result != null) {
                var x =
                    await FirebaseFirestore.instance.collection('notes').add({
                  'title': result[0],
                  'note': result[1],
                  'created_at': FieldValue.serverTimestamp()
                });
                //add id to the document
                await x.update({'id': x.id}).then((value) =>
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note added'))));
              }
            });
          },
          tooltip: 'Add note',
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('notes').get(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No notes added yet'));
            }
            var data = snapshot.data!.docs;

            //sort the notes by created_at
            data.sort((a, b) {
              var aCreatedAt = a['created_at'] as Timestamp;
              var bCreatedAt = b['created_at'] as Timestamp;
              return bCreatedAt.compareTo(aCreatedAt);
            });
            return ListView(
              children: data.map((DocumentSnapshot document) {
                var data = document.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    hoverColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text(data['title'],
                        style: const TextStyle(fontSize: 20)),
                    subtitle: Text(data['note'],
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showOkCancelAlertDialog(
                                context: context,
                                title: 'Delete note',
                                message:
                                    'Are you sure you want to delete this note?',
                                style: AdaptiveStyle.iOS)
                            .then((result) async {
                          if (result == OkCancelResult.ok) {
                            await FirebaseFirestore.instance
                                .collection('notes')
                                .doc(document.id)
                                .delete()
                                .then((value) => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text('Note deleted'))));
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ));
  }
}
