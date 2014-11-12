require 'redmine'

require 'redmine_coassign/hooks/issues_controller.rb'
#require 'redmine_coassign/patches/app/controller/application_controller.rb'
require 'redmine_coassign/patches/app/models/issue.rb'
require 'redmine_coassign/patches/app/models/project.rb'
require 'redmine_coassign/patches/app/models/user.rb'
require 'redmine_coassign/patches/app/models/query.rb'

Redmine::Plugin.register :redmine_coassign do
	name 'Coassign plugin'
	author 'Dmitry Yu Okunev'
	description 'Plugin to make a coassign field from a custom field. (not production ready)'
	version '0.0.1'
	url 'https://github.com/mephi-ut/redmine_coassign'

	settings :default => {
			:coassign_custom_field_id	=> nil,
			:coassign_role_id		=> nil
		 },
		 :partial => 'settings/coassign'
end

