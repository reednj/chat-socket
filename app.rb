require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?

require 'sequel'
require 'json'
require 'haml'
require 'time'

require './config/app.config'
require './lib/extensions'
require './lib/chat-socket'
require './lib/models'

#use Rack::Deflater
set :git_path, development? ? './.git' : '/home/reednj/code/asteroids.git/.git'
set :version, GitVersion.current(settings.git_path)

configure :development do
	set :server, :thin
	set :port, 4568

	# need this to make it possible to debug the websockets, otherwise exceptions just get silently
	# swallowed
	Thread.abort_on_exception = true

	also_reload './lib/chat-socket.rb'
	also_reload './lib/models.rb'
end

configure :production do

end

# generic helpers - we could moe these out into their own file later
# to be shared with other projects
helpers do

	# basically the same as a regular halt, but it sends the message to the 
	# client with the content type 'text/plain'. This is important, because
	# the client error handlers look for that, and will display the message
	# if it is text/plain and short enough
	def halt_with_text(code, message = nil)
		code.is_a! Integer, 'code'
		message = message.to_s if !message.nil?
		halt code, {'Content-Type' => 'text/plain'}, message
	end

end

get '/chat/:room' do |room|
	return 'websockets only' if !request.websocket?

	username = params[:username]
	key = "com.reednj.jones.#{room}.#{username}".sha1
	halt_with_text 403, 'invalid key' if key != params[:key]

	request.websocket do |ws|
		ChatWebSocket.new ws,  { 
			:username => username,
			:room => room
		}
	end

end
