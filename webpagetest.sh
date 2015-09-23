#!/bin/bash
WPTKEY="${1}"
SITES=$(if [ -n "${2}" ]
then 
	for site in "${2}"
	do 
		echo -n "configs/eb/${site} "
	done
else
	echo "configs/eb/*"
fi
)

LOCATION="Dulles:Chrome"
M_PARAMS="location=${LOCATION}.3GFast&mobile=1"
D_PARAMS="location=${LOCATION}.Cable&mobile=0"
TEST_PATH=${TEST_PATH:-/}
echo "Running test for ${SITES}"
FILENAME="testlog-$(date "+%Y-%m-%d:%H:%M:%S").log"

# create a script suitable for webpagetest to change the CNAME for the test domain
function make_script {
	echo "setDnsName%09${BACKEND}%09${SERVER_NAME}%0anavigate%09http://${BACKEND}${TEST_PATH}"
}

echo "Warming up servers: "
for file in ${SITES}
do 
	eval $(cat ${file}) 
	curl -s -I "http://www.webpagetest.org/runtest.php?script=$(make_script)&runs=1&fvonly=1&video=0&${M_PARAMS}&k=${WPTKEY}" -o /dev/null
	curl -s -I "http://www.webpagetest.org/runtest.php?url=http://${BACKEND}${TEST_PATH}&runs=1&fvonly=1&video=0&${M_PARAMS}&k=${WPTKEY}"  -o /dev/null
	curl -s -I "http://www.webpagetest.org/runtest.php?script=$(make_script)&runs=1&fvonly=1&video=0&${D_PARAMS}&k=${WPTKEY}" -o /dev/null
	curl -s -I "http://www.webpagetest.org/runtest.php?url=http://${BACKEND}${TEST_PATH}&runs=1&fvonly=1&video=0&${D_PARAMS}&k=${WPTKEY}"  -o /dev/null
	echo -e "\t${SERVER_NAME} -> ${BACKEND}" 
done 
echo -n "Cooling off for 90 seconds "
for s in {1..18}
do 
	echo -n "."
	sleep 5
done
echo -e " Done!\n"
echo -n "Warming up (again)"
for file in ${SITES}
do 
	eval $(cat ${file}) 
	curl -s -I "http://www.webpagetest.org/runtest.php?script=$(make_script)&runs=1&fvonly=1&video=0&${M_PARAMS}&k=${WPTKEY}" -o /dev/null
	curl -s -I "http://www.webpagetest.org/runtest.php?script=$(make_script)&runs=1&fvonly=1&video=0&${D_PARAMS}&k=${WPTKEY}" -o /dev/null
done 
for s in {1..6}
do 
	echo -n "."
	sleep 5
done
echo -e "\nRunning"
for file in ${SITES}
do 
	eval $(cat ${file}); 
	a=$(curl -s -I "http://www.webpagetest.org/runtest.php?label=${BACKEND}+turbo&script=$(make_script)&runs=1&fvonly=1&video=1&${M_PARAMS}&k=${WPTKEY}" | grep Location | awk '{print $2}' | cut -d '/' -f  5); 
	b=$(curl -s -I "http://www.webpagetest.org/runtest.php?label=${BACKEND}+vanilla&url=http://${BACKEND}${TEST_PATH}&runs=1&fvonly=1&video=1&${M_PARAMS}&k=${WPTKEY}" | grep Location | awk '{print $2}' | cut -d '/' -f  5); 
	c=$(curl -s -I "http://www.webpagetest.org/runtest.php?label=${BACKEND}+turbo&script=$(make_script)&runs=1&fvonly=1&video=1&${D_PARAMS}&k=${WPTKEY}" | grep Location | awk '{print $2}' | cut -d '/' -f  5); 
	d=$(curl -s -I "http://www.webpagetest.org/runtest.php?label=${BACKEND}+vanilla&url=http://${BACKEND}${TEST_PATH}&runs=1&fvonly=1&video=1&${D_PARAMS}&k=${WPTKEY}" | grep Location | awk '{print $2}' | cut -d '/' -f  5); 
	echo "http://www.webpagetest.org/video/compare.php?tests=${a},${b}" | tee -a ${FILENAME}
	echo "http://www.webpagetest.org/video/compare.php?tests=${c},${d}" | tee -a ${FILENAME}
done 
echo  "Done, see results in ${FILENAME}"
cat  ${FILENAME} | xargs open