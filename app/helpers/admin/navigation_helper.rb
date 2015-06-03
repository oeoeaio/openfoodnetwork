module Admin
  module NavigationHelper
    def menu_group(*args, &block)
      menu_items = capture(&block)
      options = {:label => args.first.to_s}

      # Return if resource is found and user is not allowed to :admin
      return '' if klass = klass_for(options[:label]) and cannot?(:admin, klass)

      if args.last.is_a?(Hash)
          options = options.merge(args.pop)
      end

      titleized_label = t(options[:label], :default => options[:label]).titleize

      css_classes = []

      if options[:icon]
        title = link_to titleized_label, "#", class: "icon_link #{options[:icon]}"
        mini = link_to '', '#', class: "minified icon_link #{options[:icon]}"
      else
        title = link_to titleized_label, "#"
      end

      content_tag 'li', class: "menu_group" do
        mini + title + content_tag(:ul) { menu_items }
      end
    end

    def menu_item(*args)
      options = {:label => args.first.to_s}

      # Return if resource is found and user is not allowed to :admin
      # return '' if klass = klass_for(options[:label]) and cannot?(:admin, klass)

      if args.last.is_a?(Hash)
          options = options.merge(args.pop)
      end
      options[:route] ||=  "admin_#{args.first}"

      destination_url = options[:url] || spree.send("#{options[:route]}_path")

      titleized_label = t(options[:label], :default => options[:label]).titleize

      css_classes = ["menu_item"]

      if options[:icon]
        link = link_to_with_icon(options[:icon], titleized_label, destination_url)
        mini = link_to '', '#', class: "minified icon_link #{options[:icon]}"
      else
        link = link_to(titleized_label, destination_url)
      end

      selected = if options[:match_path]
        request.fullpath.starts_with?("#{spree.root_path}admin#{options[:match_path]}")
      else
        args.include?(controller.controller_name.to_sym)
      end
      css_classes << 'selected' if selected

      if options[:css_class]
        css_classes << options[:css_class]
      end

      content_tag 'li', :class => css_classes.join(' ') do
        if mini
          mini + link
        else
          link
        end
      end
    end


    def menu_icon(icon)
      content_tag 'li', link_to('', '#', class: icon)
    end
  end
end
