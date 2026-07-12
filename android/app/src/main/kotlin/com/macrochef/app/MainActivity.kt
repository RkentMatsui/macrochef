package com.macrochef.app

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Bridges the Dart [MediaStoreSharedStorage] to Android storage that survives an
 * app uninstall: the public Downloads collection under a "MacroChef" subfolder.
 *
 * API 29+ uses MediaStore (no runtime permission). API 24–28 writes directly to
 * the public Downloads dir and relies on WRITE_EXTERNAL_STORAGE (declared with
 * maxSdkVersion=28 in the manifest).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.macrochef.app/downloads_backup"
    private val subDir = "MacroChef"
    private val permittedRelativePath = "${Environment.DIRECTORY_DOWNLOADS}/$subDir/"
    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingDeleteUri: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "save" -> result.success(
                            saveToDownloads(
                                call.argument<String>("path")!!,
                                call.argument<String>("name")!!,
                            )
                        )
                        "list" -> result.success(
                            listDownloads(call.argument<String>("prefix") ?: "")
                        )
                        "copy" -> {
                            copyToPath(
                                call.argument<String>("id")!!,
                                call.argument<String>("destinationPath")!!,
                            )
                            result.success(null)
                        }
                        "delete" -> deleteDownload(call.argument<String>("id")!!, result)
                        else -> result.notImplemented()
                    }
                } catch (e: BackupAccessRequiredException) {
                    result.error("access_required", e.message, null)
                } catch (e: Exception) {
                    result.error("downloads_backup", e.message, null)
                }
            }
    }

    private fun saveToDownloads(sourcePath: String, name: String): String {
        val source = File(sourcePath)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, "application/x-sqlite3")
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    permittedRelativePath,
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = contentResolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI, values,
            ) ?: throw IllegalStateException("MediaStore insert returned null")
            try {
                contentResolver.openOutputStream(uri)?.use { out ->
                    source.inputStream().use { it.copyTo(out) }
                    out.flush()
                } ?: throw IllegalStateException("openOutputStream returned null")

                val publishValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                }
                if (contentResolver.update(uri, publishValues, null, null) != 1) {
                    throw IllegalStateException("MediaStore publish failed")
                }
                return uri.toString()
            } catch (e: Exception) {
                runCatching { contentResolver.delete(uri, null, null) }
                throw e
            }
        }
        // API 24–28.
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            subDir,
        )
        if (!dir.exists()) dir.mkdirs()
        val dest = File(dir, name)
        source.copyTo(dest, overwrite = true)
        return Uri.fromFile(dest).toString()
    }

    private fun listDownloads(prefix: String): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val projection = arrayOf(
                MediaStore.Downloads._ID,
                MediaStore.Downloads.DISPLAY_NAME,
                MediaStore.Downloads.DATE_ADDED,
                MediaStore.Downloads.SIZE,
                MediaStore.Downloads.RELATIVE_PATH,
                MediaStore.Downloads.OWNER_PACKAGE_NAME,
            )
            val selection =
                "${MediaStore.Downloads.DISPLAY_NAME} LIKE ? AND " +
                    "${MediaStore.Downloads.RELATIVE_PATH} = ?"
            val args = arrayOf("$prefix%", permittedRelativePath)
            val sort = "${MediaStore.Downloads.DATE_ADDED} DESC"
            contentResolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI, projection, selection, args, sort,
            )?.use { c ->
                val idCol = c.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                val nameCol = c.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
                val addedCol = c.getColumnIndexOrThrow(MediaStore.Downloads.DATE_ADDED)
                val sizeCol = c.getColumnIndexOrThrow(MediaStore.Downloads.SIZE)
                val relativePathCol = c.getColumnIndexOrThrow(MediaStore.Downloads.RELATIVE_PATH)
                val ownerCol = c.getColumnIndexOrThrow(MediaStore.Downloads.OWNER_PACKAGE_NAME)
                while (c.moveToNext()) {
                    val uri = Uri.withAppendedPath(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI, c.getLong(idCol).toString(),
                    )
                    out.add(
                        mapOf(
                            "id" to uri.toString(),
                            "name" to c.getString(nameCol),
                            "addedAtMs" to c.getLong(addedCol) * 1000L,
                            "sizeBytes" to if (c.isNull(sizeCol)) null else c.getLong(sizeCol),
                            "relativePath" to c.getString(relativePathCol),
                            "ownedByApp" to (c.getString(ownerCol) == packageName),
                        )
                    )
                }
            }
        } else {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                subDir,
            )
            dir.listFiles()
                ?.filter { it.name.startsWith(prefix) }
                ?.sortedByDescending { it.lastModified() }
                ?.forEach {
                    out.add(
                        mapOf(
                            "id" to Uri.fromFile(it).toString(),
                            "name" to it.name,
                            "addedAtMs" to it.lastModified(),
                            "sizeBytes" to it.length(),
                            "relativePath" to null,
                            "ownedByApp" to true,
                        )
                    )
                }
        }
        return out
    }

    private fun copyToPath(id: String, destinationPath: String) {
        val uri = Uri.parse(id)
        try {
            val input = if (uri.scheme == "file") {
                uri.path?.let { File(it).inputStream() }
            } else {
                contentResolver.openInputStream(uri)
            }
            input?.use { source ->
                File(destinationPath).outputStream().use { output -> source.copyTo(output) }
            } ?: throw IllegalStateException("Backup could not be opened")
        } catch (e: SecurityException) {
            throw BackupAccessRequiredException(e.message ?: "Android access required")
        }
    }

    private fun deleteDownload(id: String, result: MethodChannel.Result) {
        if (pendingDeleteResult != null) {
            result.error("delete_in_progress", "Another delete request is awaiting consent", null)
            return
        }

        val uri = Uri.parse(id)
        if (uri.scheme == "file") {
            val file = uri.path?.let(::File)
            result.success(if (file != null && file.delete()) "deleted" else "not_found")
            return
        }

        try {
            result.success(deleteUri(uri))
        } catch (e: RecoverableSecurityException) {
            if (Build.VERSION.SDK_INT == Build.VERSION_CODES.Q) {
                requestDelete(uri, result, e.userAction.actionIntent.intentSender)
            } else {
                requestDelete(uri, result)
            }
        } catch (e: SecurityException) {
            requestDelete(uri, result)
        }
    }

    private fun deleteUri(uri: Uri): String =
        if (contentResolver.delete(uri, null, null) > 0) "deleted" else "not_found"

    private fun requestDelete(
        uri: Uri,
        result: MethodChannel.Result,
        suppliedSender: android.content.IntentSender? = null,
    ) {
        val sender = suppliedSender ?: if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            MediaStore.createDeleteRequest(contentResolver, listOf(uri)).intentSender
        } else {
            throw IllegalStateException("Recoverable delete action was not supplied")
        }
        pendingDeleteResult = result
        pendingDeleteUri = uri
        try {
            startIntentSenderForResult(sender, DELETE_REQUEST, null, 0, 0, 0)
        } catch (e: Exception) {
            pendingDeleteResult = null
            pendingDeleteUri = null
            throw e
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != DELETE_REQUEST) return

        val result = pendingDeleteResult ?: return
        val uri = pendingDeleteUri
        pendingDeleteResult = null
        pendingDeleteUri = null

        if (resultCode != Activity.RESULT_OK) {
            result.success("declined")
            return
        }
        if (uri == null) {
            result.error("downloads_backup", "Pending delete URI was lost", null)
            return
        }
        try {
            result.success(deleteUri(uri))
        } catch (e: Exception) {
            result.error("downloads_backup", e.message, null)
        }
    }

    private class BackupAccessRequiredException(message: String) : Exception(message)

    companion object {
        private const val DELETE_REQUEST = 9041
    }
}
