# this Module prepares some handy objects to
# deal with Date 's
#--
# Copyright (c) 2007 Rene Paulokat
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

require 'date'


# DateUils 
# is a simple Collection of classes which offer some 
# handy tools to get a grip on 'Date'
# ----
# * DateUtils::Year
# * DateUtils::Month
# * DateUtils::Week
# 
module DateUtils
  
  # common to Year/Month/Week
  # 
  module Common
    include Comparable
    
    # seconds in day
    DAY = 86400
    # seconds in week
    WEEK = 604800
    # seconds in month
    MONTH = 2629743.83
    # seconds in year
    YEAR = 31556926
    
    # named distance / singular / plural
    #
    def _words
      { :year => ['year','years'],
        :month => ['month','months'], 
        :week => ['week','weeks'], 
        :day => ['day', 'days'],
        :same_day => ['less than a day']
       }
    end
    
    # is given <date> included in self?
    #
    def include?(date)
      if date.instance_of?(Date)
        self.respond_to?('days') && self.days.include?(date)
      else
        raise ArgumentError, "need Date as input or no instance variable 'days'..."
      end
    end
    
    # humanized time-distance to now of given instance
    #
    #
    def distance_to_now_in_words
      distance_in_words(Time.now)
    end
    
    # humanized time-distance to given date of given instance
    #
    # somewhen = DateUtils::Year.new(Date::parse('1977-10-18'))
    # pp somewhen
    # #<DateUtils::Year:0x2b637dbb0880
    #   @date=#<Date: 4886869/2,0,2299161>,
    #   @first_day=#<Date: 4886289/2,0,2299161>,
    #   @last_day=#<Date: 4887017/2,0,2299161>,
    #   @year=1977>
    #
    # somewhen.distance_to_now_in_words
    # => "29 years,10 months,5 days ago"
    #
    def distance_in_words(date)
      _to_time = nil
      if date.kind_of?(Year) || date.kind_of?(Month) || date.kind_of?(Week) || date.kind_of?(Day)
        _to_time = Time.parse(date.date.ctime)
      elsif date.kind_of?(Date) || date.kind_of?(DateTime)
        _to_time = Time.parse(date.ctime)
      elsif date.kind_of?(Time)
        _to_time = date
      else
        raise ArgumentError.new("date needs to be instance of DateUtls::Year|Month|Week|Day or Date|DateTime|Time")
      end
      _from_time = Time.parse(self.date.ctime)
      return make_words_of(_from_time, _to_time)
    end
    
    # is this one 'later' than the other?
    # makes DateUtils:: sortable
    # expects Year || Month || Week || Day
    #
    def <=>(another)
      begin
        date <=> another.date
      rescue NoMethodError => e
        raise ArgumentError.new("<another> does not respond to 'date' / #{e.to_s}")
      end
    end
    
    private
    
    def self.extract_options_from_args!(args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options
    end
    
    # verbose 'tell' the distance
    #
    def make_words_of(from,to)
      postfix = to.to_i > from.to_i ? 'ago' : 'in future'
      left = to.to_i - from.to_i
      if left < DAY
        return _words[:same_day][0] + " " + postfix
      end
      years = left/YEAR >= 1 ? (left/YEAR).to_i : nil
      left = left - (YEAR*years) unless years.nil?
      months = left/MONTH >= 1 ? (left/MONTH).to_i : nil
      left = left - (MONTH*months) unless months.nil?
      weeks = left/WEEK >= 1 ? (left/WEEK).to_i : nil
      left = left - (WEEK*weeks) unless weeks.nil?
      days = left/DAY >= 1 ? (left/DAY).to_i : nil
      arr = []
      arr.push( years > 1 ? "#{years} #{_words[:year][1]}" : "#{years} #{_words[:year][0]}" ) if years
      arr.push( months > 1 ? "#{months} #{_words[:month][1]}" : "#{months} #{_words[:month][0]}") if months
      arr.push( weeks > 1 ? "#{weeks} #{_words[:week][1]}" : "#{weeks} #{_words[:week][0]}" ) if weeks
      arr.push( days > 1 ? "#{days} #{_words[:day][1]}" :  "#{days} #{_words[:day][0]}" ) if days
      return arr.join(',') + " " + postfix
    end
    
  end
  
  
  # represents a timezone
  # 
  class GMTZone
  
    # collection of String each representing a timezone
    # 
    def GMTZone.offsets
      arr = []
      (-12..13).each do |i|
        if i.to_s.include?('-') 
          i.to_s.length == 2 ? arr.push("GMT -0" + i.to_s.split('-')[-1].to_s + ":00") : arr.push("GMT " + i.to_s + ":00")
        else
          i.to_s.length == 1 ? arr.push("GMT +0" + i.to_s + ":00") : arr.push("GMT +" + i.to_s + ":00")
        end
      end
      arr
    end

  end
    
  # Represents a 'Week' beginning on Mondays and 
  # ending on Sundays
  #  
  class Week
    include Common
    
    # the first day (Monday) of the week
    attr_reader :first_day 
    
    # the last day (Sunday) of the week
    attr_reader :last_day 
      
    # the num of the week
    attr_reader :num_week
      
    # the initial / regular Date instance  
    attr_reader :date
      
    # the Month of the week
    attr_reader :month
      
    # create a new Week-instance with the given initial Date or Week-number
    # if 'date' is nil, create an instance with Date.today
    # 
    def initialize(val=nil)
      if val.nil?
        _date = Date.today
      else
        _date = val.is_a?(Date) ? val : (raise ArgumentError.new("neither Fixnum nor Date given."))
      end 
      set_date(_date)
      create_instance_variables
    end
    
    # create a Week-instance 
    # call with hash: year and week
    # :call-seq:
    # Week.create(:year => x, :week => y)
    # Week.create(:week => x)
    # Week.create(:year => x)
    # 
    def self.create(*args)
      options = Common::extract_options_from_args!(args)
      year_date = options.has_key?(:year) ? Date::civil(options[:year].to_i, 1,1) : Date.today
      unless options.has_key?(:week) && !options[:week].nil?
        return Week.new(year_date)
      end
      return Year.new(year_date).get_week(options[:week].to_i)
    end
    
    # return new Week -instance one week after self
    # 
    def next
      return Week.new(@last_day + 1)
    end
    
    alias succ next
    
    # returns new Week -instance one week before self
    # 
    def previous
      return Week.new(@first_day - 1)
    end
    
    # returns collection of days as Date -instances
    # or yields Day if block given
    #
    def days(&block)
      arr = []
      @first_day.upto(@last_day) { |date| arr << date }
      block_given? ? arr.each { |a| yield a } : arr
    end
    
    private
    
    # prepare instance variables
    # 
    def create_instance_variables
      @month = Month.new(@date) 
      @num_week = @date.cweek
      @first_day = @date - ( @date.cwday - 1 )
      @last_day = @date + ( 7 - @date.cwday ) 
    end
    
    # set base-date for self
    # 
    def set_date(date)
      @date = date
    end
    
    
  end
  
  # future use of Day planned instead of regular 'Date'-instance
  # when calling e.g. Month#days
  #
  class Day
    # the regular 'Date'-instance of this 'Day'
    attr_reader :date
    
    def initialize(date=nil)
      @date = date || Date.today
    end
    
  end
    
  # Represents a 'Month'
  #  
  class Month
    include Common

    # the initial / regular Date instance  
    attr_reader :date
      
    # the first day of the Month -instance
    attr_reader :first_day
      
    # the last day of the Month -instance
    attr_reader :last_day
    
    # the Month -number
    attr_reader :month
      
    # the number of days in Month
    attr_reader :num_days
      
    # create a new Month of given Date
    # 
    def initialize(val=nil)
      if val.nil?
        _date = Date.today
      else
        if val.is_a?(Date) 
          _date = val
        elsif val.is_a?(Fixnum) && val <= 12
          _date = Date::civil(Date.today.year.to_i,val,1)
        else
          raise ArgumentError.new("neither Fixnum nor Date given.")
        end
      end 
      @date = _date
      create_instance_variables
    end
        
    # create a Month-instance 
    # call with hash: year and month
    # :call-seq:
    # Month.create(:year => x, :month => y)
    # Month.create(:month => x)
    # Month.create(:year => x)
    #     
    def self.create(*args)
      options = Common::extract_options_from_args!(args)
      int_year = options.has_key?(:year) && options[:year].is_a?(Fixnum) ? options[:year] : nil
      int_month = options.has_key?(:month) && options[:month].is_a?(Fixnum) && options[:month] <= 12 ? options[:month] : nil
      return Month.new(Date::civil(int_year || Date.today.year, int_month || 1))
    end
    
    # returns new Month -instance one Month later than self
    # 
    def next
      return Month.new(@last_day + 1)
    end
     
    alias succ next
    
    # returns a new Month -instance one Month prior to self
    # 
    def previous
      return Month.new((@first_day - 1).to_date)
    end
        
    # returns collection of days as Date -instances of self
    # or yields Day if block given
    def days(&block)
      arr = []
      @first_day.upto(@last_day) { |date| arr << date }
      block_given? ? arr.each { |a| yield a } : arr
    end
      
    private
      
    def set_date(date)
      @date = date
    end
      
    def create_instance_variables
      @month = @date.month
      @first_day = @date.mday > 1 ? (@date - ( @date.mday - 1)) : @date 
      @num_days = 31 if [1,3,5,7,8,10,12].include?(@month)
      @num_days = 30 if [4,6,9,11].include?(@month)
      ( date.leap? ? (@num_days = 29) : (@num_days = 28) ) if @month == 2
      @last_day = @first_day + ( @num_days - 1 )
    end
    
  end
    
  # represents a Year
  # 
  class Year
    include Common

    # the initial Date of the Year -instance 
    attr_reader :date
    
    # the Year as an Integer of self
    attr_reader :year
    
    # first day of this year
    attr_reader :first_day
    
    # last day of this year
    attr_reader :last_day
    
    # number of weeks in year
    attr_reader :num_weeks
    
    # create a new Year -instance with given Date
    # 
    def initialize(date=nil)
      date = Date.today if date.nil?
      unless date.kind_of?(Date)
        raise ArgumentError, "needs Date as input!"
      end
      @year = date.year
      @date = date
      @first_day = Date::parse("#{@year}-01-01")
      @last_day = Date::parse("#{@year}-12-31")
      # there are 53 weeks, if year ends on thursdays: 
      @num_weeks = @last_day.wday == 4 ? 53 : 52
      
    end
    
		# create a Year-instance 
    # call with hash: year
    # :call-seq:
    # Year.create(:year => x)
    # 
    def self.create(*args)
      options = Common::extract_options_from_args!(args)
      date_year = options.has_key?(:year) ? Date.civil(options[:year]) : (raise ArgumentError.new("no key :year in hash."))
      return Year.new(date_year) 
    end
    
    # returns collection of Month -instances of self
    # or yields Month if block given
    #
    def months(&block)
      arr = []
      for i in 1..12
        arr.push( Month.new(Date.civil(@year,i) ) )
      end
      block_given? ? arr.each { |a| yield a } : arr
    end
    
    # returns collection of Week -instances of self
    # neccessarily overlaps year boundarys
    # yields Week if block given
    #
    def weeks(&block)
      d = Date.civil(@year)
      arr = []
      week = Week.new(d)
      arr.push(week)
      for i in 1..@num_weeks
        week = week.next
        arr.push(week)
      end
      block_given? ? arr.each { |a| yield a } : arr
    end
    
    # returns Week 'num' of self
    #
    def get_week(num)
      if ! num.kind_of?(Fixnum) || num > @num_weeks
        ArgumentError.new("invalid week-number 'num'")
      else
        ( @num_weeks > 52 ) ? self.weeks[num-1] : self.weeks[num]
      end
    end
    
    # returns Month 'num' of self
    # 
    def get_month(num)
      ! num.kind_of?(Fixnum) || num > 12 ? ArgumentError.new("invalid week-number 'num'"): self.months[num-1]
    end
    
    # returns new Year instance one year later
    # 
    def next
      begin
        return Year.new(Date::parse("#{@date.to_s.split('-')[0].to_i + 1}-#{@date.month}-#{@date.day}"))
      rescue ArgumentError => e
        return Year.new(Date::parse("#{@date.to_s.split('-')[0].to_i + 1}-#{@date.month}-#{@date.day - 1}"))
      end
    end
    
    alias succ next
    
    # returns new Year instance one year previous
    # 
    def previous
      begin
        return Year.new(Date::parse("#{@date.to_s.split('-')[0].to_i - 1}-#{@date.month}-#{@date.day}"))
      rescue ArgumentError => e
        return Year.new(Date::parse("#{@date.to_s.split('-')[0].to_i - 1}-#{@date.month}-#{@date.day - 1}"))
      end
    end
  end
end
