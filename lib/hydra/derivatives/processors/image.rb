require 'ruby-vips'

module Hydra::Derivatives::Processors
  class Image < Processor
    class_attribute :timeout

    def process
      timeout ? process_with_timeout : create_resized_image
    end

    def process_with_timeout
      Timeout.timeout(timeout) { create_resized_image }
    rescue Timeout::Error
      raise Hydra::Derivatives::TimeoutError, "Unable to process image derivative\nThe command took longer than #{timeout} seconds to execute"
    end

    protected

      # When resizing images, it is necessary to flatten any layers, otherwise the background
      # may be completely black. This happens especially with PDFs. See #110
      def create_resized_image
        create_image do |xfrm|
          if size
            (hscale, vscale) = Hydra::Derivatives::MagickGeometryService.resolve_pct(w: xfrm.width, h: xfrm.height, geometry: size)
            size_opts = hscale == vscale ? {} : { vscale: vscale }
            xfrm.resize(hscale, size_opts)
          else
            xfrm
          end
        end
      end

      def create_image
        xfrm = selected_layers(load_image_transformer)
        xfrm = yield(xfrm) if block_given?
        write_image(xfrm)
      end

      def write_image(xfrm)
        write_opts = { Q: quality }.reject { |k,v| v.nil? }
        img_format = ".#{directives.fetch(:format)}"
        output_io = StringIO.new(xfrm.write_to_buffer(img_format, write_opts))
        output_io.rewind
        output_file_service.call(output_io, directives)
      end

      # Override this method if you want a different transformer, or need to load the
      # raw image from a different source (e.g. external file)
      def load_image_transformer
        Vips::Image.new_from_file(source_path)
      end

    private

      def size
        directives.fetch(:size, nil)
      end

      def quality
        directives.fetch(:quality, nil)
      end

      def selected_layers(image)
        loader = image.get('vips-loader')
        loader_flags = Vips::Operation.new(loader).get_construct_args.collect(&:first)
        if loader =~ /pdf/i
          Vips::Image.pdfload(source_path, page: directives.fetch(:layer, 0))
        elsif loader_flags.include?('page') && directives.fetch(:layer, false)
          Vips::Image.send(loader.to_sym, source_path, page: directives.fetch(:layer))
        else
          image
        end
      end
  end
end
