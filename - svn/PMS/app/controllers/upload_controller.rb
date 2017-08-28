class UploadController < ApplicationController
  layout nil

  def screen_from_action(params)
    Screen.find(params[:screen_id]) || super
  end

  def save_image
    @time = Time.now.strftime('%Y%m%d%H%M%S')
    case params[:file]['picture']
    when File, ActionController::UploadedStringIO, ActionController::UploadedTempfile
      saved_name = Upload.image_save(params[:file]['picture'],@time)
      @image_name = File.basename(saved_name)
      @cf_id = params[:cf_id]
    end
  end

  def delete_image_by_temp
    image_name = params[:image_name]
    begin
      File.delete("#{RAILS_ROOT}/public/attachments/#{image_name}")
    rescue Exception
      # Nothing to do
    end
  end
end
