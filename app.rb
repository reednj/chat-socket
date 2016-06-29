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

#use Rack::Deflater
set :git_path, development? ? './.git' : '/home/reednj/code/asteroids.git/.git'
set :version, GitVersion.current(settings.git_path)

configure :development do
	set :server, :thin
	set :port, 4568

	# need this to make it possible to debug the websockets, otherwise exceptions just get silently
	# swallowed
	Thread.abort_on_exception = true
end

configure :production do
	set :facebook_app_id, '1716215681933302'

	# only log this on prod, as every flie change triggers it in development
	DB.ext.log_action 'app_startup', :description => settings.version
end

configure do
	# the models need to be initialized after the DB const is set, so do that now
	# it needs a separate connection, or it fucks up the normal entity queries for
	# some reason
	Sequel::Model.db = Sequel::Database.connect AppConfig.db
	require './lib/models'
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

get '/api/ws' do
	return 'websockets only' if !request.websocket?
	request.websocket do |ws|
		ChatWebSocket.new ws,  { }
	end

end
