module Hydra::Derivatives
  class MagickGeometryService
    def self.resolve(w:, h:, geometry:)
      MagickGeometry.new(w, h).resolve(geometry)
    end

    def self.resolve_pct(w:, h:, geometry:)
      new_dimensions = resolve(w: w, h: h, geometry: geometry)
      [new_dimensions[0].to_f / w, new_dimensions[1].to_f / h]
    end

  end

  class MagickGeometry
    attr_reader :w, :h

    def initialize(w, h)
      @w = w
      @h = h
    end

    def resolve(geometry)
      new_dimensions = case geometry
      when /^(\d+(?:\.\d+)?)%$/
        pct($1.to_f / 100, $1.to_f / 100)
      when /^(\d+(?:\.\d+)?)%x(\d+(?:\.\d+)?)%?$/,
           /^(\d+(?:\.\d+)?)%?x(\d+(?:\.\d+)?)%$/
        pct($1.to_f / 100, $2.to_f / 100)
      when /^(\d+(?:\.\d+)?)$/
        width($1.to_f)
      when /^x(\d+(?:\.\d+)?)$/
        height($1.to_f)
      when /^(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)$/
        greater($1.to_f, $2.to_f)
      when /^(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)\^$/
        lesser($1.to_f, $2.to_f)
      when /^(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)!$/
        force($1.to_f, $2.to_f)
      when /^(\d+(?:\.\d+)?)?x(\d+(?:\.\d+)?)?>$/
        at_most($1.to_f, $2.to_f)
      when /^(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)<$/
        at_least($1.to_f, $2.to_f)
      else
        raise ArgumentError, "Unknown geometry: `#{geometry}'"
      end
      new_dimensions.collect(&:round)
    end

    private

    def pct(dw, dh)
      [w * dw, h * dh]
    end

    def width(dw)
      dh = dw / w
      [dw, h * dh]
    end

    def height(dh)
      dw = dh / h
      [w * dw, dh]
    end

    def greater(dw, dh)
      if w >= h
        dh = dw / w
        [dw, h * dh]
      else
        dw = dh / h
        [w * dw, dh]
      end
    end

    def lesser(dw, dh)
      if w <= h
        dh = dw / w
        [dw, h * dh]
      else
        dw = dh / h
        [w * dw, dh]
      end
    end

    def force(dw, dh)
      [dw, dh]
    end

    def at_most(dw, dh)
      if (dw.nil? or dw == 0.0 or w > dw) and (dh.nil? or dh == 0.0 or h > dh)
        resolve("#{dw}x#{dh}")
      else
        [w, h]
      end
    end

    def at_least(dw, dh)
      if (dw.nil? or dw == 0.0 or w < dw) and (dh.nil? or dh == 0.0 or h < dh)
        resolve("#{dw}x#{dh}")
      else
        [w, h]
      end
    end
  end
end
