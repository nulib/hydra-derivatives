module Hydra::Derivatives
  class RawImageDerivatives < ImageDerivatives
    def self.processor_class
      Processors::RawImage
    end
  end
end
