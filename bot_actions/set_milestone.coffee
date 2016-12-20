request = require('request')
BotActions= require "../scripts/bot_actions"
module.exports =class set_milestone_action extends BotActions
    pr: ""
    assignMilestone: (milestone_id) ->
        milestone_req=@standard_request()
        milestone_req.method="PATCH" 
        milestone_req.url = "https://api.github.com/repos/"+@repo+"/issues/"+@pr
        milestone_req.body={"milestone":milestone_id}

        request milestone_req, (err,response,obj) ->
            console.log("Milestone added successfully")

    constructor: (params, pull_request)  ->
        super()
        mainObj=this
        @pr=pull_request
        req_options = @standard_request()
        milestone_name=params
        milestone_number=null
        req_options.method="GET"
        req_options.url = "https://api.github.com/repos/"+@repo+"/milestones"
        
        request req_options, (err,response,obj) ->
            throw err if err
            if obj.message
                console.log obj.message
            else
               # @testmethod()
                for milestone in obj
                    if milestone.title is milestone_name
                        milestone_number=milestone.number
                        mainObj.assignMilestone(milestone_number)

    