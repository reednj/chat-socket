
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

	def on_chat(data)
		return if self.username.nil?
		data[:username] = self.username
		self.send_room 'chat', data
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