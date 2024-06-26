module AresMUSH
  module Scenes
    
    def self.create_log(enactor, scene)
      log = Scenes.build_log_text(scene)
      Scenes.add_log_version(scene, log, enactor)
      scene.scene_poses.each { |p| p.delete }  
    end
    
    def self.add_log_version(scene, log_text, enactor)
      old_log = scene.scene_log
      if (!old_log || (old_log.log != log_text))
        new_log = SceneLog.create(scene: scene, log: log_text, character: enactor)
        scene.update(scene_log: new_log)
      end
    end
    
    
    def self.build_log_text(scene)
      log = ""
      div_started = false
      scene.poses_in_order.to_a.each do |pose|
        next if pose.is_ooc
        
        if (pose.place_name)
          formatted_pose = "*At #{pose.place_name}*:\n#{pose.pose}"
        else
          formatted_pose = "#{pose.pose}"
        end
        formatted_pose = formatted_pose.gsub(/</, '&lt;').gsub(/(?<!^)>/, '&gt;').gsub(/%r/i, "\n").gsub(/%t/i, "  ")
                
                
        formatted_pose = formatted_pose.split("\n").map { |line| line.strip }.join("\n")
                
        if (pose.is_system_pose?)
          if (!div_started)
            log << "[[div class=\"scene-system-pose\"]]\n"
            div_started = true
          end
          log << formatted_pose
        elsif (pose.is_setpose?)
          if (div_started)
            log << "\n[[/div]]\n\n"
            div_started = false
          end
          log << "[[div class=\"scene-set-pose\"]]\n#{formatted_pose}\n[[/div]]\n\n"
        else
          if (div_started)
            log << "\n[[/div]]\n\n"
            div_started = false
          end
          log << formatted_pose
        end
        
        if (!div_started)
          if (Global.read_config("scenes", "include_pose_separator"))
            log << "\n[[div class=\"pose-divider\"]][[/div]]\n"
          end
        end
        
        log << "\n\n"
      end
      
      if (div_started)
        log << "\n[[/div]]\n\n"
      end
      
      log
    end
    
  end
end