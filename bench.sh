#!/bin/sh

MINE=`dirname $0`
. ${MINE}/env.sh

ARGS="-r -t 60 -v 1 -c"
OPTIND=0
while getopts "i:o:" opt; do
	case $opt in
		i)
			INPUT=`readlink -f $OPTARG`;;
  		o)
			OUTPUT=`readlink -f $OPTARG`;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
	esac
done
if [ $1 == "--" ]; then
	shift
	ARGS=$@
fi

mvn -f ${ROOT}/scheduler/bench/pom.xml exec:java\
	-Dexec.mainClass="org.btrplace.bench.Bench" \
	-Dexec.args="-l ${INPUT} -o ${OUTPUT} ${ARGS}"
