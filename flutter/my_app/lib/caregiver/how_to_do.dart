import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HowToDo extends StatefulWidget {
  const HowToDo({super.key});

  @override
  _HowToDoState createState() => _HowToDoState();
}

class _HowToDoState extends State<HowToDo> {
  List<HowItem> items = [];

  final titleController = TextEditingController();
  List<TextEditingController> stepControllers = [];

  void openDialog() {
    titleController.clear();
    stepControllers = [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add How To Do"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    /// TITLE
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "What is the task?",
                      ),
                    ),

                    SizedBox(height: 10),

                    /// STEPS
                    Column(
                      children: List.generate(stepControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: stepControllers[index],
                            decoration: InputDecoration(
                              labelText: "Step ${index + 1}",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 10),

                    /// ADD STEP BUTTON
                    ElevatedButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          stepControllers.add(TextEditingController());
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text("Add Step"),
                    ),
                  ],
                ),
              ),

              /// ACTIONS
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    List<String> steps = stepControllers
                        .map((c) => c.text)
                        .where((text) => text.isNotEmpty)
                        .toList();

                    if (titleController.text.isEmpty || steps.isEmpty) return;

                    final content = steps
                        .asMap()
                        .entries
                        .map((e) => '${e.key + 1}. ${e.value}')
                        .join('\n');

                    try {
                      await ApiService.addHowToNote(
                        title: titleController.text.trim(),
                        content: content,
                      );
                    } catch (_) {}

                    setState(() {
                      items.add(
                          HowItem(title: titleController.text, steps: steps));
                    });

                    Navigator.pop(context);
                  },
                  child: Text("Add"),
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
      //appBar: AppBar(title: Text("How To Do")),
      body: Row(
        children: [
          /// MAIN PAGE
          Expanded(
            child: Column(
              children: [
                /// BUTTON LEFT
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      onPressed: openDialog,
                      icon: Icon(Icons.add),
                      label: Text("How To Do"),
                    ),
                  ),
                ),

                /// TASK LIST
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            "No tasks added yet",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];

                            return AnimatedContainer(
                              duration: Duration(milliseconds: 400),
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// TITLE
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Divider(),

                                  /// STEPS
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List.generate(
                                      item.steps.length,
                                      (i) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        child: Text(
                                          "${i + 1}. ${item.steps[i]}",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          /// NOTE ON RIGHT
          Container(
            width: 160,
            color: Colors.orange[100],
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(Icons.note_alt, size: 40),
                SizedBox(height: 10),
                Text(
                  "NOTE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  "This page helps the caregiver write steps for activities the patient enjoys but may forget.\n\nThe patient can follow these steps anytime.",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HowItem {
  String title;
  List<String> steps;

  HowItem({required this.title, required this.steps});
}
