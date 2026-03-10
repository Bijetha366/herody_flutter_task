import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Rx<User?> user = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxBool isLoggedIn = false.obs;

  // Local storage
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _initSharedPreferences();
    user.bindStream(_auth.authStateChanges());
    ever(user, (User? user) {
      if (user != null) {
        isLoggedIn.value = true;
        fetchUserData(user.uid);
        _saveUserToLocalStorage(user);
        print('User is authenticated: ${user.email}');
      } else {
        isLoggedIn.value = false;
        userModel.value = null;
        print('User is not authenticated');
        // Don't clear local storage here - let the user decide to logout
      }
    });
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadUserFromLocalStorage();
  }

  Future<void> _saveUserToLocalStorage(User user) async {
    if (_prefs != null) {
      await _prefs!.setString('user_uid', user.uid);
      await _prefs!.setString('user_email', user.email ?? '');
      await _prefs!.setString('user_name', user.displayName ?? '');
    }
  }

  Future<void> _loadUserFromLocalStorage() async {
    if (_prefs != null) {
      String? uid = _prefs!.getString('user_uid');
      String? email = _prefs!.getString('user_email');
      String? name = _prefs!.getString('user_name');
      
      if (uid != null && email != null) {
        // User data exists in local storage
        print('User data found in local storage: $email');
        
        // Check if user is still authenticated in Firebase
        User? currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          print('User is still authenticated in Firebase');
          // User is already authenticated, Firebase will handle the rest
        } else {
          print('User session expired, clearing local storage');
          await _clearUserFromLocalStorage();
        }
      } else {
        print('No user data found in local storage');
      }
    }
  }

  Future<void> _clearUserFromLocalStorage() async {
    if (_prefs != null) {
      await _prefs!.remove('user_uid');
      await _prefs!.remove('user_email');
      await _prefs!.remove('user_name');
      print('User data cleared from local storage');
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      isLoading.value = true;
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ User created in Firebase Auth: ${userCredential.user!.uid}');

      // Save user data to Realtime Database using UserModel
      try {
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now().toIso8601String(),
        );
        
        await _database.child('users').child(userCredential.user!.uid).set(newUser.toMap());
        print('✅ User data saved to Realtime Database');
        
        // Sign out after successful signup
        await _auth.signOut();
        
        Get.snackbar('Success', 'Account created! Please login.', backgroundColor: Colors.green);
        Get.offAll(() => LoginScreen());
        
      } catch (dbError) {
        print('❌ Database error: $dbError');
        Get.snackbar('Error', 'Failed to save user data. Try again.', backgroundColor: Colors.red);
      }
      
    } catch (e) {
      print('❌ Signup error: $e');
      Get.snackbar('Error', 'Signup failed. Try again.', backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar('Success', 'Login successful');
      Get.offAll(() => const HomeScreen());
    } catch (e) {
      String errorMessage = e.toString();
      String userFriendlyMessage = '';
      
      print('Firebase error: $errorMessage'); // Debug line to see actual error
      
      if (errorMessage.contains('user-not-found') || 
          errorMessage.contains('INVALID_EMAIL') ||
          errorMessage.contains('There is no user record corresponding') ||
          errorMessage.contains('firebase_auth/user-not-found')) {
        userFriendlyMessage = 'User not found. Please register first.';
      } else if (errorMessage.contains('wrong-password') || 
                 errorMessage.contains('INVALID_PASSWORD') ||
                 errorMessage.contains('The password is invalid') ||
                 errorMessage.contains('firebase_auth/wrong-password')) {
        userFriendlyMessage = 'Incorrect password. Please try again';
      } else if (errorMessage.contains('invalid-credential') ||
                 errorMessage.contains('firebase_auth/invalid-credential')) {
        // This could mean either wrong password or user not found
        // For better UX, we'll check if the email format is valid
        if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          userFriendlyMessage = 'User not found or incorrect password. Please check your credentials.';
        } else {
          userFriendlyMessage = 'Invalid email format. Please enter a valid email address.';
        }
      } else if (errorMessage.contains('too-many-requests') ||
                 errorMessage.contains('Too many unsuccessful login attempts') ||
                 errorMessage.contains('firebase_auth/too-many-requests')) {
        userFriendlyMessage = 'Too many failed attempts. Please try again later';
      } else if (errorMessage.contains('network-request-failed') ||
                 errorMessage.contains('A network error')) {
        userFriendlyMessage = 'Network error. Please check your internet connection';
      } else if (errorMessage.contains('invalid-email') ||
                 errorMessage.contains('The email address is badly formatted') ||
                 errorMessage.contains('firebase_auth/invalid-email')) {
        userFriendlyMessage = 'Please enter a valid email address';
      } else {
        userFriendlyMessage = 'Login failed. Please try again';
      }
      
      Get.snackbar('Login Failed', userFriendlyMessage, backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      DatabaseEvent event = await _database.child('users').child(uid).once();
      if (event.snapshot.value != null) {
        // ✅ Proper type conversion without casting errors
        Map<String, dynamic> data = {};
        
        if (event.snapshot.value is Map) {
          // Convert dynamic Map to Map<String, dynamic> for UserModel
          Map<dynamic, dynamic> dynamicData = event.snapshot.value as Map<dynamic, dynamic>;
          dynamicData.forEach((key, value) {
            data[key.toString()] = value;
          });
          
          userModel.value = UserModel.fromMap(data);
          
          print('✅ User data loaded successfully: ${data['email']}');
        } else {
          print('⚠️ Expected Map but got different type in fetchUserData');
        }
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.snackbar('Success', 'Logged out successfully');
      
      // Navigate to login screen after logout
      Get.offAll(() => LoginScreen());
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
