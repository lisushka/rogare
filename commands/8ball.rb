# frozen_string_literal: true

class Rogare::Commands::EightBall
  extend Rogare::Command

  command '8ball'
  usage '`!% <derp>`'
  handle_help

  match_command /(.+)/
  match_empty :help_message

  def execute(m, _param)
    m.reply [
      'It is certain.',
      'It is decidedly so.',
      'Without a doubt.',
      'Yes - definitely.',
      'You may rely on it.',
      'As I see it, yes.',
      'Most likely.',
      'Outlook good.',
      'Signs point to yes.',
      'Yes.',
      'Reply hazy, try again.',
      'Ask again later.',
      'Better not tell you now.',
      'Cannot predict now.',
      'Concentrate and ask again.',
      'Don\'t count on it.',
      'My reply is no.',
      'My sources say no.',
      'Outlook not so good.',
      'Very doubtful.'
    ].sample
  end
end
