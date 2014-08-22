#
# Describes the emop job queue
#
class JobQueue < ActiveRecord::Base

  establish_connection(:emop)
  self.table_name = :job_queue
  self.primary_key = :id


  def mark_page_imported( job_id )

     # set job status back to scheduled
     sql = "update job_queue set job_status=1 where id=#{job_id} limit 1"
     JobQueue.connection.execute(sql);
  end

end