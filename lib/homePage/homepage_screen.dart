import 'package:flutter/material.dart';
import 'package:notify/constants.dart';
import 'package:notify/db/notes_database.dart';
import 'package:notify/edit_add_note_screen/edit_add_note_screen.dart';
import 'package:notify/homePage/components/empty_notes.dart';
import 'package:notify/model/note.dart';

import 'components/single_note.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key}) : super(key: key);

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  late List<Note> notes;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  @override
  void dispose() {
    NotesDatabase.instance.closeDB();
    super.dispose();
  }

  Future refreshNotes() async {
    setState(() => isLoading = true);
    notes = await NotesDatabase.instance.readAllNotes();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : notes.isEmpty
                    ? const EmptyNotes()
                    : buildNotes(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kYellow,
          elevation: 0,
          child: const Icon(Icons.add),
          onPressed: () async {
            refreshNotes();
          },
        ),
      ),
    );
  }

  Widget buildNotes() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Note it!", style: kHeaderDarkTitle),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.startToEnd,
                        dismissThresholds: const {
                          DismissDirection.startToEnd: 0.25
                        },
                        movementDuration: const Duration(milliseconds: 800),
                        resizeDuration: const Duration(milliseconds: 600),
                        onDismissed: (direction) async {
                          await NotesDatabase.instance.deleteNote(note.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('your note will be save'),
                            action: SnackBarAction(
                              onPressed: () async {
                                await NotesDatabase.instance.insertNote(Note(
                                  id: note.id,
                                  title: note.title,
                                  content: note.content,
                                  color: note.color,
                                  createdAt: note.createdAt,
                                ));
                                refreshNotes();
                              },
                              label: "Alert!",
                            ),
                            duration: const Duration(milliseconds: 2000),
                          ));
                        },
                        background: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            color: Colors.red[400],
                          ),
                        ),
                        child: SingleNote(
                            id: note.id,
                            title: note.title,
                            content: note.content.trim(),
                            color: note.color,
                            createdAt: note.createdAt,
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditAddNoteScreen(
                                    note: note,
                                  ),
                                ),
                              );
                              refreshNotes();
                            })),
                  );
                },
              ),
            )
          ],
        ),
      );
}
