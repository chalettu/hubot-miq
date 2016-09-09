request = require('request')
BotActions= require "../scripts/bot_actions"
module.exports =class remove_label_action extends BotActions
  constructor: (params, pr)  ->
  
    trimmed_labels=params.replace /\s/g, ""
    label=trimmed_labels.split ","

    req_options = @standard_request()
    req_options.method = "DELETE"

    req_options.url = "https://api.github.com/repos/"+@repo+"/issues/"+pr+"/labels/"+label
    #console.log req_options
    request req_options, (err,response,obj) ->
        throw err if err
        if obj.message
            console.log obj.message
        else
            console.log("labels were removed successfully")
    #test case if only one is submitted
