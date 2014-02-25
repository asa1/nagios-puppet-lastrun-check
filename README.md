nagios-puppet-lastrun-check
===========================

This NRPE check for Nagios tests how long it has been since the puppet agent was run, and exits with OK, Warning or Critical status depending on the interval. This is useful in installations where the puppet agent is being run by a cron job, rather than the daemon. 
