#!/usr/bin/env python3

from mitmproxy import http
import json

SUCCESS = {
    "Object": "Register User Success",
    "Status": 0,
    "isError": False,
    "isOk": True
}

# Because the modified apk uses a modified Firebase token, registration with the
# Bluezone server will fail. We configure the mitmproxy to make the registration
# always succeed.
def request(flow: http.HTTPFlow) -> None:
    if flow.request.pretty_url == "https://apibz.bkav.com/api/App/RegisterUser":
        flow.response = http.HTTPResponse.make(
            200,  # (optional) status code
            json.dumps(SUCCESS),  # (optional) content
            {"Content-Type": "application/json"}  # (optional) headers
        )
