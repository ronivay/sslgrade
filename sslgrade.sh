#/bin/bash

DOMAIN="$1"

if [[ $# == "0" ]]; then
        echo "Usage $(dirname $0)/$(basename $0) domain.tld"
        exit 0
fi

function DependencyCheck {

if [[ -z $(which curl) ]]; then
	echo "This script requires curl"
	exit 0
fi

if [[ -z $(which jq) ]]; then
	echo "This script require jq"
	exit 0
fi

}

function TestCheck {

local STATUS=$(curl -s "https://api.ssllabs.com/api/v3/analyze?host=$DOMAIN&publish=off&analyze" | jq ".endpoints[0].statusMessage" 2>/dev/null | sed 's/\"//g' 2>/dev/null)

if [[ "$STATUS" == "In progress" ]]; then
	echo "There's a test In progress"
	echo
	WaitForTest
elif [[ "$STATUS" == "Ready" ]]; then
	echo "There's existing fresh result"
	echo "Start new test anyway?"
	read -p "[y/N] " answer
	answer=${answer:-n}
		case $answer in
		
		y)
		StartTest
		WaitForTest
		TestResultPrint
		exit 0
		;;
		n)
		TestResultPrint
		exit 0
		;;
	esac
else
	StartTest
	WaitForTest
	TestResultPrint
fi

}

function StartTest {

	echo 
	echo "Calling API to start test"
	echo "API reply:"
	sleep 3
	curl -s "https://api.ssllabs.com/api/v3/analyze?host=$DOMAIN&publish=off&analyze&startNew=on&ignoreMismatch=on"
	echo
}
	

function WaitForTest {

	sleep 5
	local STATUS=$(curl -s "https://api.ssllabs.com/api/v3/analyze?host=$DOMAIN&publish=off&analyze")
	local PROGRESS=$(echo "$STATUS" | jq ".endpoints[0].statusMessage" 2>/dev/null | sed 's/\"//g' 2>/dev/null)

	if [[ $(echo "$STATUS" | jq ".status") =~ "ERROR" ]] || [[ $(echo "$STATUS" | jq ".errors") != "null" ]]; then
		echo 
		echo "Error initializing test"
		echo "API reply:"
		echo "$STATUS"
		exit 1
	fi
	
	echo "Waiting for test to finish"
	while [[ "$PROGRESS" != "Ready" ]]; do
		sleep 3
		local STATUS=$(curl -s "https://api.ssllabs.com/api/v3/analyze?host=$DOMAIN&publish=off&analyze")
		local PERCENTAGE=$(echo "$STATUS" | jq ".endpoints[0].progress" 2>/dev/null | sed 's/\"//g' 2>/dev/null | sed 's/-1/0/' 2>/dev/null | sed 's/null/0/' 2>/dev/null)
		local TEST=$(echo "$STATUS" | jq ".endpoints[0].statusDetailsMessage" 2>/dev/null | sed 's/\"//g' 2>/dev/null)
		echo -ne "\r$PERCENTAGE%"
		local PROGRESS=$(echo "$STATUS" | jq ".endpoints[0].statusMessage" 2>/dev/null | sed 's/\"//g' 2>/dev/null)
	done
		echo
}

function TestResultPrint {

		local RESULT=$(curl -s "https://api.ssllabs.com/api/v3/analyze?host=$DOMAIN&publish=off&analyze")
                local GRADE=$(echo "$RESULT" | jq ".endpoints[0].grade" | sed 's/\"//g')
                local WARNINGS=$(echo "$RESULT" | jq ".endpoints[0].hasWarnings")
		local IPADDRESS=$(echo "$RESULT" | jq ".endpoints[0].ipAddress" | sed 's/\"//g')
		local DETAILS=$(curl -s "https://api.ssllabs.com/api/v3/getEndpointData?host=$DOMAIN&s=$IPADDRESS")
		local CERTCHAIN=$(echo "$DETAILS" | jq ".details.certChains[0].issues" | sed 's/\"//g')
		local PROTOCOLS=$(echo "$DETAILS" | jq ".details.protocols[].version" | sed 's/\"//g' | tr '\n' ' ')

		echo "https://api.dev.ssllabs.com/api/v2/getEndpointData?host=$DOMAIN&s=$IPADDRESS"

		echo
                echo "SSL Labs test results for $DOMAIN"
                echo "Grade: $GRADE"
                echo "Warnings: "$WARNINGS""
		echo
		echo -n "Issues in certificate chain: "
		if [[ $CERTCHAIN == "0" ]]; then
			echo "none"
		elif [[ $CERTCHAIN == "2" ]]; then
			echo "incomplete chain"
		elif [[ $CERTCHAIN == "4" ]]; then
			echo "chain contains unrelated or duplicate certificates"
		elif [[ $CERTCHAIN == "8" ]]; then
			echo "the certificates form a chain (trusted or not), but the order is incorrect"
		elif [[ $CERTCHAIN == "16" ]]; then
			echo "contains a self-signed root certificate"
		elif [[ $CERTCHAIN == "32" ]]; then
			echo "the certificates form a chain, but we could not validate it"
		fi
		echo "Supported TLS/SSL protocols: "$PROTOCOLS""
		
                echo
                echo "See full report at https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN&fromCache=on"

}

DependencyCheck
TestCheck
