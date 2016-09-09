fs = require('fs')
config = 'config.json'

module.exports = class BotActions
    repo:""
    constructor: (@name) ->
       
    standard_request:() ->
        standard_req= {
                    json: true,
                    method:"POST",
                    auth: {
                    user: "",
                    pass: ""
                    },
                    headers: {
                        'User-Agent': 'hubot-watch'
                    }
                }
        config_file = ->
            fs.readFileSync config, 'utf8'
        config_data=JSON.parse(config_file())
        @repo=config_data.repo
        standard_req.auth.user=config_data.git.user
        standard_req.auth.password=config_data.git.password

        return standard_req 