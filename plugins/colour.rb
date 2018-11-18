# frozen_string_literal: true

COLOURS = [
  'silver',
  'gray',
  'white',
  'maroon',
  'red',
  'purple',
  'fuchsia',
  'green',
  'lime',
  'olive',
  'yellow',
  'navy',
  'blue',
  'teal',
  'aqua',
  'antique white',
  'aquamarine',
  'azure',
  'beige',
  'bisque',
  'blanched almond',
  'blue violet',
  'brown',
  'burlywood',
  'cadet blue',
  'chartreuse',
  'chocolate',
  'coral',
  'cornflower blue',
  'cornsilk',
  'crimson',
  'cyan',
  'aqua',
  'dark blue',
  'dark green',
  'dark grey',
  'dark khaki',
  'dark magenta',
  'dark orange',
  'dark red',
  'dark slate',
  'dark turquoise',
  'dark violet',
  'dark purple',
  'dark yellow',
  'deep pink',
  'hot pink',
  'deepsky blue',
  'dimgrey',
  'dodger blue',
  'firebrick',
  'floral white',
  'forest green',
  'gainsboro',
  'ghost white',
  'gold',
  'goldenrod',
  'green yellow',
  'yellow green',
  'grey',
  'honeydew',
  'hotpink',
  'indian red',
  'indigo',
  'ivory',
  'khaki',
  'lavender',
  'lavender blush',
  'lawn green',
  'lemon chiffon',
  'light blue',
  'light green',
  'light grey',
  'light pink',
  'light red',
  'light brown',
  'light yellow',
  'lime green',
  'linen',
  'magenta',
  'fuchsia',
  'midnight blue',
  'mint cream',
  'misty rose',
  'moccasin',
  'navajo white',
  'old lace',
  'olive drab',
  'orange red',
  'orchid',
  'pale goldenrod',
  'pale green',
  'pale turquoise',
  'pale violet red',
  'papaya whip',
  'peach puff',
  'peru',
  'pink',
  'plum',
  'powder blue',
  'rosy brown',
  'royal blue',
  'saddle brown',
  'salmon',
  'sandy brown',
  'seagreen',
  'seashell',
  'sienna',
  'sky blue',
  'slate blue',
  'slate grey',
  'snow',
  'spring green',
  'steel blue',
  'tan',
  'thistle',
  'tomato',
  'turquoise',
  'violet',
  'wheat',
  'whitesmoke',
  'yellowgreen',
  'rebecca purple',
  'orange',
  'aqua',
  'black'
].freeze

class Rogare::Plugins::Colour
  extend Rogare::Plugin

  command 'colour'
  aliases 'color'
  usage '`!% [amount]`'
  handle_help

  match_command /(\d+)/
  match_empty :execute

  def execute(m, param)
    param = param.strip.to_i
    param = 1 if param < 1
    param = 10 if param > 10

    m.reply COLOURS.sample(param).map { |c| Rogare::Data.ucname c }.join(', ')
  end
end
