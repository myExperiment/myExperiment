class ChatArchiveController < ApplicationController
  def list
    if (user_on_project(session[:user_id],params[:id]))
      if (params[:viewtype]==nil)
        params[:viewtype]="Topic"
      end
      if (params[:viewtype]=="Day")
        @archives=Channelmessage.find_by_sql ["SELECT channelmessages.created_at, DATE_FORMAT(channelmessages.created_at,'%d/%m/%Y') as date, YEAR(channelmessages.created_at) as year, DATE_FORMAT(channelmessages.created_at,'%M') as month, DAY(channelmessages.created_at) as day FROM channelmessages INNER JOIN channels on channelmessages.channel_id=channels.id WHERE channels.project_id=? ORDER BY channelmessages.id ASC",params[:id]]
      else
        @archives=Channelmessage.find_by_sql ["SELECT DATE_FORMAT(channelmessages.created_at,'%d/%m/%Y') as date, YEAR(channelmessages.created_at) as year, DATE_FORMAT(channelmessages.created_at,'%M') as month, channel_topics.title as topic, channel_topics.id as topic_id  FROM channels INNER JOIN channelmessages on channels.id=channelmessages.channel_id INNER JOIN channel_topics ON channelmessages.topic_id=channel_topics.id WHERE channels.project_id=? ORDER BY channelmessages.id ASC",params[:id]]
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
        @archive=Channelmessage.find_by_sql ["SELECT DATE_FORMAT(channelmessages.created_at,'%H:%i:%s') as time, channelmessages.sender_id, channelmessages.level, channelmessages.content FROM channelmessages INNER JOIN channels on channelmessages.channel_id=channels.id WHERE channels.project_id = ? and YEAR(channelmessages.created_at) = ? and  MONTH(channelmessages.created_at) = ? and DAY(channelmessages.created_at) = ?", params[:id], year, month, day ]
      else
        @archive=Channelmessage.find_by_sql ["SELECT DATE_FORMAT(channelmessages.created_at,'%H:%i:%s') as time, channelmessages.sender_id, channelmessages.level, channelmessages.content FROM channelmessages INNER JOIN channels on channelmessages.channel_id=channels.id WHERE channels.project_id = ? and channelmessages.topic_id = ?", params[:id], params[:topic]  ]
      end
    else
      redirect_to :controller => 'projects', :action => 'channelblock', :id => params[:id]
    end
  end
  
end
