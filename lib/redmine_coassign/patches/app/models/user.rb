module CoassignPlugin
	module UserPatch
		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				alias_method_chain :allowed_to?, :coassignees
			end
		end
		module ClassMethods
		end

		module InstanceMethods
			def allowed_to_with_coassignees?(action, context, options={}, &block)
				is_allowed = allowed_to_without_coassignees?(action, context, options, &block)
				return true if is_allowed

				return false unless context && context.is_a?(Project)

				if action.is_a?(Hash)
					return false unless action[:controller] == "issues"
					return false unless action[:action] == "index" || action[:action] == "show" || action[:action] == 'new'
				elsif action != :view_issues && action != :edit_issues
					#Rails.logger.info(action.to_yaml)
					#Rails.logger.info(context.to_yaml)
					return false
				end

				is_allowed = context.visible_due_coassignees_plugin?(User.current)

				#Rails.logger.info(is_allowed.to_yaml)
				return is_allowed
			end
		end
	end
end

Rails.configuration.to_prepare do
	User.send(:include, CoassignPlugin::UserPatch)
end

