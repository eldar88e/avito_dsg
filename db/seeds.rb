if true  # Rails.env.development?
  user = User.create(email: 'test@test.tt', password: '12345678')

  store = { var: 'dsg7',
            category: 'Test',
            goods_type: 'Под тест',
            ad_type: 'Товар от производителя',
            # originality: 'Оригинал',
            type: 'Другое',
            description: 'Hello world!',
            condition: 'Новое',
            allow_email: 'Нет',
            manager_name: 'Алексей',
            contact_phone: '8 931 232-18-18',
            active: true,
            game_img_params: '{ pos_x: 240, row: 1440, column: 1440 }'
  }

  user.stores.find_or_create_by(store)

  model_parts = %w[DQ200 DL501]
  brands      = %w[VAG Luk]
  brands.each { |brand| Brand.find_or_create_by(title: brand) }

  sub_brands = {
    'Audi' => %w[A1 A3],
    'Volkswagen' => %w[Polo Golf Jetta Tiguan Passat],
    'Skoda' => %w[Superb Octavia Rapid Fabia Yeti],
    'Seat' => %w[Leon Ibiza]
  }

  descr_mah  = '<div><strong>Преимущества восстановленного маховика:<br></strong><br></div><ul><li>🔧 Качество как у нового: Полная диагностика и восстановление гарантируют долговечность и стабильную работу.</li><li>💰 Экономия: Стоимость ниже нового, но те же характеристики и ресурс.</li><li>🚗 Совместимость: Подходит для Audi, Volkswagen, Skoda, Seat с трансмиссией DSG7/DQ200.</li></ul>'
  descr_scep = '<div><strong>Почему выбирают нас?</strong><br><br>🛡 Гарантия 1 год или 30 000 км пробега: В договоре прописаны четыре ключевые гарантии.<br><br>💵 Гарантия лучшей цены.<br><br>⏳ Гарантия сроков: Мы соблюдаем установленные сроки ремонта.<br><br>🔧 Гарантия на все виды работ: Все услуги сопровождаются официальной гарантией.<br><br>🛠 Гарантия на запчасти: Используем только проверенные и сертифицированные компоненты.<br><br>❗Продажа в розницу временно приостановлена, доступна покупка при установке в нашем автосервисе.</div>'
  temp_title_mah  = '[part] [dsg_title] [brand_title] [model_part] восстановленный [sub_brand] [model], [year]'
  temp_title_scep = '[part] [dsg_title] [brand_title] [model_part] для [sub_brand] [model], [year]'

  parts = [{ title: 'Маховик', part_type: 'Сцепление', description: descr_mah, min_price: 69600, max_price: 74500, template_title: temp_title_mah },
           { title: 'Сцепление', part_type: 'Сцепление', description: descr_scep, min_price: 39900, max_price: 41000, template_title: temp_title_scep }]

  model_parts.each do |model_part|
    model_part_db = ModelPart.find_or_create_by(title: model_part)
    parts.each do |part|
      model_part_db.parts.find_or_create_by(part)
    end
  end

  vag_brand = Brand.find_by(title: 'VAG')
  sub_brands.each do |key, val|
    sub_brand = SubBrand.find_or_create_by(brand: vag_brand, title: key)
    val.each do |model|
      parts = Part.where(title: 'Маховик')
      sub_brand.models.create(title: model, start_year: 2008, end_year: 2023, parts: parts)
    end
  end

  puts "Seed done!"
end