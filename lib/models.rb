require 'sequel'
require './config/app.config'

DB = Sequel::Database.connect AppConfig.db

class ActionLogNotes < Sequel::Model(:action_log_notes)
	many_to_one :action_log, :key => :action_id
end

class ActionLog < Sequel::Model(:action_log)
	one_to_many :notes, :class => ActionLogNotes, :key => :action_id
	many_to_one :user, :class => 'Users', :key => :user_id

	def self.new_with_name(action_name, description = nil)
		self.new { |a|
			a.action_name = action_name
			a.action_desc = description
		}
	end

	dataset_module do

		def with_name(n)
			where(:action_name => n)
		end

		def today
			since(1.day.ago)
		end

		def since(t)
			where("action_log.created_date > ?", t)
		end
	end

	def notes?
		self.notes.length > 0
	end

	def notes_hash
		result = {}
		self.notes.each { |n| result[n.field_id] = n.field_value }
		return result
	end

	def username_or_id
		self.user.nil? ? self.user_id : self.user.username
	end

	def description
		action_desc
	end

end


DB.disconnect
