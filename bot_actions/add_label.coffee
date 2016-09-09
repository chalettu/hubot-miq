request = require('request')
BotActions= require "../scripts/bot_actions"
module.exports =class add_label_action extends BotActions
  constructor: (params, pr)  ->
    console.log "Constructor loaded"
    trimmed_labels=params.replace /\s/g, ""
    labels=trimmed_labels.split ","
    console.log(params)
    req_options = @standard_request()
    req_options.body = labels
 
    #



    req_options.url = "https://api.github.com/repos/"+@repo+"/issues/"+pr+"/labels"
    console.log req_options
    request req_options, (err,response,obj) ->
        throw err if err
        if obj.message
            console.log obj.message
        else
            console.log("labels were added successfully")
    #test case if only one is submitted
