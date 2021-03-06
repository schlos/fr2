class LedePhoto < ApplicationModel
  attr_reader :flickr_photo_id
  has_many :entries
  has_attached_file :photo,
                    :styles => { :navigation => ["400x175", :jpg], :homepage => ["100", :jpg], :small => ["140", :jpg], :medium => ["245", :jpg], :large => ["800x350", :jpg], :full_size => ["", :jpg] },
                    :processors => [:thumbnail],
                    :storage => :s3,
                    :s3_credentials => "#{Rails.root}/config/amazon.yml",
                    :s3_protocol => 'https',
                    :bucket => 'lede-photos.federalregister.gov',
                    :path => ":id/:style.:extension"
  
  before_save :download_and_crop_file
  before_save :get_credit_info_from_flickr
  
  def download_and_crop_file
    if url.present?
      file_path = Tempfile.new('flickr.jpg').path
      Rails.logger.warn "FILE NAME => #{file_path}"
      Curl::Easy.download(url, file_path) {|c| c.follow_location = true}
      
      if crop_x
        dst = Tempfile.new('flickr.jpg')
        dst.binmode

        command = <<-end_command
          "#{ File.expand_path(file_path) }[0]"
          -crop "#{crop_width}x#{crop_height}+#{crop_x}+#{crop_y}"
          "#{ File.expand_path(dst.path) }"
        end_command
        Rails.logger.warn(command)
        Paperclip.run("convert", command.gsub(/\s+/, " "))
        file_path = dst.path
      end
      
      self.photo = File.open(file_path)
    end
  end
  
  def flickr_photo_id=(photo_id)
    @flickr_photo_id = photo_id
  end

  def credit_url
    self['credit_url'] + '/lightbox'
  end
  
  private
  
    def get_credit_info_from_flickr
      if @flickr_photo_id.present?
        photo = Flickr::Photo.find_by_id(@flickr_photo_id)
        self.credit = photo.creator.real_name.present? ? photo.creator.real_name : photo.creator.user_name
        self.credit_url = photo.url('photopage')
      end
    
      true
    end
end
