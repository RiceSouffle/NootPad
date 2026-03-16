package com.sef.nootpad

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class SingleNoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_single_note)

            val noteJsonStr = widgetData.getString("single_note_$appWidgetId", null)

            if (noteJsonStr != null) {
                try {
                    val noteJson = JSONObject(noteJsonStr)
                    val title = noteJson.optString("title", "Untitled")
                    val category = noteJson.optString("category", "General")
                    val noteId = noteJson.optString("id", "")
                    val plainText = noteJson.optString("plainText", "")
                    val checklistItems = noteJson.optJSONArray("checklistItems")

                    views.setTextViewText(R.id.single_title, title)
                    views.setTextViewText(R.id.single_category, category)

                    if (checklistItems != null && checklistItems.length() > 0) {
                        views.setViewVisibility(R.id.single_checklist, View.VISIBLE)
                        views.setViewVisibility(R.id.single_plain_text, View.GONE)

                        val serviceIntent = Intent(context, SingleNoteRemoteViewsService::class.java).apply {
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                        }
                        views.setRemoteAdapter(R.id.single_checklist, serviceIntent)

                        // Set up click template for checklist items (background toggle)
                        val templateIntent = Intent(context, es.antonborri.home_widget.HomeWidgetBackgroundReceiver::class.java).apply {
                            action = "es.antonborri.home_widget.action.BACKGROUND"
                        }
                        var flags = PendingIntent.FLAG_UPDATE_CURRENT
                        if (Build.VERSION.SDK_INT >= 31) {
                            flags = flags or PendingIntent.FLAG_MUTABLE
                        }
                        val templatePendingIntent = PendingIntent.getBroadcast(
                            context, 200 + appWidgetId, templateIntent, flags
                        )
                        views.setPendingIntentTemplate(R.id.single_checklist, templatePendingIntent)
                    } else {
                        views.setViewVisibility(R.id.single_checklist, View.GONE)
                        views.setViewVisibility(R.id.single_plain_text, View.VISIBLE)
                        views.setTextViewText(R.id.single_plain_text, plainText)
                    }

                    // Open note on tap
                    val openPendingIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("nootpad://note/$noteId")
                    )
                    views.setOnClickPendingIntent(R.id.single_open_btn, openPendingIntent)
                    views.setOnClickPendingIntent(R.id.single_header, openPendingIntent)

                } catch (e: Exception) {
                    views.setTextViewText(R.id.single_title, "Error loading note")
                }
            } else {
                // No note selected — show most recent note as fallback
                val recentJson = widgetData.getString("recent_notes", null)
                if (recentJson != null) {
                    try {
                        val arr = org.json.JSONArray(recentJson)
                        if (arr.length() > 0) {
                            val first = arr.getJSONObject(0)
                            val noteId = first.optString("id", "")
                            views.setTextViewText(R.id.single_title, first.optString("title", "Untitled"))
                            views.setTextViewText(R.id.single_category, first.optString("category", ""))
                            views.setViewVisibility(R.id.single_checklist, View.GONE)
                            views.setViewVisibility(R.id.single_plain_text, View.VISIBLE)
                            views.setTextViewText(R.id.single_plain_text, first.optString("preview", ""))

                            val openPendingIntent = HomeWidgetLaunchIntent.getActivity(
                                context,
                                MainActivity::class.java,
                                Uri.parse("nootpad://note/$noteId")
                            )
                            views.setOnClickPendingIntent(R.id.single_header, openPendingIntent)
                        }
                    } catch (e: Exception) {
                        views.setTextViewText(R.id.single_title, "Add a Noot first!")
                    }
                } else {
                    views.setTextViewText(R.id.single_title, "Add a Noot first!")
                    views.setTextViewText(R.id.single_category, "")
                }

                val openPendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("nootpad://home")
                )
                views.setOnClickPendingIntent(R.id.single_header, openPendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.single_checklist)
        }
    }
}
