#!/bin/sh

MINE=`dirname $0`
. ${MINE}/env.sh

ARGS="-r -t 60 -v 1 -c"


#Print the usage
usage() {
cat << EOF
Usage: $0 -i instances -o output [-- bench_params]
Bench every instances and store the result

  -i instances: a file listing the path of each instance file
  -o output: the output directory
  bench_params: will be passed to org.btrplace.bench.Bench (default: $ARGS)
EOF
}

OPTIND=0
while getopts "i:o:h" opt; do
	case $opt in
		h) 
			usage
			exit 0
			;;
		i)
			INPUT=`readlink -f $OPTARG`;;
  		o)
			OUTPUT=`readlink -f $OPTARG`;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			exit 1
			;;
	esac
done

if [ -z ${INPUT+x} -o -z ${OUTPUT+x} ]; then
	echo "Missing required parameters. See with '$0 -h'"
	exit 1
fi

if [ $1 == "--" ]; then
	shift
	ARGS=$@
fi

mvn -f ${ROOT}/scheduler/bench/pom.xml exec:java\
	-Dexec.mainClass="org.btrplace.bench.Bench" \
	-Dexec.args="-l ${INPUT} -o ${OUTPUT} ${ARGS}"
