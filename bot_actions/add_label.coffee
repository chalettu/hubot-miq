request = require('request')
fs = require('fs')
BotActions= require "../scripts/bot_actions"

module.exports =class add_label_action extends BotActions
  constructor: (params, pr)  ->
    console.log "Constructor loaded"
    super()
    trimmed_labels=params.replace /\s/g, ""
    labels=trimmed_labels.split ","
    req_options = @standard_request()
    req_options.body = labels

    conf_file_name=__dirname.replace(/bot_actions/,'conf/auto_assign.json')
    config_file = ->
            fs.readFileSync conf_file_name, 'utf8'
    config_data=JSON.parse(config_file())
    assignees=[]
    for label in labels #This is the logic that figures out who to assign a ticket to
        #console.log label
        if config_data.hasOwnProperty(label)
            assignees.push(config_data[label])
    if assignees.length > 1
        ##SEnd comment to arbitrate assignees
        comment="Hey @"+@repo_admin+", figure out who needs to work on this issue"
        @post_comment(pr,comment)
    if assignees.length is 1
        @assign_issue(pr,assignees[0])

    req_options.url = "https://api.github.com/repos/"+@repo+"/issues/"+pr+"/labels"
  
    request req_options, (err,response,obj) ->
        throw err if err
        if obj.message
            console.log obj.message
        else
            console.log("labels were added successfully")
    #test case if only one is submitted
