#!/bin/bash
MINE=`dirname $0`
. ${MINE}/env.sh

COMMIT="master"
PARAMS="-t 60 -r -v 1"

#Print the usage
usage() {
cat << EOF
Usage: $0 [-c commit] [-l label] [-- bench_params]
Run the benchmark and publish the results in ${PUBLISH_DIR}/label

  -c commit: use the given commit identifier for the scheduler. (default: $COMMIT)
  -l label: identify the benchmark with the given label. (default is 'commit')
  bench_params: will be passed to bench.sh. (default: '$PARAMS')
EOF
}

#Get the code at commit $1 and install it
fetch() {
	git -C ${ROOT}/scheduler/ pull||exit 1
	git -C ${ROOT}/scheduler/ checkout $1||exit 1
	mvn -f ${ROOT}/scheduler/ -q install -DskipTests -Dgpg.skip||exit 1
}

#Create the output directory in $1
prepare() {
	echo "Output will be in ${ROOT}/${1}"
	mkdir -p ${ROOT}/$1/{results,stdout,chunks}
	# split the file per number of workers
	workers=`cat $OAR_NODE_FILE|uniq|sort`
	nb_workers=`cat $OAR_NODE_FILE|uniq|sort|wc -l`
	# do the split
	split ${ROOT}/workloads-tdsc/std.txt -n l/${nb_workers} ${ROOT}/$1/chunks/
	cat $OAR_NODE_FILE|uniq|sort > ${ROOT}/$1/nodes
	git -C ${ROOT}/scheduler rev-parse --short HEAD > ${ROOT}/$1/commit
	echo ${PARAMS} > ${ROOT}/$1/params
}

dispatch() {
	LABEL=$1
	workers=`cat $OAR_NODE_FILE|uniq|sort`
	arr=($workers)
	i=0
	for c in `ls ${ROOT}/${LABEL}/chunks/*`; do
		machine=${arr[$i]}
		i=$(($i + 1))
		chunk=`basename $c`
		echo "Execute chunk ${chunk} on ${machine}"
		cmd="source .profile; cd ${ROOT}/bench-g5k; nohup ./bench.sh -i ${ROOT}/${LABEL}/chunks/${chunk} -o ${ROOT}/${LABEL}/results/${chunk} -- ${PARAMS} &> ${ROOT}/${LABEL}/stdout/${chunk}"
		oarsh ${machine} ${cmd} &
	done;
}

#Show the solving process where $1 is the result directory
function progress() {
	count=`cat $1/chunks/*|wc -l`
	done=0
	while [ $done -lt $count ]; do
		sleep 5
		done=`cat $1/results/*/scheduler.csv|wc -l`
		echo "${done}/${count} done"
	done
}

#aggregates all the scheduler.csv. $1 is the LABEL
collect() {
    cat $1/results/*/scheduler.csv|$MINE/reformat.pl > $1/scheduler.csv
    $MINE/plot.R $1
}

#Copy the main results in $1 to another directory in $2
publish() {
	mkdir -p $2/$1
	cp $ROOT/$1/*.pdf $2/$1
	cp $ROOT/$1/*.png $2/$1
	cp $ROOT/$1/{params,commit,scheduler.csv} $2/$1
}

OPTIND=0
while getopts "w:c:l:p:h" opt; do
  	case $opt in
		h)
			usage
			exit 0
			;;
		p)
			PARAMS=$OPTARG;;
  		w)
			CLUSTER=$OPTARG;;
		c)
			COMMIT=$OPTARG;;
		l)
			MY_LABEL=$OPTARG;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
LABEL=${MY_LABEL:-$COMMIT}
if [ $# -gt 0 ]; then
	PARAMS=$*
fi

echo "root: ${ROOT}"
echo "label: ${LABEL}"
echo "commit: ${COMMIT}"
echo "args: ${PARAMS}"

echo "--- Fetching and compiling commit ${COMMIT} ---"
fetch ${COMMIT} || exit 1
echo "--- Prepare ${LABEL} ---"
prepare ${LABEL} || exit 1
echo "--- Run the bench ---"
dispatch ${LABEL} "${PARAMS}"|| exit 1
progress ${ROOT}/${LABEL}||exit 1
wait
echo "--- Bench done, collecting results ---"
collect $ROOT/${LABEL}|| exit 1
publish {LABEL} ${PUBLISH_DIR}|| exit 1
rm -rf $ROOT/${LABEL}|| exit 1
echo "Results published in ${PUBLISH_DIR}/${LABEL}"
