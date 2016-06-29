
require 'cgi'
require './lib/websocket'
require './lib/models'

class ChatWebSocket < WebSocketHelper
	def initialize(ws, options = {})
		super(ws)
		@options = options || {}
	end
end