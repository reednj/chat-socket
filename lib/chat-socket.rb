
require 'cgi'
require './lib/websocket'
require './lib/models'

class ChatWebSocket < WebSocketHelper
	attr_accessor :username
	attr_accessor :room

	def initialize(ws, options = {})
		super(ws)
		@options = options || {}

		self.username = options[:username] || nil
		self.room = options[:room] || 'default'

		self.username = nil if self.username.empty?
	end

	def on_open
		super
		log_action 'chat_connect'
		self.send_system_chat "#{chatting_count} chatting, #{connected_count-chatting_count} watching"
	end

	def on_chat(data)
		return unless can_chat?
		data[:username] = self.username
		self.send_room 'chat', data
		log_action 'chat'
	end

	def chatting_count
		@sockets.select{|s| s.can_chat? }.length
	end

	def connected_count
		@sockets.length
	end

	def can_chat?
		!self.username.nil?
	end

	def log_action(action_name, options={})
		options[:username] = self.username
		options[:thread_id] = self.room
		ActionLog.log action_name, options
	end

	def send_system_chat(message)
		self.send 'chat', {
			:username => 'system',
			:content => message.to_s
		}
	end

	def send_room(event, data)
		EM.next_tick do
			@sockets.each do |s|
				next if s.room != self.room
				s.send event, data
			end
		end
	end
end