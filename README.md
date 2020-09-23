# restapisamples
Rest API integration samples

## Goal

To show some REST API examples.   Each example shows a udsinfo or udstask command and then shows the REST equivalent.   All examples are working examples, tested and confirmed.

### JQ JSON Parser
All examples use the JQ parser.
The JQ JSON parser is portable and easy to use and can parse JSON very nicely
It is open source and free to use
Because some commands use a number of characters that cannot normally be used in HTTPS URLs, you have the choice of using quoting and special handling or URL encoding.

All examples in this article do NOT use URL encoding.

### Variables when issuing info and task commands:

All examples will use variables with curl.   This means the IP address is always shown as $cdsip
In a bash script the login parts  could get assembled like this:
```
#!/bin/bash
# IP is hardset but could be fetched as a parm like this:
# read -p "IP address or name of Actifio Appliance: " cdsip
cdsip=172.24.1.180
# We presume the user has logged in with AD user, else we can prompt for user as well
# read -p "Username to login to Actifio Appliance: " cdsuser
cdsuser=$(whoami)
read -s -p "Password for user $cdsuser on $cdsip: " cdspass
cdskey=727b5563-adf6-4450-9b60-24276194ddb5
```

### Options to handle URLs
If you do not quote your commands when used in a shell, you will need to use backslashes to prevent the '&' symbol being misinterpreted.
So for instance we wouldn't use this command to list backups in the remote-dedup job class.
Note the use of %3D, which is an encoding = sign.
```
curl -s -w "\n" -k https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&filtervalue=jobclass%3Dremote-dedup
```
You would use this (using the backslash before &filtervalue)
Note the use of %3D, which is an encoding = sign.
```
curl -s -w "\n" -k https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid\&filtervalue=jobclass%3Dremote-dedup
```
If we double quote the URL we can avoid the back slashes
Note how we also don't need to encode the = sign
```
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&filtervalue=jobclass=remote-dedup" | jq
```
For example you can see here, we are using no  backslashes or URL encoding at all:
```
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&filtervalue=jobclass=liveclone" | jq -cr '.result[] | [.id, .jobclass, .hostname, .appname]'
["22009825","liveclone","Oracle-Prod","localdb"]
["22026416","liveclone","hq-sql","smalldb"]
["22200952","liveclone","Oracle-Mask-Prd","dmdb"]
["22204385","liveclone","splunk","Splunk"]
["22217107","liveclone","sql-masking-prod","unmasked"]
```
Another example is fetching a session ID.   We can use this command.
Note the URL is double quoted, but contains no backslashes)
```
sessionid=$(curl -w "\n" -s -k -XPOST "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey" | jq -r '.sessionid')
```
There may be other commands that use characters that need to be URL encoded, so we can use a syntax like this:
```
curl -sS -w "\n" -k -G  "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode "filtervalue=jobclass=remote-dedup"  -d "sessionid=$sessionid" | jq
```
What Curl options are used in these examples?
If using Curl we use the following
OptionPurpose
-s
Silent Mode. This stops download progress messages appearing on the screen.
-S
Print errors that might be stopped by -s
-w "\n"
Print a new line at the end of the output
-k
Work with self signed certificates
-G
Send the -d data with a HTTP GET
-d
Used for additional data that we separate out due to encoding requirements
Can I use wget instead of curl?
The examples here all use curl, but you can use wget.  Here are some working examples:
The options used are:
--no-check-certificate   Because the certificate used is self-signed.
-q       Quiet option to stop so many messages getting printed to the screen
-O -   To force output to be printed to the screen  (you need the trailing dash after -O)
Check the cluster is up:
```
wget --no-check-certificate -q -O -  https://172.24.1.180/actifio/api/version| jq
{
  "result": "6.2 (6.2.0.63215)",
  "status": 0
}
```
Get a session ID:
In this example we double quote the URL to avoid the need to use backslashes.  We then push to jq to pull out just the session ID
```
wget --no-check-certificate -q -O - "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey" | jq  '.sessionid'
"a45a601d-701c-4f81-9da8-5f1802d87f6e"
```
We can place the session ID into a variable.  Make sure to use -r to remove the double quotes.
```
sessionid=$(wget --no-check-certificate -q -O - "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey" | jq -r '.sessionid')
```
List all running jobs:
Again we just double quote the URL
```
wget --no-check-certificate -q -O - "https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid" | jq
```
List just running dedup jobs
```
wget --no-check-certificate -q -O - "https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid&filtervalue=jobclass=dedup" | jq -cr '.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress]'
["Job_22297587","dedup","oracle-rac-1","raccldb","","running","30"]
["Job_22297587_00","dedup","oracle-rac-1","raccldb","","running","30"]
["Job_22297587_01","dedup","oracle-rac-1","raccldb","","running","25"]
```
Fetching Appliance version
Normally to get the Appliance version we use this udsinfo command:   udsinfo lsversion
The version command is the only REST command that does not need authentication.   It is a good way to check the Actifio Appliance is accessible.
```
$ curl -s -k  https://172.24.1.180/actifio/api/version
{"result":"6.1 (6.1.8.61044)","status":0}
```
Basic formatting:
```
$ curl -s -k  https://172.24.1.180/actifio/api/version| jq
{
  "result": "6.1 (6.1.8.61044)",
  "status": 0
}
Flat version (using -c option)
$ curl -s -k  https://172.24.1.180/actifio/api/version| jq -c
{"result":"6.1 (6.1.8.61044)","status":0}
To get just the version pull the result section only:
$ curl -s -k  https://172.24.1.180/actifio/api/version| jq '.result'
"6.1 (6.1.8.61044)"
Use -r to remove double quotes:
$ curl -s -k  https://172.24.1.180/actifio/api/version| jq -r '.result'
6.1 (6.1.8.61044)
Fetching Session ID
To get a session ID we do this:
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey"
Normally we get this:
{"status":0,"rights":["Access Application Manager","Access Domain Manager","Access SLA Architect","Access System Monitor","Application Manage","Backup Manage","CLI Usage","Clone Manage","Dedup-Async Manage","Dedup-Async Test","Host Manage","LiveClone Manage","Mount Manage","Restore Manage","SLA Assign","SLA Manage","SLA View","Storage Manage","Storage View","System Manage","System View","WorkFlow Manage","WorkFlow Run","WorkFlow View"],"sessionid":"11778220-8a20-459d-9cd6-a61b11676517"}
We pipe the output to jq
curl -w "\n" -sS -k -XPOST "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey"| jq 
The output is:
[
  {
    "status": 0,
    "rights": [
      "Access Application Manager",
      "Access Domain Manager",
      "Access SLA Architect",
      "Access System Monitor",
      "Application Manage",
      "Backup Manage",
      "CLI Usage",
      "Clone Manage",
      "Dedup-Async Manage",
      "Dedup-Async Test",
      "Host Manage",
      "LiveClone Manage",
      "Mount Manage",
      "Restore Manage",
      "SLA Assign",
      "SLA Manage",
      "SLA View",
      "Storage Manage",
      "Storage View",
      "System Manage",
      "System View",
      "WorkFlow Manage",
      "WorkFlow Run",
      "WorkFlow View"
    ],
    "sessionid": "af42d81f-b6dd-4633-bcc9-7b6db276d0e3"
  }
]
We want just the session ID, so use JQ to parse it out, asking just for the sessionid using:      jq  '.sessionid'
curl -w "\n" -sS -k -XPOST "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey"| jq  '.sessionid'
"fd8c3c03-5f64-4126-a6c8-27e60dfbc44e"
If we want to remove the double quotes, use -r like this:    jq -r  '.sessionid'
curl -w "\n" -sS -k -XPOST "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey"| jq -r  '.sessionid'
24a87504-0791-4af2-87e1-f6cc00f30748
So now we get to this.  We could add error handling, if the output is null, it is because the password didn't work or we couldn't find the device.
Since we pull the sessionid from the output, either we got a session id (success) or we didn't (failure).
sessionid=$(curl -w "\n" -sS -k -XPOST "https://$cdsip/actifio/api/login?name=$cdsuser&password=$cdspass&vendorkey=$cdskey"| jq -r '.sessionid')
if
[ -n "$sessionid" ] && [ "$sessionid' != "null" ]
then
echo "Login for user $cdsuser to $cdsip succeeded"
else
echo "Login for user $cdsuser to $cdsip failed"
fi
Listing jobs - example commands:
The udsinfo command to list running jobs is:
udsinfo lsjob
To list all running jobs:
curl -sS -w "\n" -k https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid
To list all jobs and format in a nice way:
$ curl -sS -w "\n" -k https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid| jq -cr  '["Jobname", "Jobclass", "HostName"], "AppName"], "TargetHost", "Status", "Progress"]],(.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress])'
["gc_22179120","gc","","","","running","37"]
["gc_22179120_000E","gc","","","","running","37"]
["Job_22179498","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179498_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179506","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179510","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179506_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
To list all jobs and put in CSV format:
$ curl -sS -w "\n" -k https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid| jq -cr '.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress] | @csv'
"gc_22179120","gc","","","","running","37"
"gc_22179120_000E","gc","","","","running","37"
"Job_22179498","remote-dedup","demo-sql-6","C:\","","running","78"
"Job_22179502","remote-dedup","demo-sql-6","C:\","","running","78"
"Job_22179498_00","remote-dedup","demo-sql-6","C:\","","running","78"
To list all jobs and put in a nice format with header:
$ curl -sS -w "\n" -k https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid| jq -cr  '["Jobname", "Jobclass", "HostName", "AppName", "TargetHost", "Status", "Progress"], (.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress])'
["Jobname","Jobclass","HostName","AppName","TargetHost","Status","Progress"]
["gc_22179120","gc","","","","running","37"]
["gc_22179120_000E","gc","","","","running","37"]
["Job_22179498","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179498_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179506","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179510","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179506_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
To list just remote-dedup jobs using filter value.   We need to turn this command into REST:
udsinfo lsjob -filtervalue jobclass=remote-dedup
$ curl -sS -w "\n" -k "https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid&filtervalue=jobclass=remote-dedup"| jq -cr '.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress]'
["Job_22179498","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179498_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179506","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502_00","remote-dedup","demo-sql-6","C:\\","","running","78"]
If we want just remote-dedups and no subjobs: we need to add another filter value of parentid=0.
We need to turn this command into REST.   Note because we connect the two filter values with an '&' we need to either escape it with a back slash or double quote the command:
udsinfo lsjob -filtervalue "jobclass=remote-dedup&parentid=0"
or
udsinfo lsjob -filtervalue jobclass=remote-dedup\&parentid=0
However since we are actually using two filter values of jobclass=remote-dedup and parentid=0  in REST this means I have two choices.
The first is to URL encode the middle '&' into a %26.
$ curl -sS -w "\n" -k https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid\&filtervalue=jobclass=remote-dedup%26parentid=0| jq -cr '.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress]'
["Job_22179498","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179502","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179506","remote-dedup","demo-sql-6","C:\\","","running","78"]
["Job_22179510","remote-dedup","demo-sql-6","C:\\","","running","78"]
To avoid doing this, we need to use different syntax like this.   This splits the session ID out and allows us to avoid URL encoding in the filter value.
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsjob" --data-urlencode "filtervalue=jobclass=remote-dedup&parentid=0"-d "sessionid=$sessionid"| jq -cr '.result[] | [.jobname, .jobclass, .hostname, .appname, .targethost, .status, .progress]'
To check just one job:
curl -sS -w "\n" -k "https://$cdsip/actifio/api/info/lsjob?sessionid=$sessionid&argument=Job_22179743"|jq 
{
  "result": {
    "progress": "9",
    "virtualsize": "100",
    "queuedate": "2015-11-27 00:08:12.328",
    "currentstep": "0",
    "jobname": "Job_22179743",
    "expirationdate": "2015-12-04 00:08:12.327",
    "appid": "21681349",
    "parentid": "0",
    "policyname": "Daily Dedup",
    "originaljobclass": "dedup",
    "id": "22179743",
    "jobcount": "2",
    "priority": "high",
    "changerequest": "IGNORE",
    "isscheduled": "true",
    "jobclass": "dedup",
    "flags": "0",
    "relativesize": "100",
    "status": "running",
    "hostname": "oracle-rac-1",
    "pid": "23720",
    "consistencydate": "2015-11-27 00:05:56.000",
    "startdate": "2015-11-27 00:08:12.328",
    "retrycount": "0",
    "sltname": "Gold-LogSmart",
    "totalsteps": "0",
    "sourcecluster": "590021596788",
    "appname": "racbigdb",
    "sourceid": "Image_22179670,Image_22174655",
    "errorcode": "0"
  },
  "status": 0
}
Filtering on dates
Lets say we want to restrict a list of images to a specific data range
We can use a command like this to look at snapshots for appid 3434456 that have a consistency date equal to or greater than 2018-09-19
udsinfo lsbackup -filtervalue 'appid=3434456&jobclass=snapshot&consistencydate>=2018-09-19'
The easiest way to do this in restful API is like this:
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode "filtervalue=appid=3434456&jobclass=snapshot&consistencydate>=2018-09-19" -d "sessionid=$sessionid" | jq

Mounting and unmounting Images - Example 1: Mount most recent snap
Lets mount the most recent snapshot from application ID 20837997 to a host called demo-oracle-4
udstask mountimage -appid 20837997 -host demo-oracle-4
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/mountimage?appid=20837997&host=demo-oracle-4&sessionid=$sessionid"| jq
{
  "result": "Job_22189131 to mount Image_22187857 completed",
  "status": 0
}
Lets find that image:
udsinfo lsbackup -filtervalue jobclass=mount\&appid=20837997
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode"filtervalue=jobclass=mount&appid=20837997" -d "sessionid=$sessionid"| jq 
{
  "result": [
    {
      "virtualsize": "1857028096000",
      "originalbackupid": "22187858",
      "appid": "20837997",
      "policyname": "12hr Snap",
      "id": "22189218",
      "mountedhost": "20929573",
      "username": "Scheduler",
      "sourceimage": "",
      "prepdate": "",
      "apptype": "Oracle",
      "componenttype": "0",
      "jobclass": "mount",
      "modifydate": "2015-11-29 21:17:08.940",
      "flags": "2132",
      "sensitivity": "0",
      "status": "succeeded",
      "expiration": "2100-01-01 00:00:00.000",
      "sourceuds": "590021596788",
      "hostname": "Oracle-Prod",
      "label": "",
      "consistencydate": "2015-11-29 10:22:45.000",
      "uniquehostname": "501d852d-4fc7-477c-a7e1-6b92ac4e4f6e",
      "backupdate": "2015-11-29 21:16:19.000",
      "backupname": "Image_22189211",
      "sltname": "Gold",
      "slpname": "Local Profile"
      "appname": "bigdb"
    }
  ],
  "status": 0
}
We know the host name, but need the host ID, to get mountedhostid for next command:
udsinfo lshost -filtervalue hostname=demo-oracle-4
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lshost?sessionid=$sessionid&filtervalue=hostname=demo-oracle-4" | jq -rc '.result[] | [.id, .hostname]'
["20929573","demo-oracle-4"]
Now we know mounted  host ID, we can learn backup name
udsinfo lsbackup -filtervalue jobclass=mount\&mountedhost=20929573
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode"filtervalue=jobclass=mount&mountedhost=20929573" -d sessionid=$sessionid| jq -rc '.result[] | [.id, .backupname, .label]'
["22189218","Image_22189211",""]
(see how the Job_xxxx  number to create can be used to find the image, which is usually Image_xxxx)
udstask unmountimage -image Image_22188094 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22189211&delete" | jq
{
  "result": "Job_22189234 to unmount Image_22189211 completed",
  "status": 0
}
If we try and remove the same image, it fails, which is should:
udstask unmountimage -image Image_22188094 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22189211&delete"​| jq
{
  "errormessage": "image does not exist: Image_22189211",
  "errorcode": 10016
}
We can just request the error message:
udstask unmountimage -image Image_22188094 -delete
curl -s -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22189211&delete"| jq '.errormessage'
"image does not exist: Image_22189211"
Also with raw, to remove the quotes from the JSON:
udstask unmountimage -image Image_22188094 -delete
curl -s -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22189211&delete" | jq -r '.errormessage'
image does not exist: Image_22189211
Mounting and unmounting Images - Example 2:  Mount using Drive Letters
Lets find the most recent snapshot from application ID 20990406
udsinfo lsbackup -filtervalue jobclass=snapshot\&appid=20990406
Lets learn just the ID and consistency date.
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode "filtervalue=jobclass=snapshot&appid=20990406" -d "sessionid=$sessionid"| jq -c '.result [] | [.id, .consistencydate]'
["22181177","2015-11-27 07:04:15.000"]
["22182135","2015-11-27 19:04:21.000"]
["22183338","2015-11-28 07:04:23.000"]
["22185180","2015-11-28 19:04:34.000"]
["22187622","2015-11-29 07:04:39.000"]
["22188468","2015-11-29 19:04:44.000"]
Lets learn more about one image:      udsinfo lsbackup -filtervalue id=22185180
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode"filtervalue=id=22185180" -d "sessionid=$sessionid"| jq '.result'
[
  {
    "virtualsize": "51531218944",
    "originalbackupid": "0",
    "appid": "20990406",
    "policyname": "12hr Snap",
    "id": "22185180",
    "mountedhost": "0",
    "username": "Scheduler",
    "sourceimage": "",
    "prepdate": "",
    "apptype": "SqlServerWriter",
    "componenttype": "0",
    "jobclass": "snapshot",
    "modifydate": "2015-11-29 07:05:09.148",
    "flags": "84",
    "sensitivity": "1",
    "status": "succeeded",
    "expiration": "2015-12-01 19:04:58.526",
    "sourceuds": "590021596788",
    "hostname": "sql-masking-prod",
    "label": "",
    "consistencydate": "2015-11-28 19:04:34.000",
    "uniquehostname": "502c6730-6c16-eafb-bd6e-ba8dcc57317b",
    "backupdate": "2015-11-28 19:02:38.000",
    "backupname": "Image_22185179",
    "sltname": "Gold",
    "slpname": "Local Profile",
    "appname": "unmasked"
  }
]
Without the filter value we get much more detail.  Note for restful we need to use 'argument=xxxxx'
udsinfo lsbackup 22185180
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&argument=22185180"| jq '.result'
{
  "  nvolumes": "2",
  "appclass": "SQLServer",
  "virtualsize": "51531218944",
  "restorelock": "0",
  "originalbackupid": "0",
  "    volumekey": [
    "0",
    "0"
  ],
  "    capacity": [
    "25765609472",
    "25765609472"
  ],
  "backuplock": "0",
  "appid": "20990406",
  "policyname": "12hr Snap",
  "originatinguds": "590021596788",
  "    logicalname": [
    "L:\\",
    "S:\\"
  ],
  "id": "22185180",
  "    uniqueid": [
    "dasvol:L:\\",
    "dasvol:S:\\"
  ],
  "mountedhost": "0",
  "consistency-mode": "crash-consistent",
  "username": "Scheduler",
  "transport": "SAN based, out-of-band storage",
  "    isbootvmdk": [
    "false",
    "false"
  ],
  "    sourcemountpoint": [
    "L:\\",
    "S:\\"
  ],
  "apptype": "SqlServerWriter",
  "mappedhost": "0",
  "modifiedbytes": "0",
  "componenttype": "0",
  "modifydate": "2015-11-29 07:05:09.148",
  "jobclass": "snapshot",
  "flags": "84",
  "    volumeUID": [
    "638A95F225801C59D00000000004736C",
    "638A95F225801C59D00000000004736D"
  ],
  "sourceuds": "590021596788",
  "sensitivity": "1",
  "expiration": "2015-12-01 19:04:58.526",
  "status": "succeeded",
  "expirytries": "0",
  "hostname": "sql-masking-prod",
  "consistencydate": "2015-11-28 19:04:34.000",
  "depth": "0",
  "backuphost": "sql-masking-prod.SA.actifio.com",
  "readyvm": "false",
  "backupdate": "2015-11-28 19:02:38.000",
  "uniquehostname": "502c6730-6c16-eafb-bd6e-ba8dcc57317b",
  "backupname": "Image_22185179",
  "    target": [
    "vdisk:fc-565A410F1600",
    "vdisk:fc-565A410F1601"
  ],
  "sltname": "Gold",
  "targetuds": "590021596788",
  "slpname": "Local Profile",
  "appname": "unmasked",
  "characteristic": "PRIMARY",
  "    restorableobject": [
    "unmasked",
    "unmasked"
  ]
}
So now lets mount this image to a Windows host without doing anything clever
udstask mountimage -image 22185180 -host demo-sql-4
curl -s -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/mountimage?image=22185180&host=demo-sql-4&sessionid=$sessionid"| jq
{
  "result": "Job_22190405 to mount Image_22185179 completed",
  "status": 0
}
The assigned drives are Y: and Z:
Lets instead specify which drive letter should be used for source drive.
We have two drives in the source volume:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&argument=22185180"| jq '.result | ."    uniqueid"'
[
  "dasvol:L:\\",
  "dasvol:S:\\"
]
The udsinfo command to mount L:\ to M:\ and S:\ to N:\ is as follows.
Note this example uses single quotes to hide the backslashes from the shell, meaning we don't need to double backslash our drive letters (i.e  S:\\=N:\\)
udstask mountimage -image 22330658-host demo-sql-4 -restoreoption 'mountdriveperdisk-dasvol:L:\=M:\,mountdriveperdisk-dasvol:S:\=N:\'
Due to some quirk in the URL encoding, we need to encase the restore option in single quotes as well (rather than double quotes, which most of these examples use).
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22330658&host=demo-sql-4&sessionid=$sessionid" --data-urlencode 'restoreoption=mountdriveperdisk-dasvol:L:\=P:\,mountdriveperdisk-dasvol:S:\=N:\'
{"result":"Job_22334168 to mount Image_22330657 completed","status":0}
End result:
Now it is time to unmount
udstask unmountimage -image Image_22333318 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22333318&delete" | jq
{
  "result": "Job_22333339 to unmount Image_22333318 completed",
  "status": 0
}
Mounting and unmounting Images - Example 3:  Mount using Mount points
We might want to mount using mount points rather than drive letters.
Taking the same image and host from Example 2, this is the udsinfo command.
We take the L:\ and mount it to C:\Test\Data  and we take the S:\ and we mount it to C:\Test\Logs
udstask mountimage -image 22185180 -host demo-sql-4 -restoreoption'mountpointperdisk-dasvol:L:\=C:\Test\Data,mountpointperdisk-dasvol:S:\=C:\Test\Logs'
Which gives us this command:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22330658&host=demo-sql-4&sessionid=$sessionid" --data-urlencode "restoreoption=mountpointperdisk-dasvol:L:\=C:\Test\Data,mountpointperdisk-dasvol:S:\=C:\Test\Logs"
{"result":"Job_22333318 to mount Image_22330657 completed","status":0}
Which gives us this:
Now it is time to unmount
udstask unmountimage -image Image_22333318 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22333318&delete" | jq
{
  "result": "Job_22333339 to unmount Image_22333318 completed",
  "status": 0
}
How do we get restore options listed?
1)  List all my app classes:     udsinfo lsappclass
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsappclass?sessionid=$sessionid" | jq -c '.result [] | [.name]'
["OracleGroup"]
["SQLServerGroup"]
["Oracle"]
["SQLServer"]
2) List all restore options per app class using a target host ID:    udsinfo lsrestoreoptions -applicationtype SQLServer -action mount -targethost 20933867
In the example above, you will need to change the target host to match your own.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsrestoreoptions?applicationtype=SQLServer&action=mount&targethost=20933867&sessionid=$sessionid" | jq -c '.result [] | [.name]'
["restoremacaddr"]
["mountdriveperdisk"]
["mountpointperimage"]
["slpid"]
["sltid"]
["mountpointperdisk"]
["reprotect"]
["mountdriveperimage"]
["mapdiskstoallclusternodes"]
["provisioningoptions"]
Mounting and unmounting Images - Example 4:  Linux mount using Mount points
Single mount point per image
Lets say we have a Linux file system backup.
We have identified a snapshot image of an application called /home and a target host to mount it to.
We want to ensure it mounts to /mnt/jsontest.
udstask mountimage -image 22311818 -host demo-oracle-4 -restoreoption "mountpointperdisk-dasvol:/home=/mnt/jsontest"
Which gives us this command:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22311818&host=demo-oracle-4&sessionid=$sessionid" --data-urlencode "restoreoption=mountpointperdisk-dasvol:/home=/mnt/jsontest"
On our Linux Target host we see:
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/vg_demooracle1-lv_root
                       35G   15G   19G  46% /
tmpfs                 4.9G  311M  4.6G   7% /dev/shm
/dev/sda1             477M   68M  385M  15% /boot
/dev/act_home_1449822759500_1449805206188/act_staging_vol
                       54G  911M   51G   2% /mnt/jsontest
Multiple mount points per image
Lets say we have an Oracle backup that has a log disk and a database disk.     We learn what the mount points are called:
# udsinfo lsbackup 22349758 | grep dasvol
    uniqueid dasvol:smalldb
    uniqueid dasvol:smalldb_archivelog
Which gives us this command:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&argument=22349758"| jq '.result | ."    uniqueid"'
[
  "dasvol:smalldb",
  "dasvol:smalldb_archivelog"
]
We want to mount the database as /mnt/database and /mnt/logs so we user this command:
udstask mountimage -image 22349758 -host demo-oracle-4 -restoreoption "mountpointperdisk-dasvol:smalldb=/mnt/database,mountpointperdisk-dasvol:smalldb_archivelog=/mnt/logs"
Which gives us this command:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22349758&host=demo-oracle-4&sessionid=$sessionid" --data-urlencode "restoreoption=mountpointperdisk-dasvol:smalldb=/mnt/database,mountpointperdisk-dasvol:smalldb_archivelog=/mnt/logs"
On the host we then see:
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/vg_demooracle1-lv_root
                       35G   15G   19G  46% /
tmpfs                 4.9G  311M  4.6G   7% /dev/shm
/dev/sda1             477M   68M  385M  15% /boot
/dev/sdb               50G  1.6G   46G   4% /mnt/database
/dev/sdc               50G   71M   47G   1% /mnt/logs
Mounting and unmounting Images - Example 5:  SQL App Aware mount
We may want to use App Aware mount to bring our MS SQL database online.
To do this we take everything we learn in example 3 and add provisioning options to define the app aware mount.
Here is an example for udsinfo
We have an application called localdb which is application ID 21090610.
We list the snaps:
udsinfo lsbackup -filtervalue jobclass=snapshot\&appid=21090610
Lets learn just the ID and consistency date.
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode "filtervalue=jobclass=snapshot&appid=21090610" -d "sessionid=$sessionid" | jq -c '.result [] | [.id, .consistencydate]'
["22308340","2015-12-08 17:22:00.000"]
["22315337","2015-12-09 05:21:59.000"]
["22321893","2015-12-09 17:22:10.000"]
["22326287","2015-12-10 05:22:16.000"]
We have chosen to use 22196359.
App Aware SQL mount to mount point
We want to mount this to C:\Test\jsontest so we need to learn the current drive letter.
udsinfo lsbackup 22196359
Notice the long space in the name of the variable, this is as per the source.
curl -sS -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&argument=22196359"| jq '.result | ."    uniqueid"'
"dasvol:S:\\"
The big change is we add provisioning options.   There is an appaware flag but we don't need to use it, since we are using the provisioning options.
udstask mountimage -image 22196359-host demo-sql-4 -restoreoption 'mountpointperdisk-dasvol:S:\=C:\Test\jsontest,provisioningoptions=<provisioning-options><sqlinstance>DEMO-SQL-4</sqlinstance><dbname>jsontest</dbname><recover>true</recover></provisioning-options>'
We put this into a REST command without any URL encoding (leave that to curl):
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=Image_22196358&host=demo-sql-4&sessionid=$sessionid" --data-urlencode "restoreoption=mountpointperdisk-dasvol:S:\=C:\Test\jsontest,provisioningoptions=<provisioning-options><sqlinstance>DEMO-SQL-4</sqlinstance><dbname>jsontest</dbname><recover>true</recover></provisioning-options>" | jq
{
  "result": "Job_22201771 to mount Image_22196358 completed",
  "status": 0
}
And more importantly in SQL Server we see:
Now it is time to unmount
udstask unmountimage -image Image_22201771 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22201771&delete" | jq
{
  "result": "Job_22333339 to unmount Image_22333318 completed",
  "status": 0
}
App Aware SQL mount to drive letter
We have two drives in the source volume:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&argument=22330658" | jq '.result | ."    uniqueid"'
[
  "dasvol:L:\\",
  "dasvol:S:\\"
]
We take the syntax from example 2, but step it up by also doing an App Aware mount of the DB as 'JSONTEST'
We encase the restore options in single quotes due to the number of backslashes.
udstask mountimage -image 22330658-host demo-sql-4 -restoreoption 'mountdriveperdiskddasvol:L:\=M:\,mountdriveperdiskddasvol:S:\=N:\,provisioningoptions=<provisioning-options><sqlinstance>DEMO-SQL-4</sqlinstance><dbname>jsontest</dbname><recover>true</recover></provisioning-options>'
Due to some quirk in the URL encoding, we need to encase the restore option in single quotes as well (rather than double quotes, which most of these examples use).
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22330658&host=demo-sql-4&sessionid=$sessionid" --data-urlencode 'restoreoption=mountdriveperdiskddasvol:L:\=P:\,mountdriveperdiskddasvol:S:\=N:\,provisioningoptions=<provisioning-options><sqlinstance>DEMO-SQL-4</sqlinstance><dbname>jsontest</dbname><recover>true</recover></provisioning-options>'
{"result":"Job_22334207 to mount Image_22330657 completed","status":0}
Now it is time to unmount
udstask unmountimage -image Image_22333318 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22334207&delete" | jq
{
  "result": "Job_22333339 to unmount Image_22333318 completed",
  "status": 0
}
How do we get restore options listed?
1)  List all my app classes:     udsinfo lsappclass
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsappclass?sessionid=$sessionid" | jq -c '.result [] | [.name]'
["OracleGroup"]
["SQLServerGroup"]
["Oracle"]
["SQLServer"]
2) List all restore options per app class using a target host ID:    udsinfo lsrestoreoptions -applicationtype SQLServer -action mount -targethost 20933867
In the example above, you will need to change the target host to match your own.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsrestoreoptions?applicationtype=SQLServer&action=mount&targethost=20933867&sessionid=$sessionid" | jq -c '.result [] | [.name]'
["restoremacaddr"]
["mountdriveperdisk"]
["mountpointperimage"]
["slpid"]
["sltid"]
["mountpointperdisk"]
["reprotect"]
["mountdriveperimage"]
["mapdiskstoallclusternodes"]
["provisioningoptions"]
How do we get provisioning options listed?  (note this only works in 7.0 code and higher)
1)  List all my app classes:     udsinfo lsappclass
2)  List all provisioning options per app class:    udsinfo lsappclass -name SQLServer
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsappclass?name=SQLServer&sessionid=$sessionid" | jq -c '.result [] | [.name]'
Mounting and unmounting Images - Example 6:  SQL App Aware mount of a Consistency Group
We may want to use App Aware mount of  MS SQL Consistency Group.
This is a group of databases captured at a consistent point in time from a single source host.
First we learn the Consistency Group ID.
udsinfo lsconsistgrp
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsconsistgrp?sessionid=$sessionid" | jq -c '.result [] | [.id, .groupname]'
["22346859","DemoSQL4"]
If we know the name of the consistency group we could also just look up that group:
udsinfo lsconsistgrp DemoSQL4
curl -sS -w "\n" -k "https://$cdsip/actifio/api/info/lsconsistgrp?argument=DemoSQL4&sessionid=$sessionid" | jq -cr '.result | [.id,.groupname]'
["22346859","DemoSQL4"]
We list the snaps using the group ID as the application ID:
udsinfo lsbackup -filtervalue jobclass=snapshot\&appid=22346859
Lets learn just the ID and consistency date.
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode "filtervalue=jobclass=snapshot&appid=22346859" -d "sessionid=$sessionid" | jq -c '.result [] | [.id, .consistencydate]'
["22346908","2015-12-11 12:19:10.000"]
So now we want to mount image  22346908
We want to mount our CG to C:\Test\jsontest so we need to learn the current drive letter.
udsinfo lsbackup  22346908
Notice the long space in the name of the variable, this is as per the source field.
curl -sS -w "\n" -k "https://$cdsip/actifio/api/info/lsbackup?sessionid=$sessionid&argument=22346908" | jq '.result | ."    uniqueid"'
"dasvol:C:\\"
The big change is we add provisioning options.   There is an appaware flag but we don't need to use it, since we are using the provisioning options.
We cannot choose names for the DBs because they are in a group, so instead we use a prefix.  In this example it is jsontest
udstask mountimage -image 22346908-host demo-sql-4 -restoreoption 'mountpointperdisk-dasvol:C:\=C:\Test\jsontest,provisioningoptions=<provisioning-options><ConsistencyGroupName>testme</ConsistencyGroupName><sqlinstance>DEMO-SQL-4</sqlinstance><dbnameprefix>jsontest</dbnameprefix><recover>true</recover><username></username></provisioning-options>'
We put this into a REST command without any URL encoding (leave that to curl).  Note in this example we use single quotes around the data that needs encoding.
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22346908&host=demo-sql-4&sessionid=$sessionid" --data-urlencode 'restoreoption=mountpointperdisk-dasvol:C:\=C:\Test\jsontest,provisioningoptions=<provisioning-options><ConsistencyGroupName>testme</ConsistencyGroupName><sqlinstance>DEMO-SQL-4</sqlinstance><dbnameprefix>jsontest</dbnameprefix><recover>true</recover><username></username></provisioning-options>' | jq
{
  "result": "Job_22347408 to mount Image_22346905 completed",
  "status": 0
}
We get this result.   You can see the mount point and three DBs with jsontest added to their names as a prefix.
Now it is time to unmount
udstask unmountimage -image Image_22347408 -delete
curl -sS -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/unmountimage?sessionid=$sessionid&image=Image_22347408&delete" | jq
{
  "result": "Job_22333339 to unmount Image_22333318 completed",
  "status": 0
}
Mounting and unmounting Images - Example 7:  Oracle App Aware mount
We may want to use App Aware mount to bring our Oracle database online.
To do this we take everything we learn in example 4 and add provisioning options to define the Oracle app aware mount.
Here is an example for udsinfo
We have an application called localdb which is application ID 20837997.
We list the snaps:
udsinfo lsbackup -filtervalue jobclass=snapshot\&appid=20837997
Lets learn appid, hostname, app name , backup ID and  consistency date.
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" -d "sessionid=$sessionid" --data-urlencode "filtervalue=jobclass=snapshot&appid=20837997"  | jq -c '.result [] | [.appid, .hostname, .appname, .id, .consistencydate]'
["20837997","Oracle-Prod","bigdb","22278630","2015-12-08 02:24:20.000"]
["20837997","Oracle-Prod","bigdb","22307252","2015-12-08 14:25:34.000"]
["20837997","Oracle-Prod","bigdb","22313415","2015-12-09 02:24:33.000"]
["20837997","Oracle-Prod","bigdb","22320393","2015-12-09 14:24:49.000"]
["20837997","Oracle-Prod","bigdb","22325106","2015-12-10 02:25:06.000"]
["20837997","Oracle-Prod","bigdb","22331636","2015-12-10 14:25:08.000"]
We have chosen to use 22187858.
We are going to let the system choose where to mount the DB to.
The big change is we add provisioning options.   There is an appaware flag but we don't need to use it, since we are using the provisioning options.
These are some provisioning options we can set.   To learn how to find more, the commands are listed at the bottom of this example.
<provisioning-options>
<databasesid>jsontest</databasesid>
<username>oracle</username>
<orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome>
<tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir>
<totalmemory></totalmemory>
<sgapct></sgapct>
<tnsip></tnsip>
<tnsport></tnsport>
<tnsdomain></tnsdomain>
<rrecovery>true</rrecovery>
<standalone>false</standalone>
<envvar></envvar>
</provisioning-options>
Here is our udsinfo command.  Note we encase our provisioning options inside single quotes so they don't have escape issues with all the characters in there.
udstask mountimage -image 22187858-host demo-oracle-4 -restoreoption 'provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>'
So we turn this into REST, again letting curl do the URL encoding:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=22187858&host=demo-oracle-4&sessionid=$sessionid" --data-urlencode "restoreoption=provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>"
We run the command and get a successful job:
{"result":"Job_22202340 to mount Image_22187857 completed","status":0}
Having run the command we can now login to my Oracle server and validate.  Note the job number is in the mount:
[oracle@demo-oracle-4 ~]$ df
Filesystem            1K-blocks       Used Available Use% Mounted on
/dev/mapper/vg_demooracle1-lv_root
                       36580952   14701812  20014232  43% /
tmpfs                   5065472    1550168   3515304  31% /dev/shm
/dev/sda1                487652      68810    393242  15% /boot
/dev/actbigdb_1448949440094_1448931892335/act_staging_vol
                     1784905464 1156455304 537775576  69% /act/mnt/Job_22202340_mountpoint_1448931899072
We set SID, login and verify
[oracle@demo-oracle-4 ~]$ export ORACLE_SID=jsontest
[oracle@demo-oracle-4 ~]$ sqlplus / as sysdba
SQL> @verifyDatabase.sql
....
INSTANCE_NUMBER INSTANCE_NAME HOST_NAME
--------------- ---------------- ----------------------------------------------------------------
VERSION   STARTUP_T STATUS PAR THREAD# ARCHIVE LOG_SWITCH_WAIT LOGINS   SHU
----------------- --------- ------------ --- ---------- ------- --------------- ---------- ---
DATABASE_STATUS   INSTANCE_ROLE      ACTIVE_ST BLO
----------------- ------------------ --------- ---
        1 jsontest demo-oracle-4
11.2.0.1.0   30-NOV-15 OPEN NO       1 STARTED ALLOWED    NO
ACTIVE   PRIMARY_INSTANCE   NORMAL    NO
When finished, we can get rid of the mount:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/unmountimage" --data-urlencode "image=Image_22202340" -d "delete&sessionid=$sessionid" | jq
{
  "result": "Job_22202374 to unmount Image_22202340 completed",
  "status": 0
}
How do we get restore options listed?
1)  List all my app classes:     udsinfo lsappclass
2) List all restore options per app class using a target host ID:    udsinfo lsrestoreoptions -applicationtype Oracle-action mount -targethost 20933867
In the example above, you will need to change the target host to match your own.
How do we get provisioning options listed?
1)  List all my app classes:     udsinfo lsappclass
2)  List all provisioning options per app class:    udsinfo lsappclass Oracle
Mounting and unmounting Images - Example 8:  Oracle App Aware mount with recovery time
We may want to use App Aware mount to bring our Oracle database online and roll the logs forward to a particular point in time.
When doing this we need to use the host points in time.   While this is clearly shown in the Actifio Desktop, in the CLI you need to ensure you work with the correct time range.
In this example the user 'av' has a timezone of Melbourne Australia, while the source host is in the Boston USA timezone.
Actifio:sa-hq:av> udsinfo lsuser av | grep time
timezone Australia/Melbourne
Actifio:sa-hq:av> udsinfo lsbackup Image_22349754 | grep "zone"
  timezone GMT-0500
Actifio:sa-hq:av> udsinfo lsbackup Image_22349754 | grep pit
  beginpit 2015-12-11 16:03:17
  endpit 2015-12-12 04:04:51
  hostbeginpit 2015-12-11 00:03:17
  hostendpit 2015-12-11 12:04:51
We can grab the host pit range quite easily with this REST command:
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" -d "sessionid=$sessionid" --data-urlencode "argument=Image_22349754" | jq  '.result | [."  timezone", ."  hostbeginpit", ."  hostendpit" ]'
[
  "GMT-0500",
  "2015-12-11 00:03:17",
  "2015-12-11 12:04:51"
]
Once we have selected out recovery time we can use this udstask command to mount the image:
udstask mountimage -image Image_22349754 -host demo-oracle-4 -label testav -recoverytime "2015-12-11 04:10:27" -restoreoption 'provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><password type="encrypt">*******</password><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>'
The REST version of this needed two data-url encode sections due to the recovery time
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=Image_22349754&host=demo-oracle-4&label=jsontest&sessionid=$sessionid" --data-urlencode 'recoverytime=2015-12-11 04:10:27' --data-urlencode 'restoreoption=provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><password type="encrypt">*******</password><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>'
One way to validate the command was issued correctly on the target host is to check the UDSAgent log with this command.
cat /var/act/log/UDSAgent.log | grep "recover database until time"
We should see an entry like this where the host time specified in the original command can clearly be seen.  Note the mount point contains the job number which makes it easier to find the correct entry.
run { catalog start with '/act/mnt/Job_22362562_mountpoint_1449888060617/archivelog' noprompt; catalog start with '/act/mnt/Job_22362562_mountpoint_1449888103502/archivelog' noprompt; recover database until time "to_date('201512110410','yyyymmddhh24mi')"; }
Mounting and unmounting Images - Example 9:  Oracle App Aware mount with re-protection
We may want to use App Aware mount to bring our Oracle database online and roll the logs forward to a particular point in time.
We also want to choose where it mounts.
We also want to re-protect it.
When doing this we need to use the host points in time.   While this is clearly shown in the Actifio Desktop, in the CLI you need to ensure you work with the correct time range.
In this example the user 'av' has a timezone of Melbourne Australia, while the source host is in the Boston USA timezone.
Actifio:sa-hq:av> udsinfo lsuser av | grep time
timezone Australia/Melbourne
Actifio:sa-hq:av> udsinfo lsbackup Image_22370949 | grep "zone"
  timezone GMT-0500
Actifio:sa-hq:av> udsinfo lsbackup Image_22370949 | grep pit
  beginpit 2015-12-14 12:03:58
  endpit 2015-12-14 16:02:18
  hostbeginpit 2015-12-14 12:03:58
  hostendpit 2015-12-14 16:02:18
We also want to choose where it mounts:
udsinfo lsbackup Image_22370949 | grep dasvol
    uniqueid dasvol:smalldb
    uniqueid dasvol:smalldb_archivelog
We can grab the host pit range and dasvol details quite easily with this REST command:
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" -d "sessionid=$sessionid" --data-urlencode "argument=Image_22370949" | jq  '.result | [."  timezone", ."  hostbeginpit", ."  hostendpit",."    uniqueid" ]'
[
  "GMT-0500",
  "2015-12-14 12:03:58",
  "2015-12-14 16:02:18",
  [
    "dasvol:smalldb",
    "dasvol:smalldb_archivelog"
  ]
]
We choose a recovery time of host time: 2015-12-14 12:17:27
We want to mount:
smalldb to /mnt/smalldb
smalldb_acrchivelog to /mnt/smalldb_logs
We want to re-protect using the Gold Template with the Local Profile
Gold has an SLT ID of 8629
Local Profile has an SLP ID of 51
[18:10:38] sa-hq1:~ # udsinfo lsslt | grep Gold
    8629 true     Gold Policy            Gold
[18:10:49] sa-hq1:~ # udsinfo lsslp | grep Local
      51 Local profile           Local Profile  act_per_pool000                none        sa-hq
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsslt" -d "sessionid=$sessionid" | jq -c  '.result [] | [.id, .name]'
["103","Platinum"]
["8629","Gold"]
["16905","Bronze"]
["4536878","Gold-LogSmart"]
["7456379","Cloud"]
["17791329","Silver"]
["20460291","Silver LogSmart"]
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsslp" -d "sessionid=$sessionid" | jq -c  '.result [] | [.id, .name]'
["51","Local Profile"]
["8812","Remote Profile"]
["20461775","AWS Profile"]
This creates this command that effectively has three sections:
Mountpoints:
mountpointperdisk-dasvol:smalldb=/mnt/smalldb,mountpointperdisk-dasvol:smalldb_archivelog=/mnt/smalldb_logs
Reprotect info:
reprotect=true,sltid=8629,slpid=51
Provisioning options for the app aware mounts:
<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>
Giving us this command:
udstask mountimage -image Image_22370949-host demo-oracle-4 -label testav -recoverytime "2015-12-14 12:17:27" -restoreoption 'mountpointperdisk-dasvol:smalldb=/mnt/smalldb,mountpointperdisk-dasvol:smalldb_archivelog=/mnt/smalldb_logs,reprotect=true,sltid=8629,slpid=51,provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>'
The REST version of this needed two data-url encode sections due to the recovery time causing some quirks:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=Image_22370949&host=demo-oracle-4&label=jsontest&sessionid=$sessionid" --data-urlencode 'recoverytime=2015-12-14 12:17:27'--data-urlencode'restoreoption=mountpointperdisk-dasvol:smalldb=/mnt/smalldb,mountpointperdisk-dasvol:smalldb_archivelog=/mnt/smalldb_logs,reprotect=true,sltid=8629,slpid=51,provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><password type="encrypt">*******</password><orahome>/home/oracle/app/oracle/product/11.2.0/dbhome_1</orahome><tnsadmindir>/home/oracle/app/oracle/product/11.2.0/dbhome_1/network/admin</tnsadmindir><totalmemory></totalmemory><sgapct></sgapct><tnsip></tnsip><tnsport></tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>'
{"result":"Job_22375641 to mount Image_22370949 completed","status":0}
Now there are several things we need to check after this:
1)  Did we get the right mount point?
On the target host we run:
[oracle@demo-oracle-4 ~]$ df
Filesystem           1K-blocks     Used Available Use% Mounted on
/dev/mapper/vg_demooracle1-lv_root
                      36580952 16109552  18606492  47% /
tmpfs                  5065472   310180   4755292   7% /dev/shm
/dev/sda1               487652    68810    393242  15% /boot
/dev/sdb              51475068  2031900  46821728   5% /mnt/smalldb
/dev/sdc              51475068    82992  48770636   1% /mnt/smalldb_logs
2)  Did the logs roll forward?
On the target host we run:
cat /var/act/log/UDSAgent.log | grep "recover database until time"
We should see an entry like this where the host time specified in the original command can clearly be seen.  Note the mount point contains the job number which makes it easier to find the correct entry.
run { catalog start with '/act/mnt/Job_22362562_mountpoint_1449888060617/archivelog' noprompt; catalog start with '/act/mnt/Job_22362562_mountpoint_1449888103502/archivelog' noprompt; recover database until time "to_date('201512110410','yyyymmddhh24mi')"; }
3)  Did we get a new application?
Lets look for apps with our new DB name and target host name.
udsinfo lsapplication -filtervalue "appname=jsontest&hostname=demo-oracle-4"
In REST that's:
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsapplication" --data-urlencode "filtervalue=appname=jsontest&hostname=demo-oracle-4" -d "sessionid=$sessionid" | jq -c  '.result [] | [.id, .appname]'
["22375678","jsontest"]
There is our application ID: 22375678
4)  Does the new application have any snapshots?
udsinfo lsbackup -filtervalue "appid=22375678&jobclass=snapshot"
In REST thats:
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" --data-urlencode "filtervalue=appid=22375678" -d "sessionid=$sessionid" | jq -c  '.result [] | [.id, .appname, .jobclass, .consistencydate]'
["22375693","jsontest","snapshot","2015-12-15 11:22:31.000"]
If you do not find a snapshot, maybe one is still being created or maybe your new application did not get protected.
Once we are finished we can start tearing this all down:
5)  Lets clean them up:
usdtask expireimage -image 22375693
In REST that is:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/expireimage" -d "image=22375693" -d "sessionid=$sessionid"
{"result":"Job_22375751 to expire Image_22375691 completed","status":0}
6)  Lets get rid of the application:
udstask rmapplication 22375678
In REST that is:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/rmapplication" -d "argument=22375678" -d "sessionid=$sessionid"
Mounting and unmounting Images - Example 10:  Oracle App Aware mount to RAC
We may want to use App Aware mount to bring our Oracle database online to a RAC cluster.
We need to assemble several pieces of information to do this.
First up the RAC members need to be defined to Actifio as hosts.   We need to know their IP addresses.
We also need to have an ASM backup.   In this example we know Image_22336426 is ASM as per this attribute:
[22:55:09] sa-hq1:~ # udsinfo lsbackup Image_22336426 | grep isasm
isasm true
We are interested in the isasmbeing true
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsbackup" -d "sessionid=$sessionid" --data-urlencode "argument=Image_22336426" | jq -c '.result | [.id, .isasm, .consistencydate, ."  beginpit", ."  endpit" ]'
["22336430","true","2015-12-11 04:06:27.000","2015-12-11 04:06:27","2015-12-11 14:01:55"]
In this example the ASM node list is 172.24.1.231  and 172.24.1.232
So the CLI to mount to the two nodes is:
udstask mountimage -image Image_22336426 -host oracle-rac-1 -label testav -restoreoption 'asmracnodelist=172.24.1.231:172.24.1.232,provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><orahome>/oracle/11.2.0/product/dbhome_1</orahome><tnsadmindir>/crs/11.2.0/product/grid_home/network/admin</tnsadmindir><totalmemory>1024</totalmemory><sgapct>70</sgapct><tnsip>oracle-rac-scan</tnsip><tnsport>1521</tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>'
The REST version is:
curl -sS -w "\n" -k -XPOST -G "https://$cdsip/actifio/api/task/mountimage" -d "image=Image_22336426&host=oracle-rac-1&sessionid=$sessionid" --data-urlencode "restoreoption=asmracnodelist=172.24.1.231:172.24.1.232,provisioningoptions=<provisioning-options><databasesid>jsontest</databasesid><username>oracle</username><orahome>/oracle/11.2.0/product/dbhome_1</orahome><tnsadmindir>/crs/11.2.0/product/grid_home/network/admin</tnsadmindir><totalmemory>1024</totalmemory><sgapct>70</sgapct><tnsip>oracle-rac-scan</tnsip><tnsport>1521</tnsport><tnsdomain></tnsdomain><rrecovery>true</rrecovery><standalone>false</standalone><envvar></envvar></provisioning-options>"
{"result":"Job_22349396 to mount Image_22336426 completed","status":0}
On RAC node 1 we confirm like this:
Every 2.0s: srvctl status database -d jsontest; echo ""; ps -ef | grep pmon | grep -v grep                                                                                           Thu Dec 10 23:13:18 2015
Instance jsontest1 is running on node oracle-rac-1
Instance jsontest2 is running on node oracle-rac-2
oracle   15495     1  0 23:12 ?        00:00:00 ora_pmon_jsontest1
grid     25857     1  0 Oct17 ?        00:09:53 asm_pmon_+ASM1
On RAC Node 2 we confirm like this:
Every 2.0s: ps -ef | grep pmon | grep -v grep ; echo ""; echo ""; df -h                                                                                                              Thu Dec 10 23:13:52 2015
grid     14929     1  0 Oct17 ?        00:08:58 asm_pmon_+ASM2
oracle   18849     1  0 23:12 ?        00:00:00 ora_pmon_jsontest2
Hosts:   List them and get their connector version - example commands:
Lets find what version connector is installed on our hosts:
udsinfo lshost -filtervalue hasagent=true
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lshost?sessionid=$sessionid&filtervalue=hasagent=true" ​| jq -c '.result[] | [.id, .hostname, .ostype, .connectorversion]'
["4497","hq-vcenter","Win32","6.1.7.60269"]
["4503","sa-esx1.sa.actifio.com","",""] 
["4508","sa-esx2.sa.actifio.com","",""]
["9521","hq-exchange","Win32","6.1.7.60269"]
["17170","sharepoint-prod","Win32","6.1.7.60269"]
["735134","hq-sql","Win32","6.1.7.60269"]
["1668749","sa-esx4.sa.actifio.com","",""]
["1867850","db2-linux-prod","Linux","6.1.7.60269"]
["4486107","hv-sql","Win32","6.1.7.60269"]
["17433929","Oracle-Mask-Prd","Linux","6.1.7.60269"]
["17475380","sql-masking-dev","Win32","6.1.8.61044"]
["17475383","sql-masking-prod","Win32","6.1.7.60269"]
["17555397","sql-masking-stage","Win32","6.1.7.60269"]
How about for a specific host:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lshost?sessionid=$sessionid&argument=demo-oracle-4"| jq 
{
  "result": {
    "ostype": "Linux",
    "uniquename": "501d22d5-1fb8-ff65-ae67-6264d60b8a5e",
    "ipaddress": "172.24.4.171",
    "osversion": "#1 SMP Thu Aug 13 22:55:16 UTC 2015",
    "id": "20929573",
    "originalhostid": "0",
    "timezone": "GMT-0500",
    "isclusterhost": "false",
    "isproxyhost": "false",
    "vcenterhostid": "4497",
    "friendlypath": "Needham:/Demo-Pod-4/Demo-Oracle-4",
    "modifydate": [
      "2015-08-28 11:34:17.110",
      "2015-10-16 21:02:38"
    ],
    "isesxhost": "false",
    "isvm": "true",
    "upgradestatus": "Upgrade Success",
    "hostname": "demo-oracle-4",
    "vmtype": "vmware",
    "properties": "0",
    "osrelease": "2.6.32-573.3.1.el6.x86_64",
    "hasagent": "true",
    "isvcenterhost": "false",
    "connector.port": "5106",
    "sourcecluster": "590021596788",
    "installdate": "2015-10-17 01:02:04",
    "connectorversion": "6.1.7.60269",
    "errorcode": "0",
    "maxjobs": "0"
  },
  "status": 0
}
We just want the connector version:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lshost?sessionid=$sessionid&argument=demo-oracle-4"| jq '.result | .connectorversion'
"6.1.7.60269"
What are the latest connectors?
udsinfo lsavailableconnector -filtervalue latest=true
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsavailableconnector?sessionid=$sessionid&filtervalue=latest=true"| jq -c '.result[] | [.ostype, .displayname]'
["solaris_sparc","6.2.0.63215"]
["aix","6.2.0.63215"]
["hpux","6.2.0.63215"]
["solaris_x86","6.2.0.63215"]
["linux","6.2.0.63215"]
["win32","6.2.0.63215"]
["linux_x86","6.2.0.63215"]
How about just for Linux?
udsinfo lsavailableconnector -filtervalue ostype=linux\&latest=true
curl -sS -w "\n" -k -G "https://$cdsip/actifio/api/info/lsavailableconnector" --data-urlencode "filtervalue=latest=true&ostype=linux"-d "sessionid=$sessionid" | jq -c '.result[] | [.ostype, .displayname]'
["linux","6.2.0.63215"]
Time to upgrade demo-oracle-4 to the latest release.
This command returns immediately but it takes a few minutes for the new version to show.
udstask upgradehostconnector -hosts demo-oracle-4
curl -s -w "\n" -k -XPOST "https://$cdsip/actifio/api/task/upgradehostconnector?sessionid=$sessionid&hosts=demo-oracle-4"| jq
{
  "status": 0
}
Wait a few minutes and check again:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lshost?sessionid=$sessionid&argument=demo-oracle-4"| jq '.result | .connectorversion'
"6.2.0.63215"
Fetching pool details - example commands:
To get pools we normally use this udsinfo command:   udsinfo lsdiskpool
Raw output from lsdiskpool:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"
{"result":[{"id":"71","modifydate":"2015-10-01 04:00:57.144","warnpct":"77","name":"act_pri_pool000","safepct":"90","mdiskgrp":"act_pri_pool000"},{"id":"72","modifydate":"2015-08-30 10:08:12.332","warnpct":"90","name":"act_ded_pool000","safepct":"100","mdiskgrp":"act_ded_pool000"},{"id":"73","modifydate":"2015-10-01 03:42:03.440","warnpct":"81","name":"act_per_pool000","safepct":"85","mdiskgrp":"act_per_pool000"}],"status":0}
Processed with jq
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq
{
  "result": [
    {
      "id": "71",
      "modifydate": "2015-10-01 04:00:57.144",
      "warnpct": "77",
      "name": "act_pri_pool000",
      "safepct": "90",
      "mdiskgrp": "act_pri_pool000"
    },
    {
      "id": "72",
      "modifydate": "2015-08-30 10:08:12.332",
      "warnpct": "90",
      "name": "act_ded_pool000",
      "safepct": "100",
      "mdiskgrp": "act_ded_pool000"
    },
    {
      "id": "73",
      "modifydate": "2015-10-01 03:42:03.440",
      "warnpct": "81",
      "name": "act_per_pool000",
      "safepct": "85",
      "mdiskgrp": "act_per_pool000"
    }
  ],
  "status": 0
}
First up if we look at the output we want to understand there are two sections, the resultsection and the statussection.
If you want the result or the status, ask for it you get just that section.   The status section is rather short.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq '.status'
0
If we grab the result section, lets ask for what is inside the box in the results section,  this is normally what is most interesting:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq '.result []'
{
  "id": "71",
  "modifydate": "2015-10-01 04:00:57.144",
  "warnpct": "77",
  "name": "act_pri_pool000",
  "safepct": "90",
  "mdiskgrp": "act_pri_pool000"
}
{
  "id": "72",
  "modifydate": "2015-08-30 10:08:12.332",
  "warnpct": "90",
  "name": "act_ded_pool000",
  "safepct": "100",
  "mdiskgrp": "act_ded_pool000"
}
{
  "id": "73",
  "modifydate": "2015-10-01 03:42:03.440",
  "warnpct": "81",
  "name": "act_per_pool000",
  "safepct": "85",
  "mdiskgrp": "act_per_pool000"
}
We can flatten the output with -c (compact).   Because there are not many fields, this flattens nicely.   Most output have lots of fields so spread across multiple lines.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -c '.result []'
{"id":"71","modifydate":"2015-10-01 04:00:57.144","warnpct":"77","name":"act_pri_pool000","safepct":"90","mdiskgrp":"act_pri_pool000"}
{"id":"72","modifydate":"2015-08-30 10:08:12.332","warnpct":"90","name":"act_ded_pool000","safepct":"100","mdiskgrp":"act_ded_pool000"}
{"id":"73","modifydate":"2015-10-01 03:42:03.440","warnpct":"81","name":"act_per_pool000","safepct":"85","mdiskgrp":"act_per_pool000"}
One of the nice things is we can keep piping the output for further processing without running jq twice.   In this example we first strip out the results and then ask for just the pool names:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq '.result [] | .name'
"act_pri_pool000"
"act_ded_pool000"
"act_per_pool000"
In the output above we got double quotes, so if we add -r for raw we lose those and get just the names.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -r '.result [] | .name'
act_pri_pool000
act_ded_pool000
act_per_pool000
But if we ask for two things, they get put on separate lines.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -r '.result [] | .name, .id'
act_pri_pool000
71
act_ded_pool000
72
act_per_pool000
73
If we want them on one line, we can define this like this:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -cr '.result [] | [.name, .id]'
["act_pri_pool000","71"]
["act_ded_pool000","72"]
["act_per_pool000","73"]
If we want the output in CSV, we can do this:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -cr '.result [] | [.name, .id] | @csv'
"act_pri_pool000","71"
"act_ded_pool000","72"
"act_per_pool000","73"
If you want to add out own header lines, we can do this:
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -cr '["PoolName", "PoolID"], (.result [] | [.name, .id]) | @csv'
"PoolName","PoolID"
"act_pri_pool000","71"
"act_ded_pool000","72"
"act_per_pool000","73"
We still have double quotes.   They are not being removed by 'raw' option.
We can use sed:   sed 's/\"//g'
NOTE - double quotes in CSV are both legal and necessary.   Host names and App Names contain commas.  The double quotes stop them being used as field delimiters.
curl -s -w "\n" -k "https://$cdsip/actifio/api/info/lsdiskpool?sessionid=$sessionid"| jq -cr '["PoolName", "PoolID"], (.result [] | [.name, .id]) | @csv' |  sed 's/\"//g'
PoolName,PoolID
act_pri_pool000,71
act_ded_pool000,72
act_per_pool000,73
