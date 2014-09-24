#
# Describes the emop page queue
#

class PageQueue < ActiveRecord::Base

  establish_connection(:emop)
  self.table_name = :job_queue
  self.primary_key = :id

  STATUS_READY_FOR_IMPORT = 3
  STATUS_IMPORTING = 4
  STATUS_IMPORTED = 5
  STATUS_ERRORED = 7
  CONFIDENCE_THRESHOLD = 0.8

  def self.mark_importing( page_id )
    self.update_status( page_id, STATUS_IMPORTING )
  end

  def self.mark_imported( page_id )
     self.update_status( page_id, STATUS_IMPORTED )
  end

  def self.mark_errored( page_id )
    self.update_status( page_id, STATUS_ERRORED )
  end

  def self.update_status( page_id, status )
    # set page status
    sql = "update job_queue set job_status=#{status} where id=#{page_id} limit 1"
    PageQueue.connection.execute( sql );
  end

  def self.get_pages( limit )

    pages = []
    sql = "select distinct j.page_id, w.wks_ecco_number from job_queue j, works w, page_results p where j.job_status = #{STATUS_READY_FOR_IMPORT}" \
    + " and j.work_id = w.wks_work_id and w.wks_ecco_number is not NULL and p.juxta_change_index >= #{CONFIDENCE_THRESHOLD} and j.page_id = p.page_id"
    sql += " limit #{limit}" unless limit.nil? || limit == 0
    results = PageQueue.find_by_sql( sql )

    results.each do |result|
      rec = page_result_to_hash(result)
      rec[:xml_file] = self.get_ocr_file( rec[:page_id] )
      pages << rec
    end

    return( pages )
  end

  private

  def self.get_ocr_file( page_id )
    sql = "select id, ocr_xml_path from page_results where page_id=#{page_id} and juxta_change_index >= #{CONFIDENCE_THRESHOLD} order by 1 desc limit 1"
    results = PageQueue.find_by_sql( sql )
    return results.first.ocr_xml_path
  end

  def self.page_result_to_hash( result )
    rec = {}
    rec[:page_id] = result.page_id
    rec[:ecco_number] = result.wks_ecco_number

    return( rec )
  end

end