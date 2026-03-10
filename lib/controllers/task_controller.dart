import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';
import 'auth_controller.dart';

class TaskController extends GetxController {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AuthController _authController = Get.find<AuthController>();

  RxList<TaskModel> tasks = <TaskModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_authController.user, (user) {
      if (user != null) {
        fetchTasks();
        setupRealtimeListener();
      } else {
        tasks.clear();
      }
    });
  }

  void setupRealtimeListener() {
    if (_authController.user.value == null) return;
    
    _database
        .child('tasks')
        .onValue
        .listen((event) {
      tasks.clear();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          // ✅ Only add tasks that belong to current user
          if (value['userId'] == _authController.user.value!.uid) {
            TaskModel task = TaskModel.fromMap({
              'id': key,
              ...value,
            });
            tasks.add(task);
          }
        });
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    });
  }

  Future<void> fetchTasks() async {
    if (_authController.user.value == null) return;
    
    isLoading.value = true;
    try {
      DatabaseEvent event = await _database.child('tasks').once();
      
      tasks.clear();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          // ✅ Only add tasks that belong to current user
          if (value['userId'] == _authController.user.value!.uid) {
            TaskModel task = TaskModel.fromMap({
              'id': key,
              ...value,
            });
            tasks.add(task);
          }
        });
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addTask(String title, String description) async {
    try {
      if (_authController.user.value == null) {
        Get.snackbar('Error', 'Please login first');
        return;
      }

      isLoading.value = true;
      String? userId = _authController.user.value!.uid;
      
      TaskModel newTask = TaskModel(
        id: '', // Will be set by Firebase
        title: title,
        description: description,
        isCompleted: false,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        userId: userId, // Add userId to task
      );

      await _database
          .child('tasks')
          .push()
          .set(newTask.toMap());
      
      Get.snackbar('Success', 'Task added successfully');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTask(String taskId, String title, String description) async {
    try {
      if (_authController.user.value == null) return;

      isLoading.value = true;
      
      Map<String, dynamic> updatedData = {
        'title': title,
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _database
          .child('tasks')
          .child(taskId)
          .update(updatedData);
      
      Get.snackbar('Success', 'Task updated successfully');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      if (_authController.user.value == null) return;

      await _database
          .child('tasks')
          .child(taskId)
          .update({
        'isCompleted': isCompleted,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      if (_authController.user.value == null) return;

      isLoading.value = true;
      
      await _database
          .child('tasks')
          .child(taskId)
          .remove();
      
      Get.snackbar('Success', 'Task deleted successfully');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  List<TaskModel> get completedTasks => 
      tasks.where((task) => task.isCompleted).toList();
  
  List<TaskModel> get pendingTasks => 
      tasks.where((task) => !task.isCompleted).toList();
}
