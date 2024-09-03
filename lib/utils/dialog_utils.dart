import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/default_commands.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DialogUtils {
  static void showDefaultCommandsPopup(BuildContext context, Function(String) onCommandSelected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Commands'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: DefaultCommands.commands.length,
              itemBuilder: (context, index) {
                final command = DefaultCommands.commands[index];
                return ListTile(
                  title: Text(command),
                  onTap: () async {
                    // Close the command list dialog
                    Navigator.of(context).pop();
                    onCommandSelected(command);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Future<String?> promptForInput(BuildContext context, String placeholder) {
    final TextEditingController inputController = TextEditingController();
    final FocusNode focusNode = FocusNode();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Enter $placeholder'),
              content: TextField(
                controller: inputController,
                focusNode: focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter $placeholder',
                ),
                onChanged: (value) {
                  // Rebuild the UI to update the state of the OK button
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (inputController.text.trim().isNotEmpty) {
                    Navigator.of(context).pop(inputController.text.trim());
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: inputController.text.trim().isNotEmpty
                      ? () {
                          Navigator.of(context).pop(inputController.text.trim());
                        }
                      : null,
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showClearHistoryDialog(BuildContext context, Function resetHistoryIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Command History'),
          content: const Text('Are you sure you want to clear all command history?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<Model>(context, listen: false).clearCommandHistory();
                resetHistoryIndex(); // Call resetHistoryIndex after clearing history
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  static void showHistoryPopup(BuildContext context, TextEditingController commandController, Function resetHistoryIndex, Function setCursorToEnd) {
    final model = Provider.of<Model>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Command History'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: model.commandHistory.length,
                        itemBuilder: (context, index) {
                          final command = model.commandHistory[index];
                          return ListTile(
                            title: Text(command),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  model.removeCommandFromHistory(index);
                                  commandController.clear();
                                  resetHistoryIndex();
                                });
                              },
                            ),
                            onTap: () {
                              resetHistoryIndex();
                              commandController.text = command;
                              setCursorToEnd();
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showClearHistoryDialog(context, resetHistoryIndex); // Pass resetHistoryIndex as an argument
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
