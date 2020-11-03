# frozen_string_literal: true

module Rogare::Command
  @@mine = {}

  def self.extended(base)
    logs "     > Loading #{base}"
  end

  def self.allmine
    @@mine
  end

  def my
    @@mine[inspect.to_sym] ||= {
      aliases: [],
      patterns: []
    }
  end

  def my=(val)
    @@mine[inspect.to_sym] = val
  end

  def command(comm, opts = {})
    opts[:hidden] || false
    my.merge!(opts)
    my[:command] = comm
  end

  def aliases(*aliases)
    my[:aliases] = aliases
  end

  def usage(message)
    my[:usage] = [message].flatten.compact
  end

  def before_handler(&block)
    my[:before_handler] = block
  end

  def handle_help
    match_command /help$/, method: :help_message
    h = my # Not useless! Will break if you remove
    define_method :help_message do |m|
      h[:usage][0] ||= 'No help message :('

      m.reply(h[:usage].map do |line|
        line.gsub('!%', "#{Rogare.prefix}#{h[:command]}")
      end.join("\n"))
    end
  end

  def match_message(pattern, opts = {})
    # We don't have the cinch framework to do work for us anymore, so to watch
    # multiple patterns there's two approaches. This one is to compile a single
    # pattern as they come in, and then re-match the event in priority order.
    # To compile the pattern, we remove the existing handler, add the new pattern
    # to the common pattern, re-add a handler. It's a bit messy but keeps from
    # adding boilerplate to the commands / removing dynamism.

    opts[:method] ||= :execute

    logs '       matching: ' + pattern.inspect
    my[:patterns] << [/^\s*#{Rogare.prefix}#{pattern}\s*$/m, opts]
    my[:common_pattern] = Regexp.union(my[:patterns].map { |pat| pat[0] })

    Rogare.discord.remove_handler my[:discord_handler] if my[:discord_handler]
    my[:discord_handler] = Rogare.discord.message(contains: my[:common_pattern]) do |event|
      message = event.message.content.strip
      server = event.channel.server
      chan = [server ? server.name : 'PM', event.channel.name].join '/'

      # add channel to logs
      logs "---> Discord message: ‘#{message}’ from #{event.author.username} (#{event.author.id}) in ##{chan}"
      logs "---> Handling by #{self}"

      pattern = my[:patterns].find { |pat| pat[0] =~ event.message.content }
      logs "---> Detected pattern: #{pattern[0]} (#{pattern[1]})"

      plug = new
      params = DiscordMessageShim.new(event, pattern, my).params
      meth = pattern[1][:method]
      
      if params[0].user.bot?
        logs 'Message author is a bot, skip'
        next
      end

      if my[:before_handler]
        logs 'Running before_handler'
        if my[:before_handler].call(meth, *params) == :stop
          logs 'before_handler says to stop'
          next
        end
      end

      arty = plug.method(meth).arity
      params = params.first(arty) if arty.positive?
      plug.send meth, *params
    end
  end

  def match_command(pattern = nil, opts = {})
    pattern = pattern.source if pattern.respond_to? :source
    excl = my[:help_includes_command] ? '' : '?:'
    pat = "(#{excl}#{[my[:command], *my[:aliases]].map { |c| Regexp.escape(c) }.join('|')})"
    pat = "#{pat}\\s+#{pattern}" if pattern
    match_message Regexp.new(pat, Regexp::IGNORECASE), opts
  end

  def match_empty(method, opts = {})
    opts[:method] ||= method
    match_command(nil, opts)
  end
end
