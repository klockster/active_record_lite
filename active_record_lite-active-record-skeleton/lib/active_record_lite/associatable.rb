require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'
require 'debugger'

class AssocParams
  def other_class
    @other_class_name.to_s.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  attr_reader :primary_key, :foreign_key, :other_class_name, :other_table_name, :other_class
  def initialize(name, params)
    if !params[:class_name].nil?
      @other_class_name = params[:class_name]
    else
      @other_class_name = name.to_s.split("_").map{|x| x.capitalize}.join("").to_sym
    end

    if !params[:primary_key].nil?
      @primary_key = params[:primary_key]
    else
      @primary_key = "id"
    end

    if !params[:foreign_key].nil?
      @foreign_key = params[:foreign_key]
    else
      @foreign_key = "#{name.downcase}_id"
    end

    @other_class = name.to_s.capitalize.constantize
    @other_table_name = @other_class.table_name

  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_reader :primary_key, :foreign_key, :other_class_name, :other_table_name
  def initialize(name, params, self_class)
    if !params[:class_name].nil?
      @other_class_name = params[:class_name]
    else
      @other_class_name = name.to_s.singularize.split("_").map{|x| x.capitalize}.join("").to_sym
    end

    if !params[:primary_key].nil?
      @primary_key = params[:primary_key]
    else
      @primary_key = "id"
    end

    if !params[:foreign_key].nil?
      @foreign_key = params[:foreign_key]
    else
      @foreign_key = "#{self_class.underscore}_id"
    end

    @other_class = name.to_s.singularize.capitalize.constantize
    @other_table_name = @other_class.table_name
  end

  def type
  end
end

module Associatable


  def belongs_to(name, params = {})

    define_method(name) do
      aps = BelongsToAssocParams.new(name, params)
      #puts "assoc params: #{self.class.assoc_params}, class #{self.class}"
      self.class.assoc_params[aps.other_class_name.downcase.to_sym] = aps
      select_str = "#{aps.other_table}.*"
      where_str = "#{self.class.table_name}.#{aps.foreign_key} = #{aps.other_table_name}.#{aps.primary_key}"
      from_str = "#{aps.other_table_name}, #{self.class.table_name}"
      query = <<-SQL
      SELECT
        #{select_str}
      FROM
      #{aps.other_table_name}
      JOIN
        #{self.class.table_name}
      ON
        #{where_str}
      SQL

      results = DBConnection.execute(query)
      aps.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      aps = HasManyAssocParams.new(name, params, self.class)
      select_str = "#{aps.other_table}.*"
      where_str = "#{self.class.table_name}.#{aps.primary_key} = #{aps.other_table_name}.#{aps.foreign_key}"
      from_str = "#{aps.other_table_name}, #{self.class.table_name}"
      query = <<-SQL
      SELECT
        #{select_str}
      FROM
        #{aps.other_table_name}
      JOIN
        #{self.class.table_name}
      ON
        #{where_str}
      SQL

      results = DBConnection.execute(query)
      aps.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      a1 = self.class.assoc_params[assoc1]
      #puts "#{self.class} and #{assoc1}"
      a2 = a1.other_class.assoc_params[assoc2]

      on1_str = "#{a1.other_table_name}.#{a2.foreign_key} = #{a2.other_table_name}.#{a2.primary_key}"

      select_str = "#{a2.other_table}.*"
      where_str = "#{self.class.table_name}.#{a1.foreign_key} = #{a1.other_table_name}.#{a1.primary_key}"
      from_str = "#{a2.other_table_name}, #{self.class.table_name}"
      query = <<-SQL
      SELECT
        #{select_str}
      FROM
        #{a2.other_table_name}
      JOIN
        #{a1.other_table_name}
      ON
        #{on1_str}
      JOIN
        #{self.class.table_name}
      ON
        #{where_str}
      SQL

      results = DBConnection.execute(query)
      a2.other_class.parse_all(results).first
    end
  end
end
