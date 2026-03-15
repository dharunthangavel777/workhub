package com.qwok.talents

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.qwok.talents.R

class DashboardWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_dashboard).apply {
                
                // Get data from SharedPreferences
                val userName = widgetData.getString("userName", "User")
                val jobCount = widgetData.getString("jobCount", "0")
                val freelanceCount = widgetData.getString("freelanceCount", "0")
                val projectTitle = widgetData.getString("projectTitle", "No Active Project")
                val projectProgress = widgetData.getInt("projectProgress", 0)

                // Update Views
                setTextViewText(R.id.user_name, "Hey, $userName!")
                setTextViewText(R.id.job_count, jobCount)
                setTextViewText(R.id.freelance_count, freelanceCount)
                setTextViewText(R.id.project_title, projectTitle)
                setTextViewText(R.id.project_percentage, "$projectProgress%")
                setProgressBar(R.id.project_progress_bar, 100, projectProgress, false)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
