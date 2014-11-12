
module CoassignPlugin
	module QueryPatch
		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				alias_method_chain :available_filters, :coassignees
			end
		end

		module ClassMethods
		end

		module InstanceMethods
			def available_filters_with_coassignees
				return @available_filters if @available_filters

				available_filters_without_coassignees

				if User.current.logged?
					principals = []

					if project
						principals += project.principals.sort
						unless project.leaf?
							subprojects = project.descendants.visible.to_a
							principals += Principal.member_of(subprojects)
						end
						versions = project.shared_versions.to_a
						categories = project.issue_categories.to_a
						issue_custom_fields = project.all_issue_custom_fields
					else
						if all_projects.any?
							principals += Principal.member_of(all_projects)
						end
						versions = Version.visible.where(:sharing => 'system').to_a
						issue_custom_fields = IssueCustomField.where(:is_for_all => true)
					end
					principals.uniq!
					principals.sort!
					users = principals.select {|p| p.is_a?(User)}

					assigned_to_values = []
					assigned_to_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
					assigned_to_values += (Setting.issue_group_assignment? ?
						principals : users).collect{|s| [s.name, s.id.to_s] }

					@available_filters["assignee"] = {
						:name => l(:assignee_coassignee),
						:type => :list,
						:values => assigned_to_values
					}
				end

				@available_filters
			end

			def sql_for_assignee_field(field, operator, value)
				Rails.logger.info(value.to_yaml)

				uid = User.current.id
				if operator == '='
					op = '='
					inop = 'IN'
					whereop = 'OR'
				else
					op = '<>'
					inop = 'NOT IN'
					whereop = 'AND'
				end

				issues = Issue.joins(:custom_values).where('custom_values.custom_field_id' => Setting.plugin_redmine_coassign['coassign_custom_field_id'].to_i, 'custom_values.value' => uid)

				return "#{Issue.table_name}.assigned_to_id #{op} #{uid}" unless issues.count > 0
				return "(#{Issue.table_name}.assigned_to_id #{op} #{uid} #{whereop} #{Issue.table_name}.id #{inop} (#{issues.collect(&:id).join(',')}))"
			end

		end
	end
end

Rails.configuration.to_prepare do
	Query.send(:include, CoassignPlugin::QueryPatch)
end
