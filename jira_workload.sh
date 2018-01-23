#/bin/sh

PROJECT=$1
BOARD=$2
DATEFROM="$3T00:00:00.000+0200"
COOKIE=$4


STRATIO_JIRA_AGILE="https://stratio.atlassian.net/rest/agile/latest"
STRATIO_JIRA="https://stratio.atlassian.net/rest/api/latest"

function _get_from_jira_api() {
	echo $(_get_from_jira_intern $STRATIO_JIRA $1)
}
function _get_from_jira_agile() {
	echo $(_get_from_jira_intern $STRATIO_JIRA_AGILE $1)
}
function _get_from_jira_intern() {
    local path=$2
    local response=''
    local data=''
    local status_code=-1
    local jira=$1

    response=$(curl -H "cookie: $COOKIE" -fLs -w "\n%{response_code}\n" \
               "$jira/$path")


    data=$(echo "$response" |head -1 )
    status_code=$(echo "$response" | tail -1)
    if [[ $status_code == 200 ]];then
      echo "$status_code,$data"
      return 0
    fi

    echo "$status_code, error getting data from $path"
    return 1
}

function _get_sprint_issues() {
	# get board_id
	result=$(_get_from_jira_agile "board?projectKeyOrId=$PROJECT&name=$BOARD")
	IFS=',' read -r status_code boardjson <<< "$result"
	if [[ $status_code != 200 ]];then
		echo "$status_code"
              echo "Error reading issue"
	      exit 1
	fi
	board_id=$(echo "$boardjson" | jq -cMSr ".values | .[0] | .id")

	# get active sprint
	result=$(_get_from_jira_agile "board/$board_id/sprint?state=active")
	IFS=',' read -r status_code sprintjson <<< "$result"
	if [[ $status_code != 200 ]];then
              echo "Error getting active sprint"
	      exit 1
	fi
	sprint_id=$(echo "$sprintjson" | jq -cMSr ".values | .[0] | .id")

	# get active sprint issues
	result=$(_get_from_jira_agile "sprint/$sprint_id/issue")
	IFS=',' read -r status_code issuesjson <<< "$result"
	if [[ $status_code != 200 ]];then
              echo "Error getting issues"
	      exit 1
	fi

	echo "$status_code,$issuesjson"
}

# get sprint issues
result=$(_get_sprint_issues)
IFS=',' read -r status_code updated_issues_json <<< "$result"
if [[ $status_code != 200 ]];then
      echo "Error printing issues"
      exit 1
fi

echo "$updated_issues_json"

issues=$(echo "$updated_issues_json" | jq -cMSr ".issues | .[] " | jq -cMSr ".key")

#echo "$issues"

for issue in $issues; do
	# get workloads
	result=$(_get_from_jira_api "issue/$issue/worklog")
	IFS=',' read -r status_code workloads <<< "$result"
	if [[ $status_code != 200 ]];then
              echo "Error getting worklog"
	      exit 1
	fi

	worklogs=$(echo "$workloads" | jq -cMSr ".worklogs | .[] " | jq -cMSr "select (.updated > \"$DATEFROM\")" | jq -cMSr "{author: .author | .name,updated,timeSpent,issue:\"$issue\"}")

	if [[ $worklogs != "" ]];then
		echo "$worklogs"
	fi

done
