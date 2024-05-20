package com.sef.chintaultimate.activities;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.media.Image;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;


import com.sef.chintaultimate.R;
import com.sef.chintaultimate.database.NotesDatabase;
import com.sef.chintaultimate.entities.Note;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class CreateNoteActivity extends AppCompatActivity {

    private EditText inputNoteTitle, inputNoteSubtitle, inputNoteText;
    private TextView textDateTime;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_create_note);

        ImageView imageBack = findViewById(R.id.imageBack);

        imageBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onBackPressed();
            }
        });


        inputNoteTitle = findViewById(R.id.inputNoteTitle);

        inputNoteSubtitle = findViewById(R.id.inputNoteSubtitle);

        inputNoteText = findViewById(R.id.inputNote);

        textDateTime = findViewById(R.id.textDateTime);


        textDateTime.setText(

              new SimpleDateFormat("EEEE, dd MMMM yyyy HH:mm a", Locale.getDefault())
                      .format(new Date())


        );

        ImageView imageSave = findViewById(R.id.imageSave);
        imageSave.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                saveNote();
            }
        });

    }

    private void saveNote() {
        if (inputNoteTitle.getText().toString().trim().isEmpty()){
            Toast.makeText(this, "Please put something in la", Toast.LENGTH_LONG).show();
            return;
        }
        else if (inputNoteSubtitle.getText().toString().trim().isEmpty()
            && inputNoteText.getText().toString().trim().isEmpty()) {
        Toast.makeText(this, "Write something will ya!", Toast.LENGTH_SHORT).show();
        return;
        }




        final Note note = new Note();
        note.setTitle(inputNoteTitle.getText().toString());
        note.setSubtitle(inputNoteSubtitle.getText().toString());
        note.setNoteText(inputNoteText.getText().toString());
        note.setDateTime(textDateTime.getText().toString());



        @SuppressLint("StaticFieldLeak")
        class SaveNoteTask extends AsyncTask<Void, Void, Void>{

            @Override
            protected Void doInBackground(Void... voids){
                NotesDatabase.getDatabase(getApplicationContext()).noteDao().insertNote(note);
                return null;
            }

            @Override
            protected void onPostExecute(Void aVoid){
                super.onPostExecute((aVoid));
                Intent intent = new Intent();
                setResult(RESULT_OK, intent);
                finish();
            }



        }





        new SaveNoteTask().execute();
    }





}