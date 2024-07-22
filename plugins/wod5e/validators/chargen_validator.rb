# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Validates Chargen Values
    class ChargenValidator
      def self.can_approve?(actor)
        can_manage_apps?(actor)
      end

      def self.bg_app_review(char)
        message = t('chargen.ok')
        max_length = Global.read_config('chargen', 'max_bg_length') || 0

        if char.background.blank?
          message = t('chargen.not_set')
        elsif max_length > 0 && char.background.length > max_length
          message = t('chargen.bg_too_long', total: char.background.length, max: max_length)
        end

        Chargen.format_review_status t('chargen.background_review'), message
      end

      def self.can_manage_bgs?(actor)
        return false unless actor

        actor.has_permission?('manage_apps')
      end

      def self.can_manage_apps?(actor)
        return false unless actor

        actor.has_permission?('manage_apps')
      end

      def self.can_view_bgs?(actor)
        return false unless actor

        can_manage_bgs?(actor) || actor.has_permission?('view_bgs')
      end

      def self.check_can_edit_bg(actor, model)
        return t('chargen.cannot_edit_bg') unless actor
        return t('chargen.cannot_edit_bg') if actor != model && !can_manage_bgs?(actor)

        return t('chargen.cannot_edit_after_approval') if model.is_approved? && !can_manage_bgs?(actor)

        nil
      end

      def self.unsubmit_app(char)
        char.update(chargen_locked: false)

        job = char.approval_job
        return unless job

        Jobs.change_job_status(char, job, Global.read_config('chargen', 'app_hold_status'), t('chargen.app_job_unsubmitted'))
      end

      def self.read_tutorial(name)
        filename = File.join(File.dirname(__FILE__), 'templates', name)
        File.read(filename, encoding: 'UTF-8')
      end

      def self.stages
        Global.read_config('chargen', 'stages')
      end

      def self.stage_name(char)
        stage = char.chargen_stage
        stage ? stages.keys[stage] : nil
      end

      def self.save_char(char, chargen_data)
        alerts = []

        errors = Profile::CustomCharFields.save_fields_from_chargen(char, chargen_data) || []
        alerts.concat errors if errors.instance_of?(Array) && errors.any?

        alerts
      end

      def self.approve_char(enactor, model, notes)
        return t('chargen.already_approved', name: model.name) if model.is_approved?

        job = model.approval_job

        if job
          Jobs.close_job(enactor, job, "#{Global.read_config('chargen', 'approval_message')}%R%R#{notes}")
        else
          return t('chargen.no_app_submitted', name: model.name) unless model.on_roster? || model.is_npc?
        end

        Roles.add_role(model, 'approved')
        model.update(approval_job: nil)
        model.update(approved_at: Time.now)

        unless model.on_roster? || model.is_npc?
          Achievements.award_achievement(model, 'created_character')

          arrivals_category = Global.read_config('chargen', 'arrivals_category')
          unless arrivals_category.blank?
            welcome_message = Global.read_config('chargen', 'welcome_message')
            welcome_message_args = Chargen.welcome_message_args(model)
            post_body = welcome_message % welcome_message_args

            Forum.system_post(
              arrivals_category,
              t('chargen.approval_post_subject', name: model.name),
              post_body
            )
          end
        end

        post_approval_msg = Global.read_config('chargen', 'post_approval_message')
        unless post_approval_msg.blank?
          Jobs.create_job(Global.read_config('chargen', 'app_category'),
                          t('chargen.approval_post_subject', name: model.name),
                          post_approval_msg,
                          Game.master.system_character)
        end

        Chargen.custom_approval(model)

        Global.dispatcher.queue_event CharApprovedEvent.new(Login.find_client(model), model.id)

        nil
      end

      def self.reject_char(enactor, model, notes)
        return t('chargen.already_approved', name: model.name) if model.is_approved?

        job = model.approval_job
        return t('chargen.no_app_submitted', name: model.name) unless job

        model.update(chargen_locked: false)

        Jobs.change_job_status(enactor,
                               job,
                               Global.read_config('chargen', 'app_hold_status'),
                               "#{Global.read_config('chargen', 'rejection_message')}%R%R#{notes}")

        nil
      end

      def self.build_app_review_info(char, enactor)
        abilities_app = FS3Skills.is_enabled? ? MushFormatter.format(FS3Skills.app_review(char)) : nil
        demographics_app = MushFormatter.format Demographics.app_review(char)
        bg_app = MushFormatter.format Chargen.bg_app_review(char)
        desc_app = MushFormatter.format Describe.app_review(char)
        ranks_app = Ranks.is_enabled? ? MushFormatter.format(Ranks.app_review(char)) : nil
        hooks_app = MushFormatter.format Chargen.hook_app_review(char)

        custom_review = Chargen.custom_app_review(char)
        custom_app = custom_review ? MushFormatter.format(custom_review) : nil

        {
          abilities: abilities_app,
          demographics: demographics_app,
          background: bg_app,
          desc: desc_app,
          ranks: ranks_app,
          hooks: hooks_app,
          name: char.name,
          id: char.id,
          job: char.approval_job&.id,
          custom: custom_app,
          allow_web_submit: (char == enactor) && Global.read_config('chargen', 'allow_web_submit'),
          app_notes_prompt: Website.format_markdown_for_html(Global.read_config('chargen', 'app_notes_prompt')),
          preset_responses: Jobs.preset_job_responses_for_web
        }
      end
    end
  end
end
