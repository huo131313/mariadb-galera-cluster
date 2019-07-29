#! /bin/bash

cmdline_args=$@
user=mysql
euid=$(id -u)
log_file=$(mktemp /tmp/wsrep_recovery.XXXXXX)
start_pos='0'

log() {
	local msg="galera-start-pos.sh: $@"
	# Print all messages to stderr as we reserve stdout for printing
	# --wsrep-start-position=XXXX.
	echo "$msg" >&2
}

finish() {
	rm -f "$log_file"
}

trap finish EXIT

wsrep_recover_position() {

	echo "wsrep_recover_position:  mysqld --user=$user	--wsrep-recover --log-error=$log_file"
	eval mysqld --user=$user \
			--wsrep-recover \
			--log-error="$log_file"
	if [ $? -ne 0 ]; then
		# Something went wrong, let us also print the error log so that it
		# shows up in systemctl status output as a hint to the user.
		log "Failed to start mysqld for wsrep recovery: '`cat $log_file`'"
		exit 1
	fi

	start_pos=$(sed -n 's/.*WSREP: Recovered position:\s*//p' $log_file)

	if [ -z $start_pos ]; then
		skipped="$(grep WSREP $log_file | grep 'skipping position recovery')"
		if [ -z "$skipped" ]; then
			log "=================================================="
			log "WSREP: Failed to recover position: '`cat $log_file`'"
			log "=================================================="
			exit 1
		else
			log "WSREP: Position recovery skipped."
		fi

	else
		log "Found WSREP position: $start_pos"
	fi
}

if [ -n "$log_file" -a -f "$log_file" ]; then
	[ "$euid" = "0" ] && chown $user $log_file
	chmod 600 $log_file
else
	log "WSREP: mktemp failed"
fi

if [ -f /var/lib/mysql/ibdata1 ]; then
	log "Attempting to recover GTID positon..."
	wsrep_recover_position
else
	log "No ibdata1 found, starting a fresh node..."
fi

echo "$start_pos"
