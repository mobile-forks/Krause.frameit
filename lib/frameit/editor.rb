require 'pry'
module Frameit
  class Editor
    module Color
      BLACK = "SpaceGray"
      SILVER = "Slvr"
    end

    module Orientation
      PORTRAIT = "Vert"
      LANDSCAPE = "Horz"
    end


    def initialize
      FrameConverter.new.run
    end

    def run(path)
      Dir["#{path}/**/*.png"].each do |screenshot|
        next if screenshot.include?"_framed.png"
        begin
          template_path = get_template(screenshot)
          if template_path
            template = MiniMagick::Image.open(template_path)
            image = MiniMagick::Image.open(screenshot)

            offset_information = image_offset(screenshot)
            width = offset_information[:width]
            image.resize width

            result = template.composite(image) do |c|
              c.compose "Over"
              c.geometry offset_information[:offset]
            end

            output_path = screenshot.gsub('.png', '_framed.png')
            result.write output_path
          end
        rescue Exception => ex
          Helper.log.error ex
        end
      end
    end

    # This will detect the screen size and choose the correct template
    def get_template(path)
      parts = [
        device_name(screen_size(path)),
        orientation_name(path),
        Color::BLACK
      ]

      templates = Dir["#{FrameConverter::TEMPLATES_PATH}/**/#{parts.join('_')}*.png"]
      if templates.count == 0
        if screen_size(path) == Deliver::AppScreenshot::ScreenSize::IOS_35
          Helper.log.warn "Unfortunately 3.5\" device frames were discontinued. Skipping screen '#{path}'".yellow
        else
          Helper.log.error "Could not find a valid template for screenshot '#{path}'"
        end
        return nil
      else
        Helper.log.debug "Found template '#{templates.first}' for screenshot '#{path}'"
        return templates.first.gsub(" ", "\ ")
      end
    end

    private
      def screen_size(path)
        Deliver::AppScreenshot.calculate_screen_size(path)
      end

      def device_name(screen_size)
        size = Deliver::AppScreenshot::ScreenSize
        case screen_size
          when size::IOS_55
            return 'iPhone_6_Plus'
          when size::IOS_47
            return 'iPhone_6'
          when size::IOS_40
            return 'iPhone_5s'
          when size::IOS_IPAD
            return 'iPad_Air'
        end
      end

      def orientation_name(path)
        return Orientation::PORTRAIT # TODO: Check that
      end

      def image_offset(path)
        size = Deliver::AppScreenshot::ScreenSize
        case orientation_name(path)
          when Orientation::PORTRAIT
            case screen_size(path)
              when size::IOS_55
                return { 
                  offset: '+42+147',
                  width: 539
                }
              when size::IOS_47
                return {
                  offset: '+41+154',
                  width: 530
                }
              when size::IOS_40
                return {
                  offset: "+54+197",
                  width: 543
                }
              when size::IOS_IPAD
                return {
                  offset: '+0+0', # TODO
                  width: ''
                }
            end
        end
      end
  end
end