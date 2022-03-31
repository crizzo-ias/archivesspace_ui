# sets up the AppConfig to conform to IAS's needs
AppConfig[:pui_hide][:repositories] = true
AppConfig[:pui_hide][:subjects] = false
AppConfig[:pui_hide][:agents] = true
AppConfig[:pui_hide][:accessions] = true
AppConfig[:pui_hide][:classifications] = false
AppConfig[:pui_branding_img] = '/assets/ias.png'
AppConfig[:pui_branding_img_alt_text] = 'Institute for Advanced Study'

## OVERRIDE VARIOUS METHODS/ ADD NEW METHODS
Rails.application.config.after_initialize do
     ##### BEGIN BLOCK TO FIX BUG IN ASPACE CORE #####
  # The code in this section is related to this issue in core ASpace: https://github.com/archivesspace/archivesspace/issues/2177
  # The issue has been resolved, but as of the 3.0.2RC on 8/9/21 has not made it into a release
  # When the commits listed in that issue have made it into the release that this plugin is running on
  # this code block can be removed

  module I18n
    def self.prioritize_plugins!
        self.load_path = self.load_path.reject { |p| p.match /plugins\// } + self.load_path.reject { |p| !p.match /plugins\// }
    end
  end

  I18n.prioritize_plugins!
  I18n.load_path = I18n.load_path.reject { |p| !p.match /frontend\// } + I18n.load_path.reject { |p| p.match /frontend\// }

  ##### END BLOCK TO FIX BUG IN ASPACE CORE #####

end
