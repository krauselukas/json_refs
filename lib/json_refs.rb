require 'json_refs/version'
require 'json_refs/dereference_handler'

module JsonRefs
  def self.call(doc)
    Dereferencer.new(doc).call
  end

  class Dereferencer
    def initialize(doc)
      @doc = doc
    end

    def call(doc = @doc, keys = [])
      if doc.is_a?(Array)
        doc.each_with_index do |value, idx|
          call(value, keys + [idx])
        end
      elsif doc.is_a?(Hash)
        if doc.has_key?('$ref')
          dereference(keys, doc['$ref'])
        else
          doc.each do |key, value|
            call(value, keys + [key])
          end
        end
      end
      doc
    end

    private

    def dereference(paths, referenced_path)
      key = paths.pop
      target = paths.inject(@doc) do |obj, key|
        obj[key]
      end
      target[key] = referenced_value(referenced_path)
    end

    def referenced_value(referenced_path)
      klass = referenced_path =~ /^#/ ? JsonRefs::DereferenceHandler::Local : JsonRefs::DereferenceHandler::File
      klass.new(path: referenced_path, doc: @doc).call
    end
  end
end
