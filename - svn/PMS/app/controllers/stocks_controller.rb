class StocksController < ApplicationController
  layout nil

  def permission_map(action)
    'index'
  end
  
  # GET /stocks
  # GET /stocks.xml
  def index
    @screen = session.active_screen
    @stocks = Stock.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @stocks }
    end
  end

  # GET /stocks/1
  # GET /stocks/1.xml
  def show
    @screen = session.active_screen
    @stock = Stock.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @stock }
    end
  end

  def fetch_stock
    @stock = Stock.find(params[:id].to_i)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @stock }
    end
  end

  # GET /stocks/new
  # GET /stocks/new.xml
  def new
    @screen = session.active_screen
    @stock = Stock.new

    @labels = Label.find(:all).sort{ |a,b| a.descr <=> b.descr }
    
    @all_options = CustomField.find(:all).select do |cf|
      case cf
      when CustomFields::ComboBox, CustomFields::RadioButton, CustomFields::Reference
        true
      when CustomFields::ListBox
        #~TODO only single select value
        true
      else
        false
      end
    end
    @assigned_options = []

    @numeric_custom_fields = CustomFields::NumericField.find(:all)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @stock }
    end
  end

  # GET /stocks/1/edit
  def edit
    @screen = session.active_screen
    @stock = Stock.find(params[:id].to_i)

    @labels = Label.find(:all).sort{ |a,b| a.descr <=> b.descr }

    @assigned_options = @stock.stock_keys
    @all_options = CustomField.find(:all).select do |cf|
      case cf
      when CustomFields::ComboBox, CustomFields::RadioButton, CustomFields::Reference
        true
      when CustomFields::ListBox
        #~TODO only single select value
        true
      else
        false
      end
    end

    @numeric_custom_fields = CustomFields::NumericField.find(:all)
  end

  # POST /stocks
  # POST /stocks.xml
  def create
    @screen = session.active_screen
    @stock = Stock.new(params[:stock])

    @stock.save

    respond_to do |format|
      format.html # create.html.erb
      format.xml  { render :xml => @stock }
    end
  end

  # PUT /stocks/1
  # PUT /stocks/1.xml
  def update
    @stock = Stock.find(params[:id])

    @stock.update_attributes(params[:stock])

    @step = params[:step]

    respond_to do |format|
      format.html # update.html.erb
      format.xml  { render :xml => @report }
    end
  end

  # DELETE /stocks/1
  # DELETE /stocks/1.xml
  def destroy
    @stock = Stock.find(params[:id].to_i)
    @stock.destroy
  end
  
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end

  # GET /stocks/auto_bookings/1
  def auto_bookings
    @stock = Stock.find(params[:id].to_i)

    @assigned_options = @stock.booking_keys
    @all_options = @stock.stock_keys 
  end

   # GET /stocks/hiddens/1
  def hiddens
    @stock = Stock.find(params[:id].to_i)

    @stock_keys_no_reference = @stock.stock_keys.select{|sk| sk.class != CustomFields::Reference}
  end
 
  # GET /stocks/settings/1
  def settings
    @stock = Stock.find(params[:id].to_i)
   
    @stock_detail = @stock.stock_details.select{|sd| sd.transaction_type == params[:transaction_type]}.first
    
    unless @stock_detail
      @stock_detail = StockDetail.new(
        :stock_id => @stock.id,
        :transaction_type => params[:transaction_type]
      )

      @stock.stock_details << @stock_detail
    end
    
    @assigned_options = @stock_detail.changable_keys
    @all_options = @stock.stock_keys
  end

  def setting_stock_detail
    @stock = Stock.find(params[:id].to_i)

    @stock_detail = @stock.stock_details.select{|sd| sd.transaction_type == params[:transaction_type]}.first

    @stock_detail.update_attributes(params[:stock_detail])
  end
  
end
