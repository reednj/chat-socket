require 'ostruct'

AppConfig = OpenStruct.new({
	:db => {
		:adapter => 'mysql2',
		:user => 'linkuser',
		:password => '',
		:host => '127.0.0.1',
		:database => 'redditstream'
	}
})
