class RemoveTopics < ActiveRecord::Migration
  def up
    drop_table :topics
    drop_table :topic_feedbacks
    drop_table :topic_runs
    drop_table :topic_tag_map
    drop_table :topic_workflow_map
  end

  def down
  end
end
