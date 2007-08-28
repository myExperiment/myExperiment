class ChatArchiveController < ApplicationController
  def list
    if (user_on_project(session[:user_id],params[:id]))
      if (params[:viewtype]==nil)
        params[:viewtype]="Topic"
      end
      if (params[:viewtype]=="Day")
        @archives=Channelmessage.find_by_sql ["SELECT created_at, DATE_FORMAT(created_at,'%d/%m/%Y') as date, YEAR(channelmessages.created_at) as year, DATE_FORMAT(created_at,'%M') as month, DAY(created_at) as day FROM channelmessages WHERE channel_id=? ORDER BY channelmessages.id ASC",params[:id]]
      else
        @archives=Channelmessage.find_by_sql ["SELECT DATE_FORMAT(created_at,'%d/%m/%Y') as date, YEAR(channelmessages.created_at) as year, DATE_FORMAT(created_at,'%M') as month, channel_topics.title as topic, channel_topics.id as topic_id  FROM channelmessages INNER JOIN channel_topics ON channelmessages.topic_id=channel_topics.id WHERE channelmessages.channel_id=? ORDER BY channelmessages.id ASC",params[:id]]
      end
    else
      redirect_to :controller => 'projects', :action => 'channelblock', :id => params[:id]
    end
  end
  def show
    if (user_on_project(session[:user_id],params[:id]))
      if params[:date]==nil
        params[:date]="No Archive"
      end
      day=params[:date][0..1]
      month=params[:date][3..4]
      year=params[:date][6..9]
      if (params[:viewtype]=="Day")
        @archive=Channelmessage.find_by_sql ["SELECT DATE_FORMAT(created_at,'%H:%i:%s') as time, sender_id, level, content FROM channelmessages WHERE channel_id = ? and YEAR(created_at) = ?and  MONTH(created_at) = ? and DAY(created_at) = ?", params[:id], year, month, day ]
      else
        @archive=Channelmessage.find_by_sql ["SELECT DATE_FORMAT(created_at,'%H:%i:%s') as time, sender_id, level, content FROM channelmessages WHERE channel_id = ? and topic_id = ?", params[:id], params[:topic]  ]
      end
    else
      redirect_to :controller => 'projects', :action => 'channelblock', :id => params[:id]
    end
  end
  
end
