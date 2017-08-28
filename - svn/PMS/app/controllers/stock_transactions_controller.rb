class StockTransactionsController < ApplicationController
  layout nil

  # GET /stock_transactions
  # GET /stock_transactions.xml
  def index
    @stock = Stock.find(params[:id])
    @transaction_type = params[:type]

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @stock }
    end
  end

  # GET /stock_transactions/1
  # GET /stock_transactions/1.xml
  def show
    @stock_transaction = StockTransaction.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @stock_transaction }
    end
  end

  # GET /stock_transactions/new
  # GET /stock_transactions/new.xml
  def new
    @stock = Stock.find(params[:id])
    @transaction_type = params[:transaction_type]

    @stock_item = StockItem.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /stock_transactions
  # POST /stock_transactions.xml
  def create
    @stock_transaction = StockTransaction.new(params[:stock_transaction])

    respond_to do |format|
      if @stock_transaction.save
        flash[:notice] = 'StockTransaction was successfully created.'
        format.html { redirect_to(@stock_transaction) }
        format.xml  { render :xml => @stock_transaction, :status => :created, :location => @stock_transaction }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @stock_transaction.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def search 
    render :text => (RAILS_ENV =~ /development/) ? '<span class="missing_implementation">Implement how to display the search controls.</span>' : ''  
  end

  def stock_value
    @stock = Stock.find(params[:id])
    @transaction_type = params[:transaction_type]

    conditions = {:stock_items => {}}

    key_values = []
    
    params.each do |k, v|
      if k =~ /stock_key_id_/
        conditions[:stock_items][k.to_sym] = v

        index = k.gsub(/stock_key_id_/,'').to_i

        stock_key = @stock.stock_keys[index]

        value = case stock_key
        when CustomFields::ComboBox
          v
        when CustomFields::ListBox
          ['-1', v]
        when CustomFields::RadioButton
          {:label => v}
        when CustomFields::Reference
          {:row_id => v}
        end

        html_value = stock_key.html(value)
        html_value ||= "stock_key_id_#{index}"
        
        key_values << [v, "'#{html_value}'"]
      end
    end

    @stock_item = StockItem.find(:first, :conditions => conditions)
    
    current_value = (@stock_item.nil?) ? 100 : @stock_item.take_in_qty

    #~ ToDo: Try to replace with key_values.inspect
    key_values = key_values.collect{|k| "[#{k.join(',')}]"}
    ui_feedback = <<JAVASCRIPT
    fncSetStockValue([#{key_values.join(',')}], #{current_value});
JAVASCRIPT

    render(:update) do |page|
      page << ui_feedback
    end
  end
end
