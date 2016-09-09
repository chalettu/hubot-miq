
BotActions= require "../scripts/bot_actions"
module.exports =class psl_action extends BotActions
  constructor: (params, pr)  ->

    #assignee=params.replace /\s/g, ""
    @post_comment(pr,"This isn't starbucks.  Ask your manager to order your a nice Pumpkin spice latte")