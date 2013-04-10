require "create_xml/version"

# CreateXml для создания xml объетов для синхронизации
#  методы
#     create_object_xml -> для сосздания xml объета для обычной синхронизации
#     create_default_xml_object -> этот метод для создание xmlов данных по умолчанию ресторана
#       сохраняет xml только для восстановления
module CreateXml
  # Метод для ActiveRecord создания xml  востановления нужен restoran_id метод написан для данных создающехся по умолчанию для ресторана
  def create_restaurant_default_xml
    create_default_xml_object(self, self.restaurant_id)
  end


  # Создания ХМЛа объекта сохраняет XML в таблицы
  # sync_xml_objects список xml объектов для синхронизации
  # sync_xmls кеш для ресторана создается из таблицы sync_xml_objects
  # xml_objects весь xml объектов для восстановления
  #
  def create_object_xml(object, action)
    object_id = object.id
    restaurant_id = object.restaurant.id
    table = object.class.table_name
    schema = object.class.table_name.split('.')[1]
    action = action.to_i == 1 ? 0 : 1
    schema = 'restaurant' if schema.blank?

    xml_object = SyncXmlObject.new(
      :object_id => object_id,
      :restaurant_id => restaurant_id,
      :table => table,
      :schema => schema
    )
    xml_object.save!
    xml_object.xml = create_xml(object, table, action, xml_object.id)
    xml_object.save!

    save_restore_xml(restaurant_id, schema, table, object, action)
    create_restaurant_xml(restaurant_id)
  end

  # этот метод для создание xmlов данных по умолчанию ресторана
  # сохраняет xml только для восстановления
  def create_default_xml_object(object, restaurant_id)
    object_id = object.id
    restaurant_id = object.restaurant.id
    table = object.class.table_name.split('.')[1].blank? ? object.class.table_name : object.class.table_name.split('.')[1]
    schema = object.class.table_name.split('.')[1].blank? ? 'restaurant' : object.class.table_name.split('.')[0]
    action = 0
    schema = 'restaurant' if schema.blank?
    save_restore_xml(restaurant_id, schema, table, object, action)
  end


  # Метод для создание кеша XML для ресторана берет 500 объектов из таблицы sync_xml_objects
  def create_restaurant_xml(restaurant_id)
    sync_xml = SyncXml.find_by_restaurant_id(restaurant_id)
    sync_xml = SyncXml.new( :restaurant_id => restaurant_id ) if sync_xml.blank?

    xml_objects = SyncXmlObject.where(["restaurant_id = ?", restaurant_id])
                  .order("
                    CASE
                      WHEN sync_xml_objects.table='stocks' THEN 1
                      WHEN sync_xml_objects.table='departments' THEN 2
                      WHEN sync_xml_objects.table='course_categories' THEN 3
                      ELSE 4
                    END,
                    sync_xml_objects.created_at ASC
                  ").limit(500)

    return nil if xml_objects.blank?

    table = ""
    xml = "<?xml version='1.0' encoding='utf-8' ?><response>"

    xml_objects.each do |item|
      if table != item.table.to_s
        xml << "</#{table}>" unless table.blank?
        table = item.table
        xml << "<#{table} type='table'>"
      end
      xml << item.xml.to_s
    end
    xml << "</#{table}>" unless table.blank?
    xml << "</response>"

    sync_xml.xml = xml
    sync_xml.save!
  end

  # Общий метод для создание XML
  def create_xml(object, table, action, return_id)
    xml = "<#{table.singularize} return_id='#{return_id}' action='#{action}'>"
    object_params = object.attributes

    if table.to_s == 'courses'
      object_params.delete("unit_id")
      object_params.delete("count")
      object_params.delete('weight_out')
    end

    if table.to_s == 'bill_course_resigns'
      object_params.delete("unit_id")
      object_params.delete("count")
      object_params.delete('weight_out')
    end

    object_params.each do |attr|
      if attr[0].to_s != 'kind'
        if attr[0].to_s == 'is_active'
          object_value = attr[1]
        else
          object_value = attr[1].blank? ? '' : CGI.escapeHTML(attr[1].to_s)
        end

        if table.to_s == 'bill_course_resigns' && attr[0].to_s == 'count'
          xml << "<course_count>#{object_value}</course_count>"
        else
          xml << "<#{attr[0]}>#{object_value}</#{attr[0]}>"
        end
      end
    end

    xml << "</#{table.singularize}>"
    xml
  end

  # Метод для сохранения XML восстановления
  def save_restore_xml(restaurant_id, schema, table, object, action)
    restore_xml = XmlObject.new(
      object_id: object.id,
      restaurant_id: restaurant_id,
      table: table,
      schema: schema
    )
    restore_xml.save!
    restore_xml.xml = create_xml(object, table, action, restore_xml.id)
    restore_xml.save!
  end

end

ActiveRecord::Base.class_eval do
  include CreateXml
end