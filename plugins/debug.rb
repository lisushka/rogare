class Rogare::Plugins::Debug
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'debug', hidden: true
  handle_help

  match_command /chan name/, method: :chan_name
  match_command /chan find (.+)/, method: :chan_find
  match_command /war chans (.+)/, method: :war_chans
  match_command /war mems (.+)/, method: :war_mems
  match_empty :help_message

  def chan_name(m)
    m.reply m.channel.to_s
  end

  def chan_find(m, param)
    chan = Rogare.find_channel param.strip
    return m.reply 'No such chan' unless chan
    m.reply chan.name
  end

  def war_chans(m, param)
    redis = Rogare.redis(3)
    chans = redis.smembers "wordwar:#{param.strip}:channels"
    m.reply "`#{chans.inspect}`"

    chans.map! {|c| Rogare.find_channel c }
    m.reply "`#{chans.inspect}`"
  end

  def war_mems(m, param)
    redis = Rogare.redis(3)
    mems = redis.smembers "wordwar:#{param.strip}:members"
    m.reply "`#{mems.inspect}`"
  end
end
