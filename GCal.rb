class GCal
  def initialize(name)
    oauth_yaml = YAML.load_file(File.dirname(__FILE__) + '/.google-api.yaml')
    @client = Google::APIClient.new("application_name" => name)
    @client.authorization.client_id = oauth_yaml["client_id"]
    @client.authorization.client_secret = oauth_yaml["client_secret"]
    @client.authorization.scope = oauth_yaml["scope"]
    @client.authorization.refresh_token = oauth_yaml["refresh_token"]
    @client.authorization.access_token = oauth_yaml["access_token"]

    if @client.authorization.refresh_token && @client.authorization.expired?
      @client.authorization.fetch_access_token!
    end

    @service = @client.discovered_api('calendar', 'v3')
  end

  ### 最新のイベントの日付を取得 ###
  def get_latest_event_date(calendar_id, name)
    even_list = event_list_find_by_name(calendar_id, name)
    date_list = []
    event_list.each do |ev|
      if ev.start.date_time == nil
        date_list << ev.start.date
      else
        date_list << ev.start.date_time.to_date
      end
    end
    date_list.sort.reverse.first
  end

  ### 最新の2つのイベントの日付を取得 ###
  def get_event_date_last_two(calendar_id, name)
    event_list = event_list_find_by_name(calendar_id, name)
    date_list = []
    event_list.each do |ev|
      if ev.start.date_time == nil
        date_list << ev.start.date
      else
        date_list << ev.start.date_time.to_date
      end
    end
    date_list.sort.reverse.take(2).reverse
  end

  def event_list_find_by_name(calendar_id, name)
    ex_event_list = event_list(calendar_id)
    event_list = []

    ex_event_list.each do |ev|
      if ev.summary =~ /#{name}/
        event_list << ev
      end
    end
    return event_list
  end

  def event_list(calendar_id)
    page_token = nil
    result = @client.execute(:api_method => @service.events.list,
                             :parameters => {'calendarId' => calendar_id})
    event_list = []
    while true
      events = result.data.items
      event_list += events
      # events.each do |e|
      #   print e.summary + "\n" if e.summary != nil
      # end
      if !(page_token = result.data.next_page_token)
        break
      end
      result = @client.execute(:api_method => @service.events.list,
                               :parameters => {'calendarId' => calendar_id,
                                 'pageToken' => page_token})
    end
    return event_list
  end

  def events(calendar_id)
    page_token = nil
    result = @client.execute(:api_method => @service.events.list,
                             :parameters => {'calendarId' => calendar_id})
    now = Time.now
    open("#{File.dirname(__FILE__)}/data/#{now.strftime("%Y%m%d%H%M")}.json","w") do |f|
      while true
        events = result.data.items
        events.each do |e|
          puts e
        end
        JSON.dump(JSON.parse(result.data.to_json), f)
        if !(page_token = result.data.next_page_token)
          break
        end
        result = @client.execute(:api_method => @service.events.list,
                                 :parameters => {'calendarId' => 'primary',
                                   'pageToken' => page_token})
      end
    end
  end

  def calendar_list
    page_token = nil
    result = @client.execute(:api_method => @service.calendar_list.list)
    while true
      entries = result.data.items
      entries.each do |e|
        print e.summary + "\n"
      end
      if !(page_token = result.data.next_page_token)
        break
      end
      result = @client.execute(:api_method => @service.calendar_list.list,
                              :parameters => {'pageToken' => page_token})
    end
  end

  def calendars(calendar_id)
    result = @client.execute(:api_method => @service.calendars.get,
                             :parameters => {'calendarId' => calendar_id})
    print result.data
  end
end
