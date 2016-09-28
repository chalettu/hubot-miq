request = require('request')
fs = require('fs')
config = 'config.json'
{spawn, exec}  = require 'child_process'
BotActionsClass= require "./bot_actions"
BotBaseClass=new BotActionsClass()


botActions={}
for file in fs.readdirSync "bot_actions/" when file isnt 'index.coffee'
    filneame= file.replace /\.coffee$/, ""
   # filename= requiredFiles[file.replace /\.coffee$/, ""] 
    botActions[filneame]= require "../bot_actions/#{filneame}"

standard_req=BotBaseClass.standard_request()
repo=BotBaseClass.repo

module.exports = (robot) ->
  
  url           = require('url')
  querystring   = require('querystring')

  debug = true

  robot.router.post "/hubot/github-repo-listener", (req, res) ->
    try
      #if (debug)
       # robot.logger.info("Github post received: ", req)
      eventBody =
        type   : req.headers["x-github-event"]
        signature   : req.headers["X-Hub-Signature"]
        deliveryId  : req.headers["X-Github-Delivery"]
        payload     : req.body
        query       : querystring.parse(url.parse(req.url).query)

      #robot.emit "github-repo-event", eventBody
      handleEvent(eventBody)
    catch error
      robot.logger.error "Github repo webhook listener error: #{error.stack}. Request: #{req.body}"

    res.end ""
    #https://39a24c02.ngrok.io/hubot/github-repo-listener

handleEvent = (event) ->
  console.log event.type
 # console.log JSON.stringify(event.payload)
  switch event.type
    when "issue_comment"
      event_text=event.payload.comment.body
      pr=event.payload.issue.number
      bot_check(event_text,pr) 
    when "pull_request"
      pr=event.payload.pull_request
      if pr.state isnt 'closed'
        handle_pr(pr)
     # return "#{event.actor.login} #{event.payload.action} pull request ##{event.payload.pull_request.number}: #{event.payload.pull_request}"
    when "PushEvent"
      console.log JSON.stringify(event)
     
      pr={"base":{"sha":event.payload.before},"number":""}
      head_sha=event.payload.head
      pr.head={"sha":head_sha,"repo":{"html_url":"https://github.com/#{event.repo.name}"}}
      pr_req_options=standard_req
      pr_req_options.method="GET"
      pr_req_options.url="https://api.github.com/search/issues?q=#{head_sha}"

      request pr_req_options, (err,response,obj) ->
        throw err if err
        if obj.message
          console.log obj.message
        else
          pr.number=obj.items[0].number
          handle_pr(pr)
      
      return "#{event.actor.login} pushed to #{event.payload.ref.replace('refs/heads/','')}"
    else
      return "Cannot handle event type: #{event.type}"

bot_check = (comment,pr) ->
  bot_regex=/(@miq-bot)\s(\w*)\s(.*)/mg
  bot_matches=comment.match(bot_regex)
  if bot_matches=comment.match(bot_regex)
    console.log bot_matches
    if bot_matches.length > 1
      for bot in bot_matches
        handle_bot_action(bot,pr)
    else
      handle_bot_action(bot_matches[0],pr)
  else
    console.log("No bot found")
handle_bot_action=(bot_text,pr) ->
  parse_bot_cmd=bot_text.match(/(@miq-bot)\s(\w*)\s(.*)/)
  bot_action=parse_bot_cmd[2]
  bot_arguments=parse_bot_cmd[3]
  console.log("action is "+bot_action)
  console.log("arguments are "+bot_arguments)
      
  if botActions.hasOwnProperty(bot_action)
    executeBot= new botActions[bot_action](bot_arguments,pr)
  else
    console.log("Invalid bot action specified")

handle_pr=(pr) ->
  request_number=pr.number
  console.log "Handling PR"
  creds=standard_req.auth.user+":"+standard_req.auth.password
  repo_info={
    "commit_id":pr.head.sha,
    "master_commit_id":pr.base.sha,
    "creds":creds,
    "repo_url":pr.head.repo.html_url,
    "repo":repo
  }
  #at this point load the git pull functionality
  es_lint_class=require ("../code_linters/es_lint.coffee")
  code_linting= new es_lint_class(request_number,repo_info)
  