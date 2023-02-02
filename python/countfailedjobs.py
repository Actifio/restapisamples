#!/usr/bin/python
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

# script to get BMC version

import sys
import requests, json
import google.oauth2.id_token
import google.auth.transport.requests
import time
import datetime
import os
os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="/path/to/file.json"

# we are disabling SSL warnings, we could add SSL checking to remove need to do this
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# hard coded BMC Name and oath2clientid   We could pass these in to the script
bmcname = 'agm-1234.backupdr.actifiogo.com'
oath2clientid = '5678-abc.apps.googleusercontent.com'

#  token and session ID creation
def bmclogin():
    global combinedheader
    request = google.auth.transport.requests.Request()
    token = google.oauth2.id_token.fetch_id_token(request, oath2clientid)
    #print(token)
   
    # we now load the session ID into a global header to use for all future commands 
    authheader = { 'Authorization' : 'Bearer ' + token }
    #print(authheader)
    url = 'https://' + bmcname +'/actifio/session/'
    payload = ""
    response = requests.request("POST", url, data=payload, headers=authheader, verify=False)
    # test the login process.  If we got less than 400 response code, then we should be ok
    if not response.ok:
        # print(response.text)
        print("Login failed to get session")
        sys.exit(1)
    #else:
    #    print("Login succeeded")
    #grab just the ID, which is our session ID
    session = json.loads(response.text)['id']
    #print(session)
    # we now load the session ID into a global header to use for all future commands 
    combinedheader = { 'Authorization' : 'Bearer ' + token,'backupdr-management-session' : 'Actifio ' + session }
    #print(combinedheader)

# to get the failed job count
def getjobs():
    onehourago =  int((time.time() - 3600) *1000000)
    onedayago =  int((time.time() - 86400) *1000000)
    oneweekago =  int((time.time() - 604800) *1000000)
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
