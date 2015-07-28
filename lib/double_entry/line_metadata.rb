module DoubleEntry
  class LineMetadata < ActiveRecord::Base
    belongs_to :line
  end
end
