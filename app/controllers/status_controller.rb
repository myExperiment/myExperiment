class StatusController < ApplicationController

  def index
    @render_string = "Time: " + Time.now.to_s + "\n"
    @render_string += "Item: Count: Time taken (seconds)\n"
    @render_string += "Users: " + count_users.to_s + ": " + @time_taken.to_s + "\n"
    @render_string += "Groups: " + count_groups.to_s + ": " + @time_taken.to_s + "\n"
    @render_string += "Workflows: " + count_workflows.to_s + ": " + @time_taken.to_s + "\n"
    @render_string += "Files: " + count_files.to_s + ": " + @time_taken.to_s + "\n"
    render(:text => @render_string)
  end

  private

  def count_users
    @start_time = Time.now.to_f
    @count = User.count
    @time_taken = "%5.5f" % (Time.now.to_f - @start_time)
    @count
  end

  def count_groups
    @start_time = Time.now.to_f
    @count = Network.count
    @time_taken = "%5.5f" % (Time.now.to_f - @start_time)
    @count
  end

  def count_workflows
    @start_time = Time.now.to_f
    @count = Workflow.count
    @time_taken = "%5.5f" % (Time.now.to_f - @start_time)
    @count
  end

  def count_files
    @start_time = Time.now.to_f
    @count = Blob.count
    @time_taken = "%5.5f" % (Time.now.to_f - @start_time)
    @count
  end

end
