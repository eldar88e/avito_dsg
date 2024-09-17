class WatermarkService
  include Rails.application.routes.url_helpers
  include Magick

  attr_reader :image

  def initialize(**args)
    @settings  = args[:settings]
    @main_font = @settings[:main_font]
    @store     = args[:store]
    @width     = (@settings[:avito_img_width] || 1920).to_i
    @height    = (@settings[:avito_img_height] || 1440).to_i
    @new_image = initialize_first_layer
    @part      = args[:sub_part]
    img_url    = find_main_ad_img
    @image     = image_exist?(img_url)
    @layers    = make_layers_row

    @layers << { img: img_url, menuindex: @store.menuindex,
                 params: @store.game_img_params.presence || {}, layer_type: 'img' }
    @layers.sort_by! { |layer| layer[:menuindex] }
  end

  def add_watermarks
    @layers.each do |layer|
      layer[:params] =
        if layer[:params].is_a?(Hash)
          layer[:params]
        else
          eval(layer[:params]).transform_keys { |key| key.to_s } if layer[:params].present?
        end
      layer[:params] = rewrite_pos_size(layer[:params])
      layer[:layer_type] == 'text' ? add_text(layer) : add_img(layer)
    end

    @new_image
  end

  private

  def rewrite_pos_size(args)
    return {} if args.blank?

    formated_args = {}
    formated_args['pos_x']  = args['pos_x'].to_i > @width ? @width : args['pos_x'].to_i     if args['pos_x'].present?
    formated_args['pos_y']  = args['pos_y'].to_i > @height ? @height : args['pos_y'].to_i   if args['pos_y'].present?
    formated_args['row']    = args['row'].to_i > @width ? @width : args['row'].to_i         if args['row'].present?
    formated_args['column'] = args['column'].to_i > @height ? @height : args['column'].to_i if args['column'].present?

    args.merge formated_args
  end

  def add_img(layer)
    params = layer[:params]
    img    = Image.read(layer[:img]).first
    if (params['column'] && !params['column'].zero?) || (params['row'] && !params['row'].zero?)
      img.resize_to_fit!(params['row'], params['column'])
    end

    x_offset = params['pos_x'].present? ? params['pos_x'] : (@new_image.columns - img.columns) / 2
    y_offset = params['pos_y'].present? ? params['pos_y'] : (@new_image.rows - img.rows) / 2

    @new_image.composite!(img, x_offset, y_offset, OverCompositeOp)
  end

  def add_text(layer)
    return unless layer[:title].present?

    params             = layer[:params]
    text_obj           = Draw.new
    text_obj.font      = layer[:img] || @main_font || 'Arial'
    text_obj.pointsize = params['pointsize'] || 42  # Размер шрифта
    #text_obj.rotate    = params['rotate']&.to_f || 0
    text_obj.fill      = params['fill'] || 'white'
    text_obj.stroke    = params['stroke'] || 'white'  # Цвет обводки текста
    text_obj.gravity   = make_gravity params['gravity']
    text_obj.annotate(@new_image, params['row'] || 0, params['column'] || 0,
                      params['pos_x'] || 0, params['pos_y'] || 0, layer[:title])
  end

  def make_gravity(gravity)
    { 'top_left'      => NorthWestGravity,
      'top_center'    => NorthGravity,
      'top_right'     => NorthEastGravity,
      'middle_left'   => WestGravity,
      'middle_center' => CenterGravity,
      'middle_right'  => EastGravity,
      'bottom_left'   => SouthWestGravity,
      'bottom_center' => SouthGravity,
      'bottom_right'  => SouthEastGravity
    }[gravity] || NorthWestGravity
  end

  def image_exists?(url)
    return false if url.match?(/\Ahttp/) # TODO проверить

    uri      = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    response.is_a?(Net::HTTPSuccess)
  end

  def find_main_ad_img
    return unless @part.photos.present?

    key = @part.photos.sample.blob.key
    raw_path = key.scan(/.{2}/)[0..1].join('/')
    "./storage/#{raw_path}/#{key}"
  end

  def make_layers_row
    @store.image_layers.map do |i|
      next if !i.active

      if i.layer.attached?
        key      = i.layer.blob.key
        raw_path = key.scan(/.{2}/)[0..1].join('/')
        img_path = "./storage/#{raw_path}/#{key}"
        { img: img_path,
          params: i.layer_params.presence || {},
          menuindex: i.menuindex,
          layer_type: i.layer_type,
          title: i.title
        }
      elsif i.layer_type == 'text' && i.title.present?
        { params: i.layer_params.presence || {}, menuindex: i.menuindex, layer_type: i.layer_type, title: i.title }
      else
        nil
      end
    end
  end

  def image_exist?(url)
    url && File.exist?(url)
  end

  def initialize_first_layer
    Image.new(@width, @height) do |c|
      c.background_color = @settings[:avito_back_color] || '#FFFFFF'
      #c.format           = 'JPEG'
      #c.interlace        = PlaneInterlace
    end
  end
end
