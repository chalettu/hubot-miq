{spawn, exec}  = require 'child_process'
BotActions= require "../scripts/bot_actions"
fs = require('fs')

module.exports =class rubocop extends BotActions
    constructor: (request_number,repo_info)  ->
        self=this
        repo=@repo
        s= spawn './git_pull.sh', [repo_info.creds,repo,request_number]                        
        s.stdout.on 'data', ( data ) -> 
            
            rubocop_file = ->
            fs.readFileSync '/tmp/hubot_pull_requests/rubocop.json', 'utf8'
            comment_message="Checked commits "
            rubocop_data=JSON.parse(rubocop_file())
        
            comment_message+="[#{repo_info.repo_url}/compare/#{repo_info.master_commit_id}...#{repo_info.commit_id}](#{repo_info.repo_url}/compare/#{repo_info.master_commit_id}...#{repo_info.commit_id})"
            comment_message+=" with ruby "+rubocop_data.metadata.ruby_version+", rubocop "+rubocop_data.metadata.rubocop_version
            comment_message+="\n #{rubocop_data.summary.inspected_file_count} files checked, #{rubocop_data.summary.offense_count} offenses detected \n"
            if (rubocop_data.summary.offense_count > 0)
                file_messages=parse_rubocop_messages(rubocop_data.files,commit_id,repo_url)
                comment_message+=file_messages
            else
                comment_message+="Everything looks good :thumbsup:"
            self.post_comment(request_number,comment_message)

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
  ###