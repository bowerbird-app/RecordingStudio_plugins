module ApplicationHelper
  # Admin 2.5.1 still calls this helper. Recording Studio 6.1 only ships
  # flat_pack_page_nav, so dummy maps the old kwargs onto that.
  def recording_studio_page_nav(title: nil, subtitle: nil, page_nav_anchor_url: nil, page_nav_back_url: nil, **)
    content_for(:title, title) if title.present?
    content_for(:subtitle, subtitle) if subtitle.present?

    nav = { round: true, style: :default }
    nav[:anchor_href] = page_nav_anchor_url if page_nav_anchor_url.present?
    nav[:back_href] = page_nav_back_url if page_nav_back_url.present?
    flat_pack_page_nav(**nav)
  end

  def dummy_page_nav(title:, subtitle: nil, back_url: nil, back_label: "Home")
    content_for(:title, title)
    content_for(:subtitle, subtitle) if subtitle.present?

    if back_url.present?
      flat_pack_page_nav(
        round: true,
        style: :default,
        back_href: back_url,
        back_tooltip: back_label
      )
    end
  end

  def dummy_layout_copy(content)
    content.presence
  end

  def dummy_signed_in_chrome
    return unless respond_to?(:user_signed_in?) && user_signed_in?

    safe_join(
      [
        dummy_language_selector,
        dummy_root_switch_dropdown,
        render(
          FlatPack::Button::Component.new(
            text: "Sign out",
            style: :ghost,
            size: :md,
            href: main_app.destroy_user_session_path,
            data: { turbo_method: :delete }
          )
        )
      ].compact
    )
  end

  def dummy_root_switch_dropdown(size: :md)
    return unless respond_to?(:recording_studio_root_switch_dropdown)

    recording_studio_root_switch_dropdown(size: size)
  end

  def dummy_language_selector
    return unless respond_to?(:recording_studio_language_selector)

    recording_studio_language_selector(
      class: "dummy-language-selector",
      data: { turbo: false }
    )
  end

  def dummy_document_attributes
    attributes = { "data-theme" => "rounded", lang: I18n.locale.to_s }
    attributes.merge!(recording_studio_locale_attributes) if respond_to?(:recording_studio_locale_attributes)
    return attributes unless respond_to?(:flat_pack_copy_data)

    attributes[:data] = (attributes[:data] || {}).merge(flat_pack_copy_data)
    attributes
  end

  def dummy_admin_root?
    return false unless respond_to?(:current_root_recording)

    current = current_root_recording
    return false if current.blank?

    config = RecordingStudioPlugins.configuration
    admin = config.admin_recording_resolver.call if config.respond_to?(:admin_recording_resolver)
    return current == admin || (current.respond_to?(:id) && admin.respond_to?(:id) && current.id == admin.id) if admin.present?

    recordable = current.respond_to?(:recordable) ? current.recordable : nil
    return false if recordable.blank?

    types = Array(config.admin_root_types).map(&:to_s)
    name = config.admin_root_name
    types.include?(recordable.class.name) && (name.blank? || recordable.try(:name).to_s == name.to_s)
  end
end
