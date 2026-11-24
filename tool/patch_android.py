"""Dijalankan di CI setelah `flutter create`: nambahin setelan Android yang
dibutuhin Cipher (desugaring buat notifikasi, izin, receiver, backup)."""
import pathlib
import re

app = pathlib.Path('android/app')
manifest = app / 'src/main/AndroidManifest.xml'
m = manifest.read_text()

perms = [
    'android.permission.INTERNET',               # demo DNS lookup di Info Jaringan
    'android.permission.POST_NOTIFICATIONS',     # pengingat harian (Android 13+)
    'android.permission.RECEIVE_BOOT_COMPLETED', # pasang ulang pengingat setelah HP restart
]
for p in perms:
    if p not in m:
        m = m.replace('<application', f'<uses-permission android:name="{p}" />\n    <application', 1)

m = m.replace('android:label="cipher"', 'android:label="Cipher"')
if 'android:allowBackup' not in m:
    m = re.sub(r'<application\b', '<application android:allowBackup="true"', m, count=1)

receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
if 'ScheduledNotificationReceiver' not in m:
    m = m.replace('</application>', receivers + '    </application>', 1)
manifest.write_text(m)

kts = app / 'build.gradle.kts'
groovy = app / 'build.gradle'
if kts.exists():
    g = kts.read_text()
    if 'isCoreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    if 'checkReleaseBuilds' not in g:
        # lint vital Android sempat crash di plugin in_app_purchase; bukan error kode kita
        g = re.sub(r'android\s*\{', 'android {\n    lint {\n        checkReleaseBuilds = false\n        abortOnError = false\n    }', g, count=1)
    kts.write_text(g)
elif groovy.exists():
    g = groovy.read_text()
    if 'coreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        coreLibraryDesugaringEnabled true', g, count=1)
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    if 'checkReleaseBuilds' not in g:
        g = re.sub(r'android\s*\{', 'android {\n    lintOptions {\n        checkReleaseBuilds false\n        abortOnError false\n    }', g, count=1)
    groovy.write_text(g)

root = pathlib.Path('android/build.gradle.kts')
root_groovy = pathlib.Path('android/build.gradle')
snippet_kts = '''
subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }
}
'''
snippet_groovy = '''
subprojects {
    tasks.matching { it.name.startsWith("lintVital") }.configureEach { enabled = false }
}
'''
if root.exists() and 'lintVital' not in root.read_text():
    root.write_text(root.read_text() + snippet_kts)
elif root_groovy.exists() and 'lintVital' not in root_groovy.read_text():
    root_groovy.write_text(root_groovy.read_text() + snippet_groovy)

print(manifest.read_text())
print((kts if kts.exists() else groovy).read_text())
