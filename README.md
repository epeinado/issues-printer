# Issues Printer

Script for generating the cards to print for the Scrum or Kanban board.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine. Download the project and run the scripts.

### Prerequisites

- jq 1.5

```
$>sudo apt-get install jq
```

## Running the script

To print a Scrum board run the following script:
```
$>./jira_issues_scrum.sh <JIRA_PROJECT_KEY> <JIRA_BOARD_NAME> <COOKIE> 
```

To print a Kanban board or generate cards form a JQL run the following script:
```
$>./jira_issues_kanban.sh <JQL_OF_ASSOCIATED_FILTER> <COOKIE> 
```