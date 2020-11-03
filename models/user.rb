# frozen_string_literal: true

class User < Sequel::Model
  plugin :timestamps, create: :first_seen, update: :updated, update_on_create: true, allow_manual_update: true

  one_to_many :projects
  one_to_many :suggestions, class: :Suggestion, key: :user_id
  one_to_many :war_memberships, class: :WarMember, key: :user_id
  many_to_many :wars, join_table: :wars_members, class: :War

  @discord = nil
  attr_accessor :discord

  def self.from_discord(discu)
    u = where(discord_id: discu.id).first
    return unless u

    u.discord = discu
    u
  end

  def self.create_from_discord(discu)
    u = from_discord discu
    return u if u

    u = create(discord_id: discu.id)
    u.discord = discu
    u
  end

  def seen!
    return self unless Time.now - last_seen > 60 || nick != discord_nick

    # keep same updated stamp unless we actually update something
    self.updated = updated unless nick != discord_nick
    self.last_seen = Time.now
    self.nick = discord_nick
    save

    self
  end

  def discord_nick
    (@discord.nick if @discord.is_a? Discordrb::Member) ||
      @discord.username ||
      '?'
  end

  def send_msg(message)
    @discord.pm message
  end

  def mid
    "<@#{discord_id}>"
  end

  def nixnotif
    Rogare.nixnotif nick
  end

  def timezone
    TimeZone.new tz
  end

  def date_in_tz(date)
    timezone.local date.year, date.month, date.day
  end

  def now
    timezone.now
  end

  def current_projects
    all_current_projects.where(participating: true)
  end

  def potential_projects
    all_current_projects.where(participating: false)
  end

  def all_current_projects
    projects_dataset
      .where do
        (start - concat('30 days').cast(:interval) < now.function) &
          (finish + concat('30 days').cast(:interval) > now.function)
      end
      .reverse(:start)
  end

  def nano_user_valid?
    Typhoeus.get("https://nanowrimo.org/participants/#{nano_user}").code == 200
  end

  def nano_today
    return unless nano_user

    res = Typhoeus.get "https://nanowrimo.org/participants/#{nano_user}/stats"
    return unless res.code == 200

    doc = Nokogiri::HTML res.body
    doc.at_css('#novel_stats .stat:nth-child(2) .value').content.gsub(/[,\s]/, '').to_i
  end

  def nano_count
    return unless nano_user

    res = Typhoeus.get "https://nanowrimo.org/wordcount_api/wc/#{nano_user}"
    return unless res.code == 200

    doc = Nokogiri::XML(res.body)
    return unless doc.css('error').empty?

    doc.at_css('user_wordcount').content.to_i
  end

  def latest_war
    # "Of all the valid wars of which I am a member, pick the latest one that's
    # either currently running, or has ended in the last 10 minutes,
    # or is starting in the next minute, preferring the ones that start later."
    war = wars_dataset.where do
      (cancelled =~ nil) & (
        (start + Sequel.cast(concat(seconds, ' secs'), :interval) >
          (now.function - Sequel.cast(concat(10, ' minutes'), :interval))) |
          ((started =~ false) & (start >
            (now.function - Sequel.cast(concat(1, ' minute'), :interval)))) |
          ((started =~ true) & (ended =~ false))
      )
    end.reverse(:start).first
    return [nil, nil] unless war

    # Then return the membership object too.
    [war, WarMember[war_id: war.id, user_id: id]]
  end

  def fetch_camps
    html = Typhoeus.get("https://campnanowrimo.org/campers/#{nano_user}/stats").body
    dom = Nokogiri::HTML.parse html
    dom.css('select#event_novel_slug option').map do |camp|
      { date: camp.text, slug: camp.attr('value') }
    end
  end
  
  def bot?
    @discord.bot_account?
  end
end
