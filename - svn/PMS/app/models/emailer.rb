class Emailer < ActionMailer::Base
   def email(recipient,sender,cc_dest,bcc_dest,subj,att_file)
	   recipients recipient
	   from sender
	   cc cc_dest.split(',')
	   bcc bcc_dest.split(',')
	   subject subj
	   body :user => 'TSEStaff'
	   files = att_file.split(',')
	   files.each do |a|
		   attachment :content_type => 'image/jpeg',
		   :filename => File.basename(a),
		   :body => File.open(a,'rb').read
	   end
	end
end
