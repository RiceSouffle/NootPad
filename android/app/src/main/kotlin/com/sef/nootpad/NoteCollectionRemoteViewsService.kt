package com.sef.nootpad

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class NoteCollectionRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NoteCollectionViewsFactory(applicationContext)
    }
}

class NoteCollectionViewsFactory(
    private val context: Context
) : RemoteViewsService.RemoteViewsFactory {

    private var notes = mutableListOf<JSONObject>()

    override fun onCreate() {
        loadNotes()
    }

    override fun onDataSetChanged() {
        loadNotes()
    }

    override fun onDestroy() {
        notes.clear()
    }

    override fun getCount(): Int = notes.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_note_item)

        if (position >= notes.size) return views

        val note = notes[position]
        val title = note.optString("title", "Untitled")
        val preview = note.optString("preview", "")
        val category = note.optString("category", "General")
        val colorHex = note.optString("colorHex", "#FFFEF2")
        val updatedAt = note.optString("updatedAt", "")
        val noteId = note.optString("id", "")

        views.setTextViewText(R.id.note_title, title)
        views.setTextViewText(R.id.note_preview, preview)
        views.setTextViewText(R.id.note_category, category)
        views.setTextViewText(R.id.note_date, updatedAt)

        // Set card background color
        try {
            views.setInt(R.id.note_item_root, "setBackgroundColor", Color.parseColor(colorHex))
        } catch (e: Exception) {
            views.setInt(R.id.note_item_root, "setBackgroundColor", Color.parseColor("#FFFEF2"))
        }

        // Fill-in intent with note URI — merged with template's LAUNCH action
        val fillInIntent = Intent().apply {
            data = Uri.parse("nootpad://note/$noteId")
        }
        views.setOnClickFillInIntent(R.id.note_item_root, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    private fun loadNotes() {
        notes.clear()
        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val jsonString = prefs.getString("recent_notes", null) ?: return
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                notes.add(jsonArray.getJSONObject(i))
            }
        } catch (e: Exception) {
            // Silently fail
        }
    }
}
