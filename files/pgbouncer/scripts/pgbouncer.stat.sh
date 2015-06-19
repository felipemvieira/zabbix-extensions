#!/usr/bin/env bash
# Authors:	Lesovsky A.V.
# 		Felipe M Vieira
# Description:	Pgbouncer pools stats
# $1 - param_name, $POOL - pool_name

pgbouncer_stat_ver="1.0"
pgbouncer_passfile='/var/lib/zabbix/.pgpass'

function usage()
{
    echo "pgbouncer_stat version: $pgbouncer_stat_ver"
    echo "usage:"
    echo "    $0 avg_req [pool_name]       -- Check total accesses."
    echo "    $0 avg_req [pool_name]       -- Average requests per second in last stat period."
    echo "    $0 avg_recv [pool_name]      -- Average received (from clients) bytes per second."
    echo "    $0 avg_sent [pool_name]      -- Average sent (to clients) bytes per second."
    echo "    $0 avg_query [pool_name]     -- Average query duration in microseconds."
    echo "    $0 cl_active [pool_name]     -- Count of currently active client connections."
    echo "    $0 cl_waiting [pool_name]    -- Count of currently waiting client connections."
    echo "    $0 sv_active [pool_name]     -- Count of currently active server connections."
    echo "    $0 sv_idle [pool_name]       -- Count of currently idle server connections."
    echo "    $0 sv_used [pool_name]       -- Count of currently used server connections."
    echo "    $0 sv_tested [pool_name]     -- Count of currently tested server connections."
    echo "    $0 sv_login [pool_name]      -- Count of server connections currently login to PostgreSQL."
    echo "    $0 maxwait [pool_name]       -- How long has first (oldest) client in queue waited, in second."
    echo "    $0 free_clients              -- Count of free clients."
    echo "    $0 used_clients              -- Count of used clients."
    echo "    $0 login_clients             -- Count of clients in login state."
    echo "    $0 free_servers              -- Count of free servers."
    echo "    $0 used_servers              -- Count of used servers."
} 
one_params=(free_clients used_clients login_clients free_servers used_servers version)
two_params=(avg_req avg_req avg_recv avg_sent avg_query cl_active cl_waiting sv_active sv_idle sv_used sv_tested sv_login maxwait)

if [[ ! -f $pgbouncer_passfile ]]; then echo "ERROR: $pgbouncer_passfile not found" ; exit 1; fi

if [[ $# ==  1 ]]; then
	if [[ ! ${one_params[*]} =~ $1 ]]; then
        	usage
		exit 0
	fi
elif [[ $# == 2 ]]; then
        if [[ ! ${two_params[*]} =~ $1 ]]; then
                usage
                exit 0
        fi
else
    #No Parameter
    usage
    exit 0
fi

PSQL=$(which psql)

hostname=$(head -n 1 $pgbouncer_passfile |cut -d: -f1)
port=$(head -n 1 $pgbouncer_passfile |cut -d: -f2)
username=$(head -n 1 $pgbouncer_passfile |cut -d: -f3)
dbname="pgbouncer"
PARAM="$1"
POOL="$2"

if [ '*' = "$hostname" ]; then hostname="127.0.0.1"; fi

conn_param="-qAtX -F: -h $hostname -p $port -U $username $dbname"

case "$PARAM" in
'avg_req' )
        $PSQL $conn_param -c "show stats" |grep -w $POOL |cut -d: -f6
        rval=$?;;
'avg_recv' )
        $PSQL $conn_param -c "show stats" |grep -w $POOL |cut -d: -f7
        rval=$?;;
'avg_sent' )
        $PSQL $conn_param -c "show stats" |grep -w $POOL |cut -d: -f8
        rval=$?;;
'avg_query' )
        $PSQL $conn_param -c "show stats" |grep -w $POOL |cut -d: -f9
        rval=$?;;
'cl_active' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f3
        rval=$?;;
'cl_waiting' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f4
        rval=$?;;
'sv_active' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f5
        rval=$?;;
'sv_idle' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f6
        rval=$?;;
'sv_used' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f7
        rval=$?;;
'sv_tested' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f8
        rval=$?;;
'sv_login' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f9
        rval=$?;;
'maxwait' )
        $PSQL $conn_param -c "show pools" |grep -w ^$POOL |cut -d: -f10
        rval=$?;;
'free_clients' )
        $PSQL $conn_param -c "show lists" |grep -w free_clients |cut -d: -f2
        rval=$?;;
'used_clients' )
        $PSQL $conn_param -c "show lists" |grep -w used_clients |cut -d: -f2
        rval=$?;;
'login_clients' )
        $PSQL $conn_param -c "show lists" |grep -w login_clients |cut -d: -f2
        rval=$?;;
'free_servers' )
        $PSQL $conn_param -c "show lists" |grep -w free_servers |cut -d: -f2
        rval=$?;;
'used_servers' )
	$PSQL $conn_param -c "show lists" |grep -w used_servers |cut -d: -f2
	rval=$?;;
'version' )
	echo "$pgbouncer_stat_ver"
	exit $rval;;
* )
	usage
	exit $rval;;
esac

if [ "$rval" -ne 0 ]; then
      echo "ZBX_NOTSUPPORTED"
fi

exit $rval

#
# end pgbouncer_stat
