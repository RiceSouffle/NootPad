package com.sef.chintaultimate.activities;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.content.Intent;

import androidx.appcompat.app.AppCompatActivity;

import com.sef.chintaultimate.R;
import com.sef.chintaultimate.activities.CreateNoteActivity;


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
    }
}