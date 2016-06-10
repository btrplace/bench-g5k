#!/bin/bash
MINE=`dirname $0`
source ${MINE}/env.sh

COMMIT="master"
ARGS="-t 60 -r -v 1"

#Get the code at commit $1 and install it
fetch () {
	git -C ${ROOT}/scheduler pull
	git ${ROOT}/scheduler checkout $1||exit 1
	mvn -f ${ROOT}/scheduler -q install -DskipTests -Dgpg.skip||exit 1
}

#Create the output directory in $1
prepare () {
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
		cmd="source .profile; cd ${ROOT}/bench-g5k; nohup ./bench.sh ${LABEL}/chunks/${chunk} ${LABEL}/results/${chunk} 2>&1 > ${LABEL}/stdout/${chunk}"
		oarsh ${machine} ${cmd} &
	done;
	echo "Waiting for termination"
	wait
}

#aggregates all the scheduler.csv. $1 is the LABEL
collect() {
    cat $1/results/*/scheduler.csv|./reformat.pl > $1/scheduler.csv
	./plot.R $1
}

#Copy the main results in $1 to another directory in $2
publish() {
	mkdir -p $2/$1
	cp -r $1/{*.pdf, *.png, env, commit, scheduler.csv} $2/$1
}

#Clean the temporary produced files in $1
clean() {
	rm -rf $1/{chunks,results,stdout}
}

OPTIND=0
while getopts "w:c:l:p:" opt; do
  case $opt in
		p)
			PARAMS=$OPTARG;;
  		w)
			CLUSTER=$OPTARG;;
		c)
			COMMIT="$OPTARG";;
		l)
			MY_LABEL="$OPTARG";;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
esac
done

LABEL=${MY_LABEL:-$COMMIT}
shift "$((OPTIND-1))"
if [[ $1 = "--" ]]; then
	shift
	ARGS=("$@")
fi

echo "label: ${LABEL}\ncommit: ${COMMIT}\nargs: ${ARGS}"
echo "--- Fetching and compiling commit ${COMMIT} ---"
fetch ${COMMIT} || exit 1
echo "--- Prepare ${LABEL} ---"
prepare ${LABEL} || exit 1
echo "--- Run the bench ---"
dispatch ${LABEL} "${PARAMS}"|| exit 1
collect ${LABEL}|| exit 1
echo "--- publish the results in `readlink ~/public/` ---"
publish ${LABEL} ~/public/|| exit 1
echo "--- Cleaning the environment ---"
clean ${LABEL}|| exit 1
echo "Job done. Results available in the public directory of the site"