#!/bin/bash

# A simple NRPE check to monitor the time since the puppet agent was last run
# Notes:
#	- This will catch SSL cert errors, since the state file is not modified if the puppet agent encounters an SSL error.
#	- To access the state file, the nagios user must be a member of the puppet group.
# - Doesn't bother with taking warning/critical thresholds as arguments, since it's easy enough to change in the script, then deploy to all nodes using the puppet server.
# Warnings:
#	- Does not do any checks related to the puppet daemon, although it should work with it. This was designed with the assumption that a cron job is running the agent.
#	- Only tested on Debian & CentOS, but will work on any distro with the same state.yml path

# NRPE Exit Codes, for reference:
#	0: OK
#	1: WARNING
#	2: CRITICAL
#	3: UNKNOWN

# Thresholds for warning & critical levels, in minutes:
warning_threshold=60
critical_threshold=120

# Path to state file. Verified on Debian & CentOS, may need to be changed on other distros:
state_file=/var/lib/puppet/state/state.yaml

# Covert minutes to seconds, to make the computer happy:
warning_threshold_sec=$(expr $warning_threshold \* 60)
critical_threshold_sec=$(expr $critical_threshold \* 60)

# Make sure the state file exists:
if [ ! -f "$state_file" ]; then
	echo "CRITICAL: Puppet state file $state_file does not exist, or is not readable. Make sure the nagios user is a member of the puppet group"
	exit 2
fi
lastrun_time=$(stat -c %Y "$state_file")

now_time=$(date +%s)
time_since_run=$(expr $now_time - $lastrun_time)
time_since_run_human=$(expr $time_since_run / 60)

# Check time run against thresholds, and exit with appropriate status for NRPE to report to Nagios:
if (($time_since_run < $warning_threshold_sec)); then
	echo "OK: The last puppet run was $time_since_run_human minutes ago"
	exit 0 
elif (($time_since_run >= $warning_threshold_sec && $time_since_run < $critical_threshold_sec)); then
	echo "WARNING: The last puppet run was $time_since_run_human minutes ago"
	exit 1
elif (($time_since_run >= $critical_threshold_sec)); then
	echo "CRITICAL: The last puppet run was $time_since_run_human minutes ago"
	exit 2
else
	echo "CRITICAL: Last puppet run $time_since_run_human minutes is out of check range"
	exit 2
fi
