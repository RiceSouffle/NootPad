package com.sef.nootpad

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject

class SingleNoteRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        return SingleNoteViewsFactory(applicationContext, appWidgetId)
    }
}

class SingleNoteViewsFactory(
    private val context: Context,
    private val appWidgetId: Int
) : RemoteViewsService.RemoteViewsFactory {

    private var items = mutableListOf<JSONObject>()
    private var noteId = ""

    override fun onCreate() {
        loadItems()
    }

    override fun onDataSetChanged() {
        loadItems()
    }

    override fun onDestroy() {
        items.clear()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_checklist_item)

        if (position >= items.size) return views

        val item = items[position]
        val text = item.optString("text", "")
        val checked = item.optBoolean("checked", false)
        val opIndex = item.optInt("opIndex", -1)

        views.setTextViewText(R.id.checklist_text, text)

        if (checked) {
            views.setImageViewResource(
                R.id.checklist_icon,
                android.R.drawable.checkbox_on_background
            )
            views.setTextColor(R.id.checklist_text, 0xFF9B8568.toInt())
        } else {
            views.setImageViewResource(
                R.id.checklist_icon,
                android.R.drawable.checkbox_off_background
            )
            views.setTextColor(R.id.checklist_text, 0xFF5C4A32.toInt())
        }

        // Fill-in intent for toggling this checklist item via background callback
        // Set on root and children for maximum OEM compatibility
        if (noteId.isNotEmpty() && opIndex >= 0) {
            val fillInIntent = Intent().apply {
                data = Uri.parse("nootpad://toggle/$noteId/$opIndex")
            }
            views.setOnClickFillInIntent(R.id.checklist_item_root, fillInIntent)
            views.setOnClickFillInIntent(R.id.checklist_icon, fillInIntent)
            views.setOnClickFillInIntent(R.id.checklist_text, fillInIntent)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = false

    private fun loadItems() {
        items.clear()
        noteId = ""
        try {
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val jsonString = prefs.getString("single_note_$appWidgetId", null) ?: return
            val noteJson = JSONObject(jsonString)
            noteId = noteJson.optString("id", "")
            val checklistArray = noteJson.optJSONArray("checklistItems") ?: return
            for (i in 0 until checklistArray.length()) {
                items.add(checklistArray.getJSONObject(i))
            }
        } catch (e: Exception) {
            // Silently fail
        }
    }
}
