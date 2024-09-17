if Rails.env.development?
  # user = User.create(email: 'test@test.tt', password: 12345678)

  store = { var: 'dsg7',
            category: 'Test',
            goods_type: 'Под тест',
            ad_type: 'Товар от производителя',
            # originality: 'Оригинал',
            type: 'Другое',
            description: 'Hello world!',
            condition: 'Новое',
            allow_email: 'Нет',
            manager_name: 'Роман',
            contact_phone: '8 931 232-18-18',
            active: true,
            game_img_params: '{ pos_x: 240, row: 1440, column: 1440 }'
  }
  # user.stores.create(store)

  car_spare_parts = %w[ДСГ7 DSG7 DQ200]

  brands = %w[VAG]

  sub_brands = {
    'Audi' => %w[A1 A3],
    'Volkswagen' => %w[Polo Golf Jetta Tiguan Passat],
    'Skoda' => %w[Superb Octavia Rapid Fabia Yeti],
    'Seat' => %w[Leon Ibiza]
  }

  brands.each do |brand|
    current_brand = Brand.create(title: brand)
    sub_brands.each do |key, val|
      current_sub_brand = SubBrand.create(brand: current_brand, title: key)
      val.each do |model|
        Model.create(sub_brand: current_sub_brand, title: model)
      end
    end
  end

  puts "Seed done!"
end