class Conversion < ActiveRecord::Base
   validates :to_format, :inclusion=> {:in => ['tei', :tei, 'txt', :txt, 'gale', :gale]}
   validates :from_format, :inclusion=>{ :in => ['gale', :gale, 'alto', :alto]}
   validates :xslt, presence: true
end
