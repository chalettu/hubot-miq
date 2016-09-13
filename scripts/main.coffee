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
 
  watched = []
  watch_req_options = standard_req
  watch_req_options.method="GET"
  watch_req_options.url = "https://api.github.com/repos/#{repo}/events"
  
  request watch_req_options, (err,response,obj) ->
    throw err if err
    if obj.message
      console.log obj.message
     # res.send obj.message
    else
     watched[repo] = obj[0].id
     console.log(obj[0].id)
  
  setInterval ->
    for repo of watched
      watch_req_options.url = "https://api.github.com/repos/#{repo}/events"
     
      request watch_req_options, (err, response, obj) ->
        if obj[0].id != watched[repo]
          robot.send '',repo + ": " + handleEvent obj[0] unless process.env.HUBOT_WATCH_IGNORED and process.env.HUBOT_WATCH_IGNORED.indexOf(obj[0].type) isnt -1
          watched[repo] = obj[0].id
  ,5000

handleEvent = (event) ->
  console.log event.type
  switch event.type
    when "IssuesEvent"
      return "#{event.actor.login} #{event.payload.action} issue ##{event.payload.issue.number}: #{event.payload.issue.title}"
    when "IssueCommentEvent"
      event_text=event.payload.comment.body
      pr=event.payload.issue.number
      bot_check(event_text,pr) 
    when "PullRequestEvent"
      pr=event.payload.pull_request
      if pr.state isnt 'closed'
        handle_pr(pr)
      return "#{event.actor.login} #{event.payload.action} pull request ##{event.payload.pull_request.number}: #{event.payload.pull_request}"
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
  commit_id=pr.head.sha
  master_commit_id=pr.base.sha
  repo_url=pr.head.repo.html_url
  creds=standard_req.user+":"+standard_req.password
  #at this point load the git pull functionality
  s = spawn './git_pull.sh', [creds,repo,request_number]                        
  s.stdout.on 'data', ( data ) -> 
    
    rubocop_file = ->
      fs.readFileSync '/tmp/hubot_pull_requests/rubocop.json', 'utf8'
    comment_message="Checked commits "
    rubocop_data=JSON.parse(rubocop_file())
   
    comment_message+="[#{repo_url}/compare/#{master_commit_id}...#{commit_id}](#{repo_url}/compare/#{master_commit_id}...#{commit_id})"
    comment_message+=" with ruby "+rubocop_data.metadata.ruby_version+", rubocop "+rubocop_data.metadata.rubocop_version
    comment_message+="\n #{rubocop_data.summary.inspected_file_count} files checked, #{rubocop_data.summary.offense_count} offenses detected \n"
    if (rubocop_data.summary.offense_count > 0)
      file_messages=parse_rubocop_messages(rubocop_data.files,commit_id,repo_url)
      comment_message+=file_messages
    else
      comment_message+="Everything looks good :thumbsup:"
    req_options = BotBaseClass.standard_request()
    req_options.body = {"body":comment_message}
    req_options.method= "POST"
    req_options.url = "https://api.github.com/repos/"+repo+"/issues/"+request_number+"/comments"

    request req_options, (err,response,obj) ->
      throw err if err
      if obj.message
        console.log obj.message
      else
      console.log("Comment on ticket was successful")  

parse_rubocop_messages=(files,commit_id,repo_url) ->
  msg_text=""
  for ruby_file in files
    msg_text+="""
    \n :warning: **Path : #{ruby_file.path}** \n
    """
    for offense in ruby_file.offenses
      line=offense.location.line
      col=offense.location.column
      msg_text+="""
       [Line #{line}](#{repo_url}/blob/#{commit_id}/#{ruby_file.path}##{line}), Col #{col} - [#{offense.cop_name}](http://www.rubydoc.info/gems/rubocop/0.37.2/RuboCop/Cop/#{offense.cop_name}) - #{offense.message}\n
      """
  return msg_text