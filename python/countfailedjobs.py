#!/usr/bin/python3
# Copyright 2023 Google LLC. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script has been updated in July 2023 - to Support the new
# Authentication changes in version 11.0.5 of Google Cloud Backup & DR
# To use this update the "key_path" location to your service account key file
# update the "target_principal" with your service account id & also
# update the "bmcname" to equal the hostname of your Management Console

#!pip install google-auth

from google.auth import impersonated_credentials
from google.auth.transport.requests import Request
from google.oauth2 import service_account

# Path to your service account JSON key file
key_path = '/path/to/file.json'

# we are disabling SSL warnings, we could add SSL checking to remove need to do this
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Load the service account credentials from the key file
credentials = service_account.Credentials.from_service_account_file(key_path)

# Optional: Impersonate another service account if needed
target_principal = 'python@<YOUR_PROJECT_NAME>.iam.gserviceaccount.com'
target_scopes = ['https://www.googleapis.com/auth/cloud-platform']
credentials = impersonated_credentials.Credentials(
    source_credentials=credentials,
    target_principal=target_principal,
    target_scopes=target_scopes,
    lifetime=3600,
)

# Refresh the token if it has expired
if credentials.expired:
    credentials.refresh(Request())

# Get the access token
access_token = credentials.token

#bmcname = 'bmc-1234-xxxyyyzz-dot-asia-southeast1.backupdr.googleusercontent.com'
bmcname = 'bmc-<YOURPROJECT_ID>-<RANDOM_CHARS>-dot-<REGION_OF_MANAGEMENT_CONSOLE>.backupdr.googleusercontent.com'

import sys
import requests, json
import google.auth.transport.requests
import time

def bmclogin():
    global combinedheader

    request = google.auth.transport.requests.Request()
    token = access_token
#    print(token)

    authheader = {"Authorization": "Bearer " + token}
#    print(authheader)
    url = 'https://' + bmcname +'/actifio/session/'
    payload = ""
    response = requests.request("POST", url, data=payload, headers=authheader, verify=False)
    # test the login process.  If we got less than 400 response code, then we should be ok
    if not response.ok:
        # print(response.text)
        print("Login failed to get session")
        sys.exit(1)
    session = json.loads(response.text)['id']
    combinedheader = { 'Authorization' : 'Bearer ' + token,'backupdr-management-session' : 'Actifio ' + session }

# to get the failed job count
def getjobs():
    onehourago = int((time.time() - 3600) *1000000)
    onedayago = int((time.time() - 86400) *1000000)
    oneweekago = int((time.time() - 604800) *1000000)
    url = 'https://' +bmcname +'/actifio/jobstatus?filter=status:==failed&filter=startdate:>=' + str(oneweekago)
    #url = 'https://' +bmcname +'/actifio/jobstatus&filter=startdate:>=1674962618972000'
    payload = ""
    response = requests.request("GET", url, data=payload, headers=combinedheader, verify=False)
    if not response.ok:
        print(response.text)
        print("Command failed")
        sys.exit(1)
    count = json.loads(response.text)['count']
    #print(response.text)
    print("Failed jobs:" + str(count))

bmclogin()
getjobs()
