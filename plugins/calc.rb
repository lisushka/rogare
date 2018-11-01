class Rogare::Plugins::Calc
  include Cinch::Plugin
  extend Rogare::Plugin

  command 'calc'
  aliases '='
  usage '!% <a calculation>'
  handle_help

  match_command /.+/
  match_empty :help_message

  def execute(m, param)
    param.strip!
    res = Typhoeus.get 'https://api.wolframalpha.com/v2/query', params: {
      input: param,
      appid: ENV['WOLFRAM_KEY'],
      primary: 'true',
      format: 'plaintext'
    }

    doc = Nokogiri::XML.parse res.body
    pods = doc.css('queryresult pod')
    return m.reply 'No results ;(' if pods.nil? || pods.empty?

    pod0 = pods[0].at_css('subpod plaintext').content.strip
    pod1 = pods[1].at_css('subpod plaintext').content.strip
    return m.reply 'Mm, that didn’t work.' if pod0.nil?

    if pod1.lines.count > 2
      m.user.send "Calc results:\n#{pod0} =\n#{pod1}", true
    elsif pod0.length > 400
      m.user.send "#{pod0} = #{pod1}", true
    else
      m.reply "#{pod0} = #{pod1}"
    end
  end
end
