import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../models/task_model.dart';

class TaskScreen extends StatelessWidget {
  final TaskModel? task;
  
  TaskScreen({super.key, this.task});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TaskController taskController = Get.find<TaskController>();

  @override
  Widget build(BuildContext context) {
    // Pre-fill form if editing
    if (task != null) {
      titleController.text = task!.title;
      descriptionController.text = task!.description;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const Spacer(),
            Obx(() => ElevatedButton(
              onPressed: taskController.isLoading.value
                  ? null
                  : () {
                      if (titleController.text.trim().isEmpty) {
                        Get.snackbar('Error', 'Please enter a task title');
                        return;
                      }
                      
                      if (task == null) {
                        // Add new task
                        taskController.addTask(
                          titleController.text.trim(),
                          descriptionController.text.trim(),
                        );
                      } else {
                        // Update existing task
                        taskController.updateTask(
                          task!.id,
                          titleController.text.trim(),
                          descriptionController.text.trim(),
                        );
                      }
                      Get.back();
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: taskController.isLoading.value
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(task == null ? 'Add Task' : 'Update Task'),
            )),
          ],
        ),
      ),
    );
  }
}
