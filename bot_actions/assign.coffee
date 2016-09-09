request = require('request')
BotActions= require "../scripts/bot_actions"
module.exports =class assign_action extends BotActions
  constructor: (params, pr)  ->

    assignee=params.replace /\s/g, ""
    req_options = @standard_request()
    req_options.body = {"assignees":[assignee]}
    
    req_options.url = "https://api.github.com/repos/"+@repo+"/issues/"+pr+"/assignees"
    console.log req_options
    request req_options, (err,response,obj) ->
        throw err if err
        if obj.message
            console.log obj.message
        else
            console.log("Assignee was added successfully")
