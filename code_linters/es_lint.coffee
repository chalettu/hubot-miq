{spawn, exec}  = require 'child_process'
BotActions= require "../scripts/bot_actions"
fs = require('fs')
eslint_version=""

module.exports =class es_lint extends BotActions
    constructor: (request_number,repo_info)  ->
        self=this
        repo=repo_info.repo
        shell_cmd = spawn 'node_modules/.bin/eslint',['-v']
        shell_cmd.stdout.on 'data', ( data ) -> 
            eslint_version=data.toString()
        s = spawn './git_pull.eslint.sh', [repo_info.creds,repo,request_number]
        s.stderr.on 'data', (data) ->
            console.log data.toString()
        s.on 'exit', (code) ->
            if code is 0                    
                eslint_file = ->
                    fs.readFileSync '/tmp/hubot_pull_requests/eslint_output.json', 'utf8'
                comment_message="Checked commits "
                
                eslint_data=JSON.parse(eslint_file())
                
                comment_message+="[#{repo_info.repo_url}/compare/#{repo_info.master_commit_id}...#{repo_info.commit_id}](#{repo_info.repo_url}/compare/#{repo_info.master_commit_id}...#{repo_info.commit_id})"
                comment_message+=" with eslint #{eslint_version}"
                # comment_message+="\n #{eslint_data.summary.inspected_file_count} files checked, #{eslint_data.summary.offense_count} offenses detected \n"
                #loop through get the count of errors and warnings
                error_count=0
                warning_count=0
                files_checked=eslint_data.length - 1
                for item in eslint_data
                    error_count+= item.errorCount
                    warning_count+= item.warningCount
                issues_count=error_count+warning_count - 1

                if (error_count > 0 or warning_count > 0)
                    comment_message+="\n #{files_checked} files checked, #{issues_count} offenses detected.\n"
                    comment_message+= self.parse_eslint_messages(eslint_data,repo_info.commit_id,repo_info.repo_url)
                    self.post_status(repo,'failure',repo_info.commit_id)
                else
                    comment_message+="Everything looks good :thumbsup:"
                    self.post_status(repo,'success',repo_info.commit_id)
            
            self.post_comment(request_number,comment_message)

    parse_eslint_messages: (files,commit_id,repo_url) ->
        msg_text=""
        for js_file in files
            file_path=js_file.filePath.replace(/^.+\/tmp\/hubot_pull_requests\/eslint/,'');
            if file_path.indexOf("eslintrc.json") is -1
                msg_text+="\n**#{file_path}** \n"

                for error in js_file.messages
                    emoji= switch
                        when error.severity==1 then ':grey_exclamation:'
                        when error.severity==2 then ':exclamation:'

                    line=error.line
                    col=error.column
                    msg_text+="""
                    - [ ] #{emoji} [Line #{line}](#{repo_url}/blob/#{commit_id}/#{file_path}#L#{line}), Col #{col} - [#{error.ruleId}](http://eslint.org/docs/rules/#{error.ruleId}) - #{error.message} \n
                    """

        return msg_text