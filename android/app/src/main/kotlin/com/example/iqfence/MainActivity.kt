package com.iqutta.iqfence

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.widget.Toast
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.DatabaseReference
import com.google.firebase.database.FirebaseDatabase

class MainActivity : FlutterActivity() {
    private lateinit var auth: FirebaseAuth
    private lateinit var database: FirebaseDatabase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        auth = FirebaseAuth.getInstance()
        database = FirebaseDatabase.getInstance()
    }

    private fun registerUser(email: String, password: String, name: String) {
        auth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    val userId = auth.currentUser?.uid
                    if (userId != null) {
                        val usersRef: DatabaseReference = database.getReference("users")
                        usersRef.child(userId).setValue(User(name, email))
                        Toast.makeText(this, "Registrasi berhasil!", Toast.LENGTH_SHORT).show()
                    }
                } else {
                    Toast.makeText(
                        this,
                        "Registrasi gagal: ${task.exception?.message}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
    }
}

data class User(val name: String, val email: String)