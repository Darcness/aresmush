module AresMUSH
    module WoD5e
      def self.plugin_dir
        File.dirname(__FILE__)
      end
      
     def self.shortcuts
        Global.read_config("wod5e", "shortcuts")
      end
    end
  end