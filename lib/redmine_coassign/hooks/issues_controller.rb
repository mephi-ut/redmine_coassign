# Hooks to attach to the Redmine Issues.

class CoassignPluginListener < Redmine::Hook::Listener
	def controller_issues_edit_before_save(context = {})
		issue = context[:issue]

		check_for_coassignees(issue)
	end

	def controller_issues_new_before_save(context = {})
		check_for_coassignees(context[:issue])
	end


	def controller_issues_bulk_edit_before_save(context = {})
		issue = context[:issue]

		check_for_coassignees(issue)
	end

	private
	def check_for_coassignees(issue)
		project = Project.find_by_id(issue['project_id'])
		if project.module_enabled?("auto_roles")
			role_id = project.custom_field_value(Setting.plugin_redmine_auto_role['autorole_custom_field_id'])
		end
		if role_id.nil?
			role_id = Setting.plugin_redmine_coassign['coassign_role_id']
		end
		unless role_id.nil? || role_id.empty? || role_id == '1'
			(issue.custom_field_value(Setting.plugin_redmine_coassign['coassign_custom_field_id'].to_i) || []).each do |uid_s|
				uid = uid_s.to_i
				user = User.find(uid)
				next if user.nil?

				member         = Member.new
				member.user    = User.find(user)
				member.project = project
				member.roles  += [Role.find(role_id)]
				member.save

				issue.add_watcher(user)
			end
		end
	end
end
