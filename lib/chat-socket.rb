
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
	end

	def on_open
		super
		log_action 'chat_connect'
		self.send_system_chat 'xx chatting, xx watching'
	end

	def on_chat(data)
		return if self.username.nil?
		data[:username] = self.username
		self.send_room 'chat', data
		log_action 'chat'
	end

	def log_action(action_name, options={})
		options[:username] = self.username
		options[:thread_id] = self.room
		ActionLog.log action_name, options
	end

	def send_system_chat(message)
		self.send_room 'chat', {
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