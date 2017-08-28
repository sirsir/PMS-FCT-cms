module ReportRequestCols
  class LoginSrc < ReportRequestCol
    belongs_to :user, :foreign_key => 'source_id'

    def description
      @description ||= user.description.clone
    end

    alias_method :descr, :description

  end
end