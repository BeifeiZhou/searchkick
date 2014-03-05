module Searchkick
  class Results < Elasticsearch::Model::Response::Response
    attr_writer :response

    delegate :each, :empty?, :size, :slice, :[], :to_ary, to: :records

    def suggestions
      if @response["suggest"]
        @response["suggest"].values.flat_map{|v| v.first["options"] }.sort_by{|o| -o["score"] }.map{|o| o["text"] }.uniq
      else
        raise "Pass `suggest: true` to the search method for suggestions"
      end
    end

    def with_details
      each_with_hit.map do |model, hit|
        details = {}
        if hit["highlight"]
          details[:highlight] = Hash[ hit["highlight"].map{|k, v| [k.sub(/\.analyzed\z/, "").to_sym, v.first] } ]
        end
        [model, details]
      end
    end

    def facets
      response["facets"]
    end

    # fixes deprecation warning
    def __find_records_by_ids(klass, ids)
      @options[:load] === true ? klass.find(ids) : klass.includes(@options[:load][:include]).find(ids)
    end

    def model_name
      @options[:model_name]
    end

  end
end
