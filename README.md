# Demo: how Bluezone servers can silently collect contact history from any users

Bluezone is a BLE-based contact tracing app sponsored by the Government of
Vietnam and developed by a coalition of local tech companies and the Ministry of
Information and Communications. As of 2020-08-08, more than tens of millions of
users have installed its Android or iOS version.

In a [white paper](https://github.com/BluezoneGlobal/documents/blob/master/Bluezone_White_paper_EN.pdf) published on 2020-05-02, the development team stresses that "the app stores your
data on your own device, not on centralized servers". This claim has also been
widely reported by the Vietnamese media.

In this demo I'll show the claim has no basis in reality, and present
reproducible evidences showing that Bluezone centralized servers have the
capabilities to silently grab all contact history from any users, including
those who have not in contact with any F0, F1, or F2. Because there's no user
confirmation, nobody would be able to tell when or why their data is uploaded
to Bluezone servers (which are currently hosted at `https://apiz.bkav.com`).

## Require tools

* Two Android phones. One is okay if you only want to trigger the `PUSH_HISTORY`
command.

* [Android Studio](https://developer.android.com/studio/releases). Technically
you only need the SDK, but I found that installing Android Studio is the easiest
way to get the SDK.

* [mitmproxy](https://mitmproxy.org/). We need this to observe Bluezone's attempts
to upload data to its servers.

```
brew install mitmproxy
```

* Firebase Admin SDK for Python. This is needed to send push notifications to
Bluezone. The push notifications can contain commands that trigger auto data
uploading.

```
pip install firebase-admin
```

## Configure mitmproxy to intercept traffic from the Android phones

* Start an instance of mitmproxy listening on port 8080:

```
mitm -s mitm.py
```

* On each phone:

- Configure the above instance as a proxy for your WiFi connection

- Visit http://mitm.it to install the mitmproxy's certificate

## How Bluezone servers send commands to client devices

Bluezone servers send commands to client devices using
[Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging).
The list of supported commands are

* `PUSH_HISTORY` (a.k.a `YeuCauGuiLichSu`): when client devices receive this
command, they will silently upload its own Bluezone IDs and all contact history
to the server.

* `CHECK_CONTACT_F0` (a.k.a `KiemTraLichSuTiepXuc`): this command includes
a list of F0 or F1. When client devices receive this command, they will check
whether they were in contact with any of the F0 or F1. If so, they will silently
upload its own Bluezone IDs and all contact history to the server.

* TODO(thaidn): describe other commands.

## Build and install a new APK

The stock Bluezone app is configured to accept commands from a specific
[Firebase account](https://github.com/BluezoneGlobal/bluezone-app/blob/master/android/google-services.json).
We don't have access to that account. In order to trigger the data collection
feature, we must reconfigure the app to accept commands from our own account.

```
./create_apk.sh
```

This script decompiles the [apks](apks) of the official app, overwrites the
Firebase account settings, and builds a new `bluezone.apk`.

Install the apk on each phone

```
adb install bluezone.apk
```

You should remove any existing installation.

## Retrieve Firebase tokens

On each phone:

* Run the app.

* Let each phone scan and confirm that they can "see" each other. Each will record
the other's Bluezone IDs in its local database.

* In the mitmproxy console, you'll see a request to
`https://apibz.bkav.com/api/App/RegisterUser`. The request body contains
something like this

```
{
    "TokenFirebase": "ej9PUqKURR-MGoEf_lTek5:APA91bGUeG-rHC2pz7bwwfPrzT5v0NazlNVHR7pdVT8efCSJH-_fX8SqDAFGMsRNK5Su9h2FexaM7e9hcSqtJ2C8GZuD
XazX0Z6XU2YKfx7haJz8_LYsjyuJjSqETdTIsgIHK2rTXKJo"
}
```

* Copy the string starting with "ej9". This is the Firebase token. You want to
get two tokens, one for each phone.

## Trigger the PUSH_HISTORY command

For each token copied above, run:

```
./notify.py [token]
```

In the mitmproxy console, you'll see two requests to
`https://apibz.bkav.com/api/AppHistoryContact/ReportHistory_ConfirmDeclare`.

[request_upload_history.txt](request_upload_history.txt) contains a request
that I captured during my testing.

The request body contains something like this

```
InfoF:         {"base_id":"66B07D33DA4E16A359B590EDA1E8DC90892D341C86A6491376041FE44505FFB5","time":1596844800,"daily_key":"66B07D33DA4E1
6A359B590EDA1E8DC90892D341C86A6491376041FE44505FFB5","time_start":1596844800}
OTP:           123456
TokenFirebase: ez8SS_xvSfOWnzTTyLYBez:APA91bE64VGz-9TaPvJa7ILfNnojPRniVx7oblsVQnQ95M_MvobSCjYhvLoXX8nue_k0iJA7IbSxyOoL2L5sgETTjH_f9jzZ8kV
MiZ_pFbc0TafEiIiY4VFIRwEEVZLGknV40jdQTu7l
history:       286BCE589AB994EFA5F73CAD?9C25DF2D9861B31897EA3028?-74?1596887252275286BCE589AB994EFA5F73CAD?9C25DF2D9861B31897EA3028?-53?1
596887262301286BCE589AB994EFA5F73CAD?9C25DF2D9861B31897EA3028?-51?1596887272324286BCE589AB994EFA5F73CAD?9C25DF2D9861B31897EA3028?-64?1596
887282356286BCE589AB994EFA5F73CAD?9C25DF2D9861B31897EA3028?-66?1596887302412286BCE589AB994EFA5F73CAD?9C25DF2D9861B31897EA3028?-64?1596887
312446
```

* `InfoF` contains the base ID of the phone. Copy the base ID (i.e., the string
starting with 66B0). You'd need it to trigger the `CHECK_CONTACT_F0` command.
* `OTP` is the one-time password the server requires for this upload. Since
this upload was triggered by a fake push notification sent by us, not real
Bluezone servers, `OTP` is set to a dummy value `123456`. A real notification
by Bluezone servers will include a correct value.
* `TokenFirebase` is the Firebase token of the client device. From this token,
Bluezone servers can figure out the user's phone number, if they entered it during
registration.
* history contains the contact history this client device has recorded.


## Trigger the `CHECK_CONTACT_F0` command

Run:

```
./notify.py [token] [base-id]
```

Where [token] belongs to one phone and [base-id] belongs to the other. In the
mitmproxy console, you'd see another request to `https://apibz.bkav.com/api/AppHistoryContact/ReportHistory_ConfirmContact`.

[request_check_contact_f0.txt](request_check_contact_f0.txt) contains a request
that I captured during my testing.

This concludes the demo.

## Troubleshooting

I've tested this on macOS. If it doesn't work for you, file a ticket or drop
me a line at thaidn@gmail.com.

