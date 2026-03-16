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

class NoteCollectionWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_note_collection)

            // "Add" button → opens app with new note URI
            val addPendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("nootpad://new")
            )
            views.setOnClickPendingIntent(R.id.widget_add_btn, addPendingIntent)

            // Header tap → opens app
            val openPendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("nootpad://home")
            )
            views.setOnClickPendingIntent(R.id.widget_header, openPendingIntent)

            // Check if we have notes
            val notesCount = widgetData.getInt("recent_notes_count", 0)

            if (notesCount == 0) {
                views.setViewVisibility(R.id.widget_grid, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_grid, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)

                // Set up RemoteViewsService for grid
                val serviceIntent = Intent(context, NoteCollectionRemoteViewsService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.widget_grid, serviceIntent)

                // Set up click template for grid items
                // Must use FLAG_MUTABLE so fill-in intents can set the URI per item
                val templateIntent = Intent(context, MainActivity::class.java).apply {
                    action = "es.antonborri.home_widget.action.LAUNCH"
                }
                var flags = PendingIntent.FLAG_UPDATE_CURRENT
                if (Build.VERSION.SDK_INT >= 31) {
                    flags = flags or PendingIntent.FLAG_MUTABLE
                }
                val templatePendingIntent = PendingIntent.getActivity(
                    context, 100 + appWidgetId, templateIntent, flags
                )
                views.setPendingIntentTemplate(R.id.widget_grid, templatePendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_grid)
        }
    }
}
