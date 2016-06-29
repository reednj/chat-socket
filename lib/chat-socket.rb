
require 'cgi'
require './lib/websocket'
require './lib/models'

class ChatWebSocket < WebSocketHelper
	attr_accessor :username
	attr_accessor :room
	attr_accessor :chat_banned

	def initialize(ws, options = {})
		super(ws)
		@options = options || {}

		self.username = options[:username] || nil
		self.room = options[:room] || 'default'
		self.username = nil if self.username.empty?

		@rateWindow = SocketRateWindows.new
	end

	def on_open
		super
		log_action 'chat_connect'
		self.send_system_chat "#{chatting_count} chatting, #{connected_count-chatting_count} watching"
		self.send_counts
	end

	def on_close
		self.send_room_others 'countChanged', {
			:connected => connected_count - 1,
			:chatting => chatting_count - (can_chat? ? 1 : 0)
		}

		super
	end

	def on_chat(data)
		return unless can_chat?

		if @rateWindow.banned?
			if !self.chat_banned
				self.chat_banned = true
				self.on_user_banned @rateWindow.ban_length
			end

			return
		end

		data[:username] = self.username
		self.send_room 'chat', data
		log_action 'chat'

		self.chat_banned = @rateWindow.banned? 
		@rateWindow.inc
	end

	def on_user_banned(ban_length)
		self.send_system_chat 'you are doing that too fast. take a break for a minute'
		log_action 'chat_ban', :description => ban_length 
	end

	def chatting_count
		room_sockets.select{|s| s.can_chat? }.length
	end

	def connected_count
		room_sockets.length
	end

	def can_chat?
		!self.username.nil?
	end

	def room_sockets
		@sockets.select{|s| s.room == self.room }
	end

	def log_action(action_name, options={})
		options[:username] = self.username
		options[:thread_id] = self.room
		ActionLog.log action_name, options
	end

	def send_counts
		self.send_room 'countChanged', {
			:connected => connected_count,
			:chatting => chatting_count
		}
	end

	def send_system_chat(message)
		self.send 'chat', {
			:username => 'system',
			:content => message.to_s
		}
	end

	def send_room_others(event, data)
		EM.next_tick do
			room_sockets.each do |s|
				next if s == self
				s.send event, data
			end
		end
	end

	def send_room(event, data)
		EM.next_tick do
			room_sockets.each do |s|
				s.send event, data
			end
		end
	end
end

class SocketRateWindows
	attr_accessor :rate_windows
	attr_accessor :ban_length

	def initialize
		@ban_start = nil
		self.ban_length = 60.0

		self.rate_windows = [
			{ :window => 1.0, :limit => 3 },
			{ :window => 5.0, :limit => 7 },
			{ :window => 10.0, :limit => 10 },
			{ :window => 60.0, :limit => 30 }
		].map{|o| RateWindow.new o }
	end

	def inc
		self.rate_windows.each{ |r| r.inc }
		self.update_ban
	end

	def ok?
		self.rate_windows.all? {|r| r.ok? }
	end

	def banned?
		!ban_age.nil? && ban_age < self.ban_length 
	end

	def update_ban
		return if banned?
		@ban_start = Time.now if !ok?
	end

	def ban_age
		return nil if @ban_start.nil?
		Time.now - @ban_start
	end

end

class RateWindow
	def initialize(options = {})
		@window = options[:window].to_f || 60.0
		@limit = options[:limit].to_i || 100
		@count = 0
		@window_start = Time.now
	end

	def ok?
		# we are outside the window now, or the count is inside the 
		# limit
		(window_age > @window) || count <= @limit
	end

	def window_age
		Time.now - @window_start 
	end

	def in_window?
		ok?
	end

	def count
		@count
	end

	def increment
		if window_age > @window
			@count = 0
			@window_start = Time.now
		end

		@count += 1
	end

	def inc
		increment
	end
end
