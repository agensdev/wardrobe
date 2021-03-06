# frozen_string_literal: true

module Wardrobe
  module Refinements
    module Presenter
      refine Time do
        def _present(**options)
          if options[:time_formatter]
            options[:time_formatter].call(self.dup)
          else
            to_s
          end
        end
      end
    end
  end
end
