package com.sef.nootpad

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.ListView
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.activity_widget_config)

        val listView = findViewById<ListView>(R.id.config_notes_list)
        val emptyView = findViewById<TextView>(R.id.config_empty)

        val prefs = getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
        val notesJsonStr = prefs.getString("all_notes_picker", null)

        if (notesJsonStr == null) {
            listView.visibility = View.GONE
            emptyView.visibility = View.VISIBLE
            return
        }

        val notesArray: JSONArray
        try {
            notesArray = JSONArray(notesJsonStr)
        } catch (e: Exception) {
            listView.visibility = View.GONE
            emptyView.visibility = View.VISIBLE
            return
        }

        if (notesArray.length() == 0) {
            listView.visibility = View.GONE
            emptyView.visibility = View.VISIBLE
            return
        }

        val notes = mutableListOf<JSONObject>()
        for (i in 0 until notesArray.length()) {
            notes.add(notesArray.getJSONObject(i))
        }

        listView.adapter = NotePickerAdapter(notes)
        listView.setOnItemClickListener { _, _, position, _ ->
            selectNote(notes[position])
        }
    }

    private fun selectNote(note: JSONObject) {
        val prefs = getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
        prefs.edit()
            .putString("single_note_$appWidgetId", note.toString())
            .apply()

        // Trigger widget update
        val updateIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            component = android.content.ComponentName(
                this@WidgetConfigActivity,
                SingleNoteWidgetProvider::class.java
            )
        }
        sendBroadcast(updateIntent)

        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultValue)
        finish()
    }

    private inner class NotePickerAdapter(
        private val notes: List<JSONObject>
    ) : BaseAdapter() {

        override fun getCount() = notes.size
        override fun getItem(position: Int) = notes[position]
        override fun getItemId(position: Int) = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView
                ?: layoutInflater.inflate(R.layout.config_note_item, parent, false)

            val note = notes[position]

            view.findViewById<TextView>(R.id.config_note_title).text =
                note.optString("title", "Untitled")
            view.findViewById<TextView>(R.id.config_note_category).text =
                note.optString("category", "General")

            try {
                val colorHex = note.optString("colorHex", "#FFFEF2")
                view.background.setTint(Color.parseColor(colorHex))
            } catch (_: Exception) {
                // ignore
            }

            return view
        }
    }
}
