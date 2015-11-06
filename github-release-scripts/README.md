## GitHub script for releases

This is a script to update the milestone and label names across multiple repos
in the same way. It's main purpose is to rename i.e. a milestone
`8.1.5-current-maintenance` to `8.1.5`, `8.1.6-next-maintenance` to
`8.1.6-current-maintenance` and create a new one called `8.1.7-next-maintenance`.

The same applies for labels and it can also update due dates of milestones across multiple repos.

Whom to ask if something is unclear: [Morris Jobke](https://github.com/morrisjobke)

### How to run it

```
$ composer install
$ cp credentials.dist.json credentials.json
$ # add your GitHub API token to credentials.json
$ cp config.dist.json config.json
$ # configure the behaviour - see config section below
$ php releases.php
```

This will run the script in dry mode. To actually do the API call you need to uncomment one of the 6 `continue;` statements in `releases.php`. Each has a comment for which update call it is good for. As a hint: always just comment **one** of the 6 `continue`statements. The **rename** operations should always be executed **before** the **add** operations. So following order is recommended:

* run php releases.php & check output
* comment `continue` of rename of labels/milestone
* run php releases.php & check output
* uncomment `continue` of rename of labels/milestone
* comment `continue` of add of labels/milestone
* run php releases.php & check output

### Config

Note: The milestones and labels are in following format: X.Y.Z and an optional suffix (one of: `-current`, `-next`, `-current-maintenance`, `-next-maintenance`)


Open the file `config.json` and edit following values:

* `org`: this is the organisation or user that holds all the repos
* `repos`: a list of repos that should be updated at once
* `skipLabels`: a list of repos where the labels shouldn't get added/renamed/deleted - only milestones are updated
* `dueDates`: a list of key value pairs with a milestone as key and a date that then will be set as due date
* `renameLabels`: a list of key value pairs with the old label name as key and the new name as value
* `renameMilestones`: a list of key value pairs with the old milestone name as key and the new name as value
* `addLabels`: a list of labels that should be added
* `addMilestones`: a list of milestones that should be added
* `deleteLabels`: a list of labels that should be deleted
* `versionAdded`: a list of key value pairs with the repo as key and a version number as value. The labels/milestones are only applied (add/rename/delete) if the version of the label/milestone is bigger or equal then the specified version number.

An complete config for all ownCloud repos can be found at https://github.com/owncloud/enterprise/wiki/Github-Release-update-script-config
It's in there because only owners of the ownCloud GitHub orga should run this - if they know what they do ;).

