require_dependency 'user'

module CoassignPlugin
	module ProjectPatch
		class << Project
			def visible_condition_with_coassignees(user=User.current, options={})
				current_uid = (user || User.current).id
				issues = Issue.joins(:custom_values).where('custom_values.custom_field_id' => Setting.plugin_redmine_coassign['coassign_custom_field_id'].to_i, 'custom_values.value' => current_uid)
				return visible_condition_without_coassignees(user, options) + (issues.count == 0 ? '' : " OR #{Project.table_name}.id IN (#{issues.all.collect(&:project_id).join(",")})")
			end
			alias_method_chain :visible_condition, :coassignees

		end

		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				def visible_due_coassignees_plugin?(user)
					current_uid = (user || User.current).id

					issues = Issue.joins(:custom_values).where('custom_values.custom_field_id' => Setting.plugin_redmine_coassign['coassign_custom_field_id'].to_i, 'custom_values.value' => current_uid, :project_id => self.id)
					return true if issues.count > 0

					return false
				end

				def visible_with_coassignees?(user=User.current)
					visible = visible_without_coassignees?(user)
					return true if visible

					return visible_due_coassignees?(user)
				end
				alias_method_chain :visible?, :coassignees
			end
		end
		module ClassMethods
		end

		module InstanceMethods
		end
	end
end

Rails.configuration.to_prepare do
	Project.send(:include, CoassignPlugin::ProjectPatch)
end

