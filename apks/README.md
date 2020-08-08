The apks in this folder are pulled from a vanilla installation of Bluezone
2.0.4 for Android.

```
$ adb shell pm path com.mic.bluezone
package:/data/app/com.mic.bluezone-LqAm3n_8jSZS2gSJ6q-x7Q==/base.apk
package:/data/app/com.mic.bluezone-LqAm3n_8jSZS2gSJ6q-x7Q==/split_config.arm64_v8a.apk
package:/data/app/com.mic.bluezone-LqAm3n_8jSZS2gSJ6q-x7Q==/split_config.en.apk
package:/data/app/com.mic.bluezone-LqAm3n_8jSZS2gSJ6q-x7Q==/split_config.vi.apk
package:/data/app/com.mic.bluezone-LqAm3n_8jSZS2gSJ6q-x7Q==/split_config.xxhdpi.apk

$ adb pull /data/app/com.mic.bluezone-LqAm3n_8jSZS2gSJ6q-x7Q==/base.apk
```

You can verify that they're signed by Google, i.e., they aren't tampered with.

```
$ jarsigner -verbose -verify base.apk
```
