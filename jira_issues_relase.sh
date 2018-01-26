#/bin/sh

PROJECT=$1
BOARD=$2
COOKIE=$3


STRATIO_JIRA="https://stratio.atlassian.net/rest/agile/latest"

function _get_from_jira() {
    local path=$1
    local response=''
    local data=''
    local status_code=-1

    response=$(curl -H "cookie: $COOKIE" -fLs -w "\n%{response_code}\n" \
               "$STRATIO_JIRA/$path")


    data=$(echo "$response" |head -1 )
    status_code=$(echo "$response" | tail -1)
    if [[ $status_code == 200 ]];then
      echo "$status_code,$data"
      return 0
    fi

    echo "$status_code, error getting data from $path"
    return 1
}

function _get_header_html() {
echo "<html>
<head>
<style>
@media all {
body{
 -webkit-print-color-adjust:exact;
}
table.card {
    height: 150px; width: 250px; border: 1px solid #62b6db; border-spacing: initial;
}
tr {
    background-color: #62b6db; border: 0px;
}
td {
    background-color: #FFFFFF; border: 0px;
}
tr.cardtop {
    height: 15%; border: 0px;
}
td.logo  {
    width: 40%; border: 0px solid powderblue; background-color: #62b6db; text-align: center; font-family: arial; font-weight: bold; font-style: normal; font-size: 18px; line-height: 18px; vertical-align: middle; 
}
td.header  {
    width: 12%; border: 0px solid powderblue; background-color: #62b6db; text-align: right; font-family: arial; font-weight: bold; font-style: normal; font-size: 14px; line-height: 18px; vertical-align: middle; 
}
td.key  {
    width: 48%; border: 0px solid powderblue; background-color: #62b6db; text-align: right; font-family: arial; font-weight: bold; font-style: normal; font-size: 16px; line-height: 18px; vertical-align: middle; color: #FFFFFF
}
tr.cardmiddle {
    height: 60%;
}
td.summary {
    border: 0px solid #62b6db; background-color: #FFFFFF; text-align: center; font-family: arial; font-style: normal; font-size: 22px; line-height: 22px; vertical-align: middle;
}
tr.cardbottom {
    height: 15%;
}
td.versiontype  {
    border: 0px solid #62b6db; text-align: left; font-family: arial; font-weight: bold; font-style: normal; font-size: 12px; vertical-align: middle;
}
td.version  {
    border: 0px solid #62b6db; text-align: left; font-family: arial; font-style: normal; font-size: 12px; vertical-align: middle;
}
td.version span {
  display: inline-block;
}
td.priority  {
    border: 0px solid #62b6db; text-align: left; font-family: arial; font-weight: bold; font-style: normal; font-size: 12px; vertical-align: middle; 
}
img.priority {
    margin-left:5px; margin-right:5px; height:18px; vertical-align:middle; 
}
td.storypoints  {
    border: 0px solid #62b6db; text-align: center; font-family: arial; font-weight: bold; font-style: normal; font-size: 18px; vertical-align: middle;
}
td.issuetype  {
    border: 0px solid #62b6db; text-align: left; font-family: arial; font-weight: bold; font-style: normal; font-size: 12px; line-height: 18px; vertical-align: middle;
}
img.issuetype {
    margin-left:5px; margin-right:5px; height:18px; vertical-align:middle; 
}
img.logo {
    height:15px; vertical-align:middle; margin: auto;
}
tr.cardbottomparent {
    height: 10%;
}
td.parent  {
    border: 0px solid #62b6db; text-align: center; font-family: arial; font-style: normal; font-size: 10px; line-height: 18px; vertical-align: bottom;
}


span {
    margin-left: 5px; margin-right: 5px; vertical-align:middle;
}

#container {
    display: flex;
    flex-wrap: wrap;
}

#container div {
   margin: 0px;
}
}
</style>
</head>

<body>
<div id='container'>"
}

function _get_footer_html() {
echo '</div></body>
</html>'
}

function _get_issue_html() {
    local issuejson=$1
    local id=$(echo "$issuejson" | jq -cMSr ".id")
    local key=$(echo "$issuejson" | jq -cMSr ".key")
    local summary=$(echo "$issuejson" | jq -cMSr ".summary")
    local SP=$(echo "$issuejson" | jq -cMSr ".SP")
    local issuetype=$(echo "$issuejson" | jq -cMSr ".type")
    local issuetypename=$(echo "$issuejson" | jq -cMSr ".typename")
    local priority=$(echo "$issuejson" | jq -cMSr ".priority")
    local priorityname=$(echo "$issuejson" | jq -cMSr ".priorityname")
    local estimate=$(echo "$issuejson" | jq -cMSr ".estimate")
    local parentkey=$(echo "$issuejson" | jq -cMSr ".parent")
    local fixversions=$(echo "$issuejson" | jq -cMSr '.fixVersions | .[] | .name | "<span>\(.)</span>"')
    local affectedversions=$(echo "$issuejson" | jq -cMSr '.affectedVersions | .[] | .name |  "<span>\(.)</span>"')
    local targetversions=$(echo "$issuejson" | jq -cMSr '.targetVersions | .[] | .name | "<span>\(.)</span>"')

# Discard subtasks
#if [[ "$issuetype" == "5" ]];then
#    echo "Issuetype!!!!! $issuetype"
#    return 1
#fi

# if SP is not set, get from estimation
if [[ "$SP" == "null" ]];then
	aux=$(expr $(expr $estimate + 14399) / 14400)
	SP=$(echo "scale=1;$aux / 2" | bc)
	# remove .0 decimal...
	if [[ "$SP" == *\.0 ]];then
		SP=$(expr $aux / 2)
        fi
fi
if [[ "$SP" == "0" ]];then
	SP=""	
fi
# if parentkey is not set, avoid print
if [[ "$parentkey" == "null" ]];then
	parentkey=""
fi

htmlissue="<div id='$id'>
  <table class=card>
    <tr class=cardtop >
      <td class=logo><img class='logo' src='./images/logo-stratio-white.png' /></td>
      <td class=header></td>
      <td class=key><span>$key</span></td>
    <tr class=cardmiddle>
      <td colspan=3 class='summary'><span>$summary</span></td>
    </tr>
    <tr class=cardbottomparent>
      <td></td>
      <td></td>
      <td class=parent>$parentkey</td>
    </tr>
    <tr class=cardbottom>
      <td class=priority><img class='priority' src='./images/priority/$priority.svg' />&nbsp;<img class='issuetype' src='./images/type/$issuetype.svg' /></td>
      <td class=storypoints><span class=storypoints>$SP</span></td>
    </tr>
    "

if [[ "$affectedversions" != "" ]];then
  htmlissue="$htmlissue <tr>
      <td class=versiontype>Affect:</td>
    </tr>
    <tr>
      <td class=version colspan=3>$affectedversions</td>
    </tr>" 
fi

if [[ "$fixversions" != "" ]];then
  htmlissue="$htmlissue <tr>
      <td class=versiontype>Fix:</td>
    </tr>
    <tr>
      <td class=version colspan=3>$fixversions</td>
    </tr>" 
fi

if [[ "$targetversions" != "" ]];then
  htmlissue="$htmlissue <tr>
      <td class=versiontype>Target:</td>
    </tr>
    <tr>
      <td class=version colspan=3>$targetversions</td>
    </tr>" 
fi

htmlissue="$htmlissue 
  </table>
</div>"

echo $htmlissue

}


# get board_id
result=$(_get_from_jira "board?projectKeyOrId=$PROJECT&name=$BOARD")
IFS=',' read -r status_code boardjson <<< "$result"
if [[ $status_code != 200 ]];then
      exit 1
fi
board_id=$(echo "$boardjson" | jq -cMSr ".values | .[0] | .id")
echo "BOARD ID: $board_id"


# get active sprint
result=$(_get_from_jira "board/$board_id/sprint?state=active")
IFS=',' read -r status_code sprintjson <<< "$result"
if [[ $status_code != 200 ]];then
      exit 1
fi
sprint_id=$(echo "$sprintjson" | jq -cMSr ".values | .[0] | .id")
echo "SPRINT_ID: $sprint_id"


# get active sprint issues
result=$(_get_from_jira "sprint/$sprint_id/issue")
IFS=',' read -r status_code issuesjson <<< "$result"
if [[ $status_code != 200 ]];then
      exit 1
fi

echo $issuesjson

issues=$(echo "$issuesjson" | jq -cMSr ".issues | .[] " | jq -cMSr "{id,key,summary: .fields | .summary,SP: .fields | .customfield_10004,type: .fields | .issuetype | .id,typename: .fields | .issuetype | .name,priority: .fields | .priority | .id,priorityname: .fields | .priority | .name,estimate: .fields | .timetracking | .originalEstimateSeconds,parent: .fields | .parent | .key,fixVersions: .fields | .fixVersions,affectedVersions: .fields | .versions,targetVersions: .fields | .customfield_10700 }")

# convert to HTML
rm ./output-$PROJECT-$BOARD.html
_get_header_html >> ./output-$PROJECT-$BOARD.html
IFS='
'
for issue in $issues; do
	issue_html=$(_get_issue_html $issue)
	echo "$issue_html" >> ./output-$PROJECT-$BOARD.html
done
_get_footer_html >> ./output-$PROJECT-$BOARD.html
