module Elastic
  module Helpers extend self
    def to_alias_name(klass)
      underscore(demodulize(klass.to_s))
    end

    private

    def demodulize(str)
      if i = str.rindex("::")
        str[(i + 2)..-1]
      else
        str
      end
    end

    def underscore(camel_cased_word)
      return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)
      word = camel_cased_word.to_s.gsub("::".freeze, "/".freeze)
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
      word.tr!("-".freeze, "_".freeze)
      word.downcase!
      word
    end
  end
end
