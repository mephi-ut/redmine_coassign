require 'redmine'

module CoassignPlugin
	module IssuePatch
		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				def visible_condition_with_coassignees(user, options={})
					return visible_condition_without_coassignees(user, options)
				end

				alias_method_chain :visible?, :coassignees
				alias_method_chain :editable?, :coassignees

				class << self
					alias_method_chain :visible_condition, :coassignees
				end
			end
		end

		module ClassMethods
			def visible_condition_with_coassignees(user, options={})
				current_uid = (user || User.current).id

				issues = Issue.joins(:custom_values).where('custom_values.custom_field_id' => Setting.plugin_redmine_coassign['coassign_custom_field_id'].to_i, 'custom_values.value' => current_uid)

				return visible_condition_without_coassignees(user, options) unless issues.count > 0
				return "(" + visible_condition_without_coassignees(user, options) + ") OR (#{Issue.table_name}.id IN (#{issues.collect(&:id).join(',')}))"
			end
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

