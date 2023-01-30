#!/usr/bin/python
# script to get BMC version

import sys
import requests, json
import google.oauth2.id_token
import google.auth.transport.requests

# we are disabling SSL warnings, we could add SSL checking to remove need to do this
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# hard coded BMC Name and oath2clientid   NEED TO BE UPDATED TO MATCH YOURS.   SA IS ASSUMED ACTIVATED SO NOT SPECIFIED
bmcname = 'agm-1234.backupdr.actifiogo.com'
oath2clientid = '1234-ABCDEF.apps.googleusercontent.com'

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

# to get the BMC version
def getversion():
    url = 'https://' +bmcname +'/actifio/config/version/'
    payload = ""
    response = requests.request("GET", url, data=payload, headers=combinedheader, verify=False)
    if not response.ok:
        print(response.text)
        print("Command failed")
        sys.exit(1)
    summary = json.loads(response.text)['summary']
    #print(response.text)
    print(summary)

bmclogin()
getversion()
