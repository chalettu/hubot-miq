fs = require('fs')
config = 'config.json'
request = require('request')

module.exports = class BotActions
    repo:""
    repo_admin:""

    constructor: (@name) ->
       
    standard_request:() ->
        standard_req= {
                    json: true,
                    method:"POST",
                    auth: {
                    user: "",
                    password: ""
                    },
                    headers: {
                        'User-Agent': 'hubot-watch'
                    }
                }
        config_file = ->
            fs.readFileSync config, 'utf8'
        config_data=JSON.parse(config_file())
        @repo=config_data.repo
        @repo_admin=config_data.repo_administrator
        standard_req.auth.user=config_data.git.user
        standard_req.auth.password=config_data.git.password

        return standard_req 

    assign_issue:(pr,assignee) ->
        req_options = @standard_request()
        req_options.body = {"assignees":[assignee]}
                    
        req_options.url = "https://api.github.com/repos/"+@repo+"/issues/"+pr+"/assignees"
        @sleep(Math.random() * 1500)
        request req_options, (err,response,obj) ->
            throw err if err
            if obj.message
                console.log obj.message
            else
                console.log("Assignee was added successfully")
    post_status:(repo,status,commit_id) ->
        console.log repo
        req_options = @standard_request()
        req_options.url = "https://api.github.com/repos/"+@repo+"/statuses/"+commit_id
        req_options.body ={"state":status}
        
        @sleep(Math.random() * 1500)
        request req_options, (err,response,obj) ->
            throw err if err
            if obj.message
                console.log obj.message
            else
                console.log("Status was updated successfully")
    post_comment:(pr,comment) ->
        req_options = @standard_request()
        req_options.body = {"body":comment}
                    
        req_options.url = "https://api.github.com/repos/"+@repo+"/issues/"+pr+"/comments"
        @sleep(Math.random() * 1500)
        request req_options, (err,response,obj) ->
            throw err if err
            if obj.message
                console.log obj.message
            else
                console.log("Comment was made successfully")
    sleep:(ms) ->
        start = new Date().getTime()
        continue while new Date().getTime() - start < ms
        #this function was added to deal with API rate limiting