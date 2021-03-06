
require 'cgi'
require './lib/websocket'
require './lib/models'

class ChatHistory
	attr_accessor :room

	@@data = {}

	def initialize(room)
		self.room = room
	end

	def data
		@@data[room] ||= []
	end

	def add(username, content)
		msg = {
			:username => username,
			:content => content,
			:color => username.as_color,
			:created_date => Time.now
		}

		self.data.push msg
	end

end

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
		@history = ChatHistory.new self.room
	end

	def on_open
		super
		self.send_counts
		self.send_system_chat "#{chatting_count} chatting"
		
		if can_chat?
			self.send_room_others 'chat', {
				:username => 'system',
				:content => "#{self.username} just joined. say hi!"
			}

			self.send_history

			log_action 'chat_connect', :description => "#{chatting_count}/#{connected_count}"
		end
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
		data[:content] = data[:content].to_s.truncate(256)
		data[:color] = self.username.as_color

		self.send_room 'chat', data
		@history.add self.username, data[:content]
		log_action 'chat', :description => data[:content]

		self.chat_banned = @rateWindow.banned? 
		@rateWindow.inc
	end

	def on_user_banned(ban_length)
		self.send_system_chat 'you are doing that too much. take a break for a minute'
		log_action 'chat_ban', :description => ban_length 
	end

	def on_ping(data)
		self.send 'pong', data
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

	def send_history
		self.send 'history', @history.data.first(100)
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
