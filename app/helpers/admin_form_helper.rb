module AdminFormHelper
  def form_group(model, value_key, &block)
    content_tag(:div,
                [capture(&block), form_group_error(model, value_key)].compact.join.html_safe,
                class: form_group_class(model, value_key))
  end

  def form_group_class(model, value_key)
    return "form-group" if model.errors.blank?
    return "form-group has-error" if model.errors[value_key].any?
    "form-group has-success"
  end

  def form_group_error(model, value_key)
    return if model.errors[value_key].blank?

    content_tag(:p, model.errors[value_key].first, class: "form-input-hint")
  end
end
