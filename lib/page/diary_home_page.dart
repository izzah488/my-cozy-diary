import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../diary_database.dart';
import 'profile_page.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _currentIndex = 0;

  List<Map<String, dynamic>> _entriesForSelectedDay = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final allEntries = await DiaryDatabase.instance.fetchEntries();
    final filtered = allEntries.where((entry) {
      final entryDate = DateTime.parse(entry['date']);
      return isSameDay(entryDate, _selectedDay);
    }).toList();

    setState(() {
      _entriesForSelectedDay = filtered;
    });
  }

  Future<void> _addEntry() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedEmoji = '😊';
    File? selectedImage;

    Future<void> _pickImage(StateSetter setDialogState) async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setDialogState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Diary Entry'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Content'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: ['😊', '😄', '😢', '🥳', '😭', '😎'].map((emoji) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: 28,
                              backgroundColor: selectedEmoji == emoji
                                  ? Colors.amberAccent
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(setDialogState),
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                    ),
                    const SizedBox(height: 10),
                    selectedImage != null
                        ? Image.file(selectedImage!, height: 100)
                        : const Text('No image selected.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await DiaryDatabase.instance.insertEntry({
                      'date': _selectedDay.toIso8601String(),
                      'title': titleController.text,
                      'content': contentController.text,
                      'emoji': selectedEmoji,
                      'imagePath': selectedImage?.path,
                    });
                    Navigator.pop(context);
                    _loadEntries();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cozy Diary'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadEntries();
            },
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildDiaryList()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF6F61),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) _addEntry();
          if (index == 2) {
  DiaryDatabase.instance.getTotalEntryCount().then((count) {
    Navigator.push(context,
      MaterialPageRoute(builder: (context) => ProfilePage(totalEntries: count))
    );
  });
}

        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'New Entry'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDiaryList() {
    if (_entriesForSelectedDay.isEmpty) {
      return const Center(
        child: Text(
          'No entries for this day.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _entriesForSelectedDay.length,
      itemBuilder: (context, index) {
        final entry = _entriesForSelectedDay[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: entry['imagePath'] != null
                ? Image.file(File(entry['imagePath']), width: 50, height: 50, fit: BoxFit.cover)
                : Text(entry['emoji'], style: const TextStyle(fontSize: 24)),
            title: Text(entry['title']),
            subtitle: Text(entry['content']),
          ),
        );
      },
    );
  }
}
