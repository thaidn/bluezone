#!/usr/bin/env python3

from __future__ import print_function

import datetime
import firebase_admin
import json
import sys

from firebase_admin import credentials, messaging

cred = credentials.Certificate('service-account.json')
firebase_admin.initialize_app(cred)

def get_contact_history(token):
    message = messaging.Message(
        data={
            'Type': 'YeuCauGuiLichSu',
            'DataContent': '{"OTP":"123456"}'
        },
        token=token,
    )
    response = messaging.send(message)
    print('Successfully sent message:', response)

def check_contact_f0(token, f0):
    if len(f0) != 64:
        print("invalid f0, must in hex format with 64 chars")
        sys.exit(-1)

    info = {
       "data": [
            {
                "daily_key": f0,
                "time_start": 1596844800,
                "time_end":   1600000000,
                "max": 96,
            }
        ]
    }
    data_content = {
       "FindGUID": "123456",
       "InfoF": json.dumps(info),
    }
    message = messaging.Message(
        data={
            'Type': 'KiemTraLichSuTiepXuc',
            'DataContent': json.dumps(data_content)
        },
        token=token,
    )
    response = messaging.send(message)
    print('Successfully sent message:', response)

if __name__ == "__main__":
    if len(sys.argv) == 2:
        get_contact_history(sys.argv[1])
    elif len(sys.argv) == 3:
        check_contact_f0(sys.argv[1], sys.argv[2])
    else:
        print("%s token [f0]" % (sys.argv[0]))
