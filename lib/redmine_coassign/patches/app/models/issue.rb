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
				alias_method_chain :new_statuses_allowed_to, :coassignees

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

			def new_statuses_allowed_to_with_coassignees(user=User.current, include_default=false)
				statuses = new_statuses_allowed_to_without_coassignees(user, include_default)

				return statuses if new_record? && @copied_from
				return statuses if self.assigned_to_id == user.id
				return statuses unless self.is_coassignee?(user)

				initial_status = nil
				if new_record?
					initial_status = IssueStatus.default
				elsif status_id_was
					initial_status = IssueStatus.find_by_id(status_id_was)
				end
				initial_status ||= status

				#Rails.logger.info(statuses.to_yaml)

				statuses_additional = initial_status.find_new_statuses_allowed_to(
					user.roles_for_project(project),
					tracker,
					false,
					true
				)

				#Rails.logger.info(statuses_additional.to_yaml)

				statuses_additional << initial_status if statuses.empty? unless statuses_additional.empty?
				statuses_additional = statuses_additional.compact
				statuses_additional = blocked? ? statuses_additional.reject {|s| s.is_closed?} : statuses_additional

				statuses = statuses + statuses_additional
				statuses = statuses.uniq.sort

				#Rails.logger.info(statuses.to_yaml)

				return statuses
			end
		end
	end
end

Rails.configuration.to_prepare do
	Issue.send(:include, CoassignPlugin::IssuePatch)
end

