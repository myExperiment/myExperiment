class Job < ActiveRecord::Base

  belongs_to :workflow

  # Status constants

  @@Running   = 0
  @@Completed = 1
  @@Failed    = 2
  @@Cancelled = 3

  def Job.running
    @@Running
  end

  def Job.completed
    @@Completed
  end

  def Job.failed
    @@Failed
  end

  def Job.cancelled
    @@Cancelled
  end

  def status_string()
    if (status == Job.running)
      return "Running"
    elsif (status == Job.completed)
      return "Completed"
    elsif (status == Job.failed)
      return "Failed"
    elsif (status == Job.cancelled)
      return "Cancelled"
    else
      return "Unknown"
    end
  end

end
