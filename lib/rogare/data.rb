# frozen_string_literal: true

module Rogare::Data
  class << self
    def users
      Rogare.sql[:users]
    end

    def novels
      Rogare.sql[:novels]
    end

    def user_from_discord(discu)
      users.where(discord_id: discu.id).first
    end

    # returns date user was last previously seen
    def user_seen(discu)
      nick = discu.nick || discu.username
      discordian = user_from_discord(discu)

      return new_user(discu)[:last_seen] unless discordian
      return discordian[:last_seen] unless Time.now - discordian[:last_seen] > 60 || discordian[:nick] != nick

      users.where(id: discordian[:id]).update(
        last_seen: Sequel.function(:now),
        nick: nick
      )

      Time.now
    end

    def new_user(discu, extra = {})
      defaults = {
        discord_id: discu.id,
        nick: discu.nick || discu.username,
        first_seen: Sequel.function(:now),
        last_seen: Sequel.function(:now)
      }

      id = users.insert(defaults.merge(extra))
      users.where(id: id).first
    end

    def get_nano_user(discu)
      user = user_from_discord discu
      (user && user[:nano_user]) || discu.nick || discu.username
    end

    def set_nano_user(discu, name)
      user = user_from_discord(discu)
      if user
        users.where(id: user[:id]).update(nano_user: name)
      else
        new_user(discu, nano_user: name)
      end
    end

    def all_nano_users
      users
        .distinct
        .select(:nano_user)
        .where { nano_user !~ nil }
        .map { |u| u[:nano_user] }
    end

    def current_novels(user)
      novels
        .where do
          (user_id =~ user[:id]) &
            (started <= Sequel.function(:now)) &
            (finished =~ false)
        end
        .reverse(:started)
    end

    def first_of(month)
      # Assume +1300. In November it will be right, otherwise it will be off but
      # in the right "direction" i.e. there won't be surprised 'but it IS month'
      DateTime.parse("#{Time.new.year}-#{month}-01 00:00:00 +1300").to_time
    end

    def ensure_novel(did)
      user = users.where(discord_id: did).first
      latest_novel = current_novels(user).first

      this_is_november = first_of(11) <= Time.new && Time.new < first_of(12)
      # We only assume and create a novel when it's november. If it's camp time,
      # we don't, and you'll have to tell us to make a new one if you want.

      if this_is_november
        if latest_novel.nil? || latest_novel[:started] < first_of(11)
          # This is nano, start a new novel!
          novels.insert(
            user_id: user[:id],
            started: first_of(11),
            type: 'nano'
          )
        end
      elsif latest_novel.nil?
        # No unfinished novels, start one now
        novels.insert(user_id: user[:id])
      end
    end
  end
end
