class Conversion < ActiveRecord::Base
    validates :to_format, :inclusion=> {:in => ['tei', :tei, 'txt', :txt, 'alto', :alto} #mjc: 9/24/15, fixing TW ingestion of ALTO
   validates :from_format, :inclusion=>{ :in => ['gale', :gale, 'alto', :alto]}
   validates :xslt, presence: true
end
