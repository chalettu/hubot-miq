
BotActions= require "../scripts/bot_actions"
module.exports =class assign_action extends BotActions
  constructor: (params, pr)  ->

    assignee=params.replace /\s/g, ""
    @assign_issue(pr,assignee)