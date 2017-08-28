class ListRowsController < RowsController
  layout nil

  # GET /rows
  # GET /rows.xml
    def index
        redirect_to :controller=> 'rows',
          :action => 'index',
          :id => params[:id],
          :action_source => params[:action_source], 
          :quick_operation => params[:quick_operation],
          :pageno => params[:pageno]
    end
end
