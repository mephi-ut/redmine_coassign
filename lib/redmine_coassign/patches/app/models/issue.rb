require 'redmine'

module CoassignPlugin
	module IssuePatch
		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				alias_method_chain :visible?, :coassignees
				alias_method_chain :editable?, :coassignees
			end
		end

		module ClassMethods
		end

		module InstanceMethods
			def is_coassignee?(user=User.current)
				current_uid = (user || User.current).id

				(self.custom_field_value(Setting.plugin_redmine_coassign['coassign_custom_field_id'].to_i) || []).each do |uid_s|
					uid = uid_s.to_i
					return true if current_uid == uid
				end

				return false
			end

			def visible_with_coassignees?(user=User.current)
				visible = visible_without_coassignees?(user)
				return true if visible

				visible = is_coassignee?(user)
				return visible
			end

			def editable_with_coassignees?(user=User.current)
				editable = editable_without_coassignees?(user)
				return true if editable

				visible = is_coassignee?(user)
				return visible
			end
		end
	end
end

Rails.configuration.to_prepare do
	Issue.send(:include, CoassignPlugin::IssuePatch)
end

