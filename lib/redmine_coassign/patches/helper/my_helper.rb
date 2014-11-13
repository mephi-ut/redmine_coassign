
module CoassignPlugin
	module MyHelperPatch
		def self.included(base)
			base.extend(ClassMethods)
			base.send(:include, InstanceMethods)
			base.class_eval do
				unloadable

				alias_method_chain :issuesassignedtome_items, :coassignees
			end
		end

		module ClassMethods
		end

		module InstanceMethods
			def issuesassignedtome_items_with_coassignees
				issuesassignedtome_items_without_coassignees
			end
		end
	end
end

Rails.configuration.to_prepare do
	MyHelper.send(:include, CoassignPlugin::MyHelperPatch)
end

