module CoassignPlugin
	module ApplicationControllerPatch
		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				alias_method_chain :authorize, :coassign
			end
		end
		module ClassMethods
		end

		module InstanceMethods
			def authorize_with_coassign(ctrl = params[:controller], action = params[:action], global = false)
				if    (ctrl == "projects" && action == "show")
				elsif (ctrl == "issues"   && action == "show")
					if @issue.is_coassignee?(User.current)
						return true
					end
				end


				return authorize_without_coassign(ctrl, action, global)
			end
		end
	end
end

ApplicationController.send(:include, CoassignPlugin::ApplicationControllerPatch)
