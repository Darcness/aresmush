module AresMUSH
  module Chargen
    class ChargenInfoRequestHandler
      def handle(request)
        fs3 = (FS3Skills::ChargenInfoRequestHandler.new.handle(request) if FS3Skills.is_enabled?)

        {
          fs3:,
          group_options: Demographics::GroupInfoRequestHandler.new.handle(request),
          demographics: Demographics.public_demographics.map(&:titlecase),
          date_format: Global.read_config('datetime', 'date_entry_format_help'),
          bg_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'bg_blurb')),
          hooks_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'hooks_blurb')),
          desc_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'desc_blurb')),
          groups_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'groups_blurb')),
          icon_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'icon_blurb')),
          demographics_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'demographics_blurb')),
          lastwill_blurb: Website.format_markdown_for_html(Global.read_config('chargen', 'lastwill_blurb')),
          traits_blurb: Website.format_markdown_for_html(Global.read_config('traits', 'traits_blurb')),
          rpg_blurb: Website.format_markdown_for_html(Global.read_config('rpg', 'rpg_blurb')),
          allow_web_submit: Global.read_config('chargen', 'allow_web_submit'),
          stages: Global.read_config('chargen', 'stages').keys,
          genders: Demographics.genders
        }
      end
    end
  end
end
