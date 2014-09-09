
# Describes an eMOP work item.
#
class Work < ActiveRecord::Base
   establish_connection(:emop)
   self.table_name = :works
   self.primary_key = :wks_work_id

   # is this an EEBO document?
   def isEEBO?
      if !self.wks_eebo_directory.nil? && self.wks_eebo_directory.length > 0
         return true
      end
      return false
   end

   # is this an ECCO document?
   def isECCO?
     if !self.wks_ecco_number.nil? && self.wks_ecco_number.length > 0
       return true
     end
     return false
   end

   # get the ecco number from the work ID
   def self.getEccoNumber( work_id )
     work = self.get_by_wks_work_id( work_id )
     if work.nil? == false
       return( work.wks_ecco_number)
     end
     return ""
   end
end