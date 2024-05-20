package com.sef.chintaultimate.activities;

import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.content.Intent;

import androidx.appcompat.app.AppCompatActivity;

import com.sef.chintaultimate.R;
import com.sef.chintaultimate.activities.CreateNoteActivity;
import com.sef.chintaultimate.database.NotesDatabase;
import com.sef.chintaultimate.entities.Note;

import java.util.List;


public class MainActivity extends AppCompatActivity {



    public static final int REQUEST_CODE_ADD_NOTE = 1;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);



        ImageView imageAddNoteMain = findViewById(R.id.imageAddNoteMain);
        imageAddNoteMain.setOnClickListener(new View.OnClickListener(){

            @Override
            public void onClick(View v) {

                startActivityForResult(
                        new Intent(getApplicationContext(), CreateNoteActivity.class),
                        REQUEST_CODE_ADD_NOTE


                );


            }


        });

        private void getNotes(){

            class GetNotesTask extends AsyncTask<Void, Void, List<Note>>{

                @Override
                protected List<Note> doInBackground(Void... voids) {

                    return NotesDatabase
                            .getDatabase(getApplicationContext())
                            .noteDao().getAllNotes();

                }


                @Override
                protected void onPostExecutive(List<Note> notes){
                    super.onPostExecute(notes);
                }

            }

        }
    }
}