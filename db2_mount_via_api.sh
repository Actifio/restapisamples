#!/bin/sh
# Check if all required arguments are provided

if [ $# -lt 7 ]; then
  cat << EOF
  Usage: $0 <MS_URL> <appid> <datavol> <logvol> <logbackup> <hostid> <disktypie> <wait_flag>
  MS_URL     :  Management Console URL, Ex: https://bmc-699999999995-pxyzabco-dot-asia-southeast1.backupdr.googleusercontent.com
  appid      :  Source Application ID from Management Console
  datavol    :  Data volume mount point Ex: /opt/ibm/db2/data
  logvol     :  Log Volume mount point Ex: /opt/ibm/db2/log
  logbackup  :  Log Backup mount point Ex: /opt/ibm/db2/backup
  hostid     :  Target host ID from Management Console
  disktype   :  Target Disk type (pd-ssd, pd-balanced, pd-standard, pd-extreme, etc)
  wait_flag  :  Wait for the mount job completion (true/false)
  e.g # ./db2_mount_via_api.sh https://bmc-699999999995-pxxxxyyo-dot-asia-southeast1.backupdr.googleusercontent.com 1340102 /mnt/data /mnt/log /mnt/backup 1294549 pd-ssd true
EOF
  exit 1
fi
set -x
MS_URL="$1"
appid="$2"
datavol="$3"
logvol="$4"
archivevol="$5"
hostid="$6"
disktype="$7"
wait_flag="$8"

if [[ -z "$wait_flag" ]]; then
   wait_flag=false
fi

label="$(tr -dc 'a-z' < /dev/urandom | head -c 8; echo)"
label='db2_mount_'"$label"
TOUCH_DIR="/act/touch"

output_date()
{
  echo "Date: "$(date +"%m-%d-%Y %H:%M:%S")""
}

TMPPATH=$PWD
remove_file()
{
  filename=$1
  if [[ -f $filename ]]; then
     rm -f $filename
  fi
}

generate_token()
{
# Get the Google Cloud access token
    token=$(gcloud auth print-access-token)

    # Check if token retrieval was successful
    if [[ $? -ne 0 ]]; then
      echo "Error: Failed to get Google Cloud access token."
      remove_file $TMPPATH/data_$label.json
      remove_file $TMPPATH/test_$label.out
      exit 1
    fi

    # Create a BackupDR session
    session=$(curl -s -f -s -f -XPOST -H "Content-Length: 0" -H "Authorization: Bearer $token" \
      "$MS_URL/actifio/session" \
      | grep -o '"session_id".*' | awk -F '"' '{print $4}')

    # Check if session creation was successful
    if [[ -z "$session" ]]; then
      echo "Error: Failed to create BackupDR session."
      remove_file $TMPPATH/data_$label.json
      remove_file $TMPPATH/test_$label.out
      exit 1
    else
      echo "BackupDR session created successfully -> $session"
    fi
}

#### Generate token and generate token ################
output_date
generate_token

################# Get the Image details for the application ID ##############################

data=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/backup?filter=appid:==$appid&sort=consistencydate:desc&limit=1"`
echo "$data" > $TMPPATH/data_$label.json  # Save data to a file
image=$(jq -r '.items[0].id' $TMPPATH/data_$label.json)
id=$(jq -r '.items[0].host.id' $TMPPATH/data_$label.json)
echo "======= Initiating mount job with the parameters ==========="
echo "TARGET_HOST=$hostid"
echo "APPID=$appid"
echo "DATAVOL=$datavol"
echo "LOGVOL=$logvol"
echo "LOGBKP=$archivevol"
echo "DISKTYPE=$disktype"
echo "BACKUP IMAGE=$image"
echo "==========================================================="
curl -s -f -X POST \
          -H "backupdr-management-session: Actifio $session" \
          -H "Authorization: Bearer $token" \
          -H "Content-Type: application/json" \
          "$MS_URL/actifio/backup/$image/mount" \
          -d '{
              "restoreobjectmappings": [],
              "host": {
                  "id": "'"$hostid"'"
              },
              "restoreoptions": [
                  {
                      "name": "disktypemapping",
                      "value": "db2backup:'"$disktype"',db2log:'"$disktype"',db2data:'"$disktype"'"
                  },
                  {
                      "name": "mountpointmapping",
                      "value": "db2backup:backup:'"$archivevol"',db2log:log:'"$logvol"',db2data:data:'"$datavol"'"
                  }
              ],

              "label": "'"$label"'",
              "selectedobjects": []
}'

retval=$?
if [[ "$retval" -gt 0 ]]; then
   echo "Failed submit mount job"
   remove_file $TMPPATH/data_$label.json
   remove_file $TMPPATH/test_$label.out
   exit 1
else
   echo "Mount job successfully submitted"
   remove_file $TMPPATH/data_$label.json
   remove_file $TMPPATH/test_$label.out
fi

if [[ "$wait_flag" != "true" ]]; then
   exit 0
fi

echo "=======  Monitoring the mount job ========"
sleep 10
jobs=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/jobstatus?filter=label:==$label&filter=jobclass:==mount"`

output_date

########################## Get the Job ID #######################
count=0
echo "$jobs" > $TMPPATH/data_$label.json  # Save data to a file
jobid=$(jq -r '.items[0].id' $TMPPATH/data_$label.json)
while [[ -z "$jobid" ]] || [[ "$jobid" == "null" ]]; do
      sleep 20
      echo "Trying to get tthe job id"
      jobs=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/jobstatus?filter=label:==$label&filter=jobclass:==mount"`
      if [[ -z "$jobs" ]]; then
         generate_token
      fi
     echo "$jobs" > $TMPPATH/data_$label.json  # Save data to a file
     jobid=$(jq -r '.items[0].id' $TMPPATH/data_$label.json)
     count=$(($count+1))
     if [[ "$count" -eq 360 ]]; then
        echo "Unable to get the Job ID"
        remove_file $TMPPATH/data_$label.json
        remove_file $TMPPATH/test_$label.out
        exit 1
     fi
done

########################## Get the Job status #######################
status=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/job/$jobid"`
sleep 2

output_date

echo "$status" > $TMPPATH/data_$label.json
jobstatus=$(jq -r '.status' $TMPPATH/data_$label.json)
while [[ "$jobstatus" == "running" ]]; do
   echo "====== Mount job $jobid is still running ====="
   sleep 20
   status=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/job/$jobid"` 2>&1
   if [[ -z "$status" ]]; then
      generate_token
   fi
   echo "$status" > $TMPPATH/data_$label.json
   jobstatus=$(jq -r '.status' $TMPPATH/data_$label.json)
   if [[ -z "$jobstatus" ]]; then
      sleep 20
      status=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/job/$jobid"` 2>&1
      echo "$status" > $TMPPATH/data_$label.json
      jobstatus=$(jq -r '.status' $TMPPATH/data_$label.json)
   fi
done
output_date
sleep 10
count=0

###################################### Job Message ############################
jobmessage=$(jq -r '.message' $TMPPATH/data_$label.json)
while [[ "$jobmessage" == "null" ]] || [[ -z "$jobmessage" ]]; do
    sleep 20
    status=`curl -s -f -XGET -H "backupdr-management-session: Actifio $session" -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$MS_URL/actifio/job/$jobid"` 2>&1
    if [[ -z "$status" ]]; then
       generate_token
    fi
    echo "$status" > $TMPPATH/data_$label.json
    jobmessage=$(jq -r '.message' $TMPPATH/data_$label.json)
    count=$(($count+1))
    if [[ "$count" -eq 360 ]]; then
       echo "Unable to get the Job ID"
       remove_file $TMPPATH/data_$label.json
       remove_file $TMPPATH/test_$label.out
       exit 1
    fi
done
output_date

if [[ "$jobstatus" == "succeeded" ]]; then
   echo "================ Mount completed successfully for the app:$appid==================="
else
   echo "Mount job failed with the error message :$jobmessage"
   #echo "Mount job failed for the application: $appid  with the error message :$jobmessage" | mail -s "Integrity Check Failed" xyz@abc.com
   remove_file $TMPPATH/data_$label.json
   remove_file $TMPPATH/test_$label.out
   remove_file $TOUCH_DIR/'.'"$appid"_mount.txt
   exit 1
fi
output_date
remove_file $TMPPATH/data_$label.json
remove_file $TMPPATH/test_$label.out