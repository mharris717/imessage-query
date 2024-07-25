require "active_record"
require_relative "my_ext"

def connect_to_db
  db_path = ENV["DB_PATH"] || File.expand_path("~/Library/Messages/chat.db")
  raise "no db mounted at #{db_path}" unless File.exist?(db_path)
  puts "Attempting to connect to database at: #{db_path}"
  begin
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: db_path,
    )
    puts "Successfully connected to the database."
  rescue SQLite3::CantOpenException => e
    puts "Error: Unable to open the database file."
    puts "Error details: #{e.message}"
    puts "Please check if the file exists and has correct permissions."
    exit(1)
  end
end

def ensure_connected_to_db
  return unless $connected_to_db
  $connected_to_db = true
  connect_to_db
end

connect_to_db

class AppleTimestampType
  def convert_apple_timestamp_to_datetime(apple_timestamp)
    Time.at(apple_timestamp / 1000000000 + 978307200)
  end

  def convert_datetime_to_apple_timestamp(datetime)
    (datetime.to_i - 978307200) * 1000000000
  end

  def cast(value)
    if value.kind_of?(Numeric)
      convert_apple_timestamp_to_datetime(value)
    else
      super(value)
    end
  end

  def serialize(value)
    raise "not time #{value}" unless value.kind_of?(Time)
    convert_datetime_to_apple_timestamp(value)
  end

  def deserialize(value)
    raise "not number #{value}" unless value.kind_of?(Numeric)
    convert_apple_timestamp_to_datetime(value).tap { |x| puts "deserialize #{x}" }
  end
end

ActiveRecord::Type.register(:apple_timestamp, AppleTimestampType)

class Handle < ActiveRecord::Base
  self.table_name = "handle"

  def raw_id = self[:id]
end

class Message < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  self.table_name = "message"
  belongs_to :handle
  has_one :chat_message_join
  has_one :chat, through: :chat_message_join
  scope :myself, -> { joins(:chat).where(chat: Chat.myself) }
  scope :since_dt, ->(dt) { where(Message.arel_table[:date].gt(dt)) }
  scope :recent, -> { since_dt(3.days.ago) }
  # scope :with_handle_id, ->(id_value) { joins(:chat).where(chat: Chat.with_handle_id(id_value)) }
  attribute :date, :apple_timestamp

  def good_text
    return text if text.present?
    return parsed_attributed_body if attributedBody
    "no clue"
  end

  def parsed_attributed_body
    text = attributedBody.split("NSString")[1]
    text = text[5..-1]  # stripping some preamble which generally looks like this: '\x01\x94\x84\x01+'

    # this 129 is '\x81, ruby indexes byte strings as ints,
    # this is equivalent to text[0] == '\x81'
    if text[0].ord == 129
      length = text[1..2].unpack("v*").first
      text = text[3..length + 2]
    else
      length = text[0].ord
      text = text[1..length]
    end
    text.force_encoding("UTF-8")
  end

  def desc
    d = date.strftime("%Y-%m-%d %H:%M:%S")
    "#{chat.desc} | #{d} #{good_text}"
  end
end

class Chat < ActiveRecord::Base
  self.table_name = "chat"
  has_many :chat_message_joins
  has_many :messages, through: :chat_message_joins
  has_many :chat_handle_joins
  has_many :handles, through: :chat_handle_joins

  scope(:with_single_handle, lambda do
    inner = joins(:handles).group("chat.ROWID").having("COUNT(handle.ROWID) = 1")
    where(ROWID: inner.pluck(:ROWID))
  end)
  scope :with_handle_id, ->(id_value) { joins(:handles).where("handle.id = ?", id_value) }
  scope :iMessage, -> { where(service_name: "iMessage") }
  scope :_direct_with, ->(handle) { iMessage.with_handle_id(handle).with_single_handle }
  scope :myself, -> { where(ROWID: [10, direct_with("example@gmail.com").ROWID]) }
  def self.by_name(name)
    where(display_name: name).first_only
  end

  def self.direct_with(handle)
    _direct_with(handle).first_only
  end

  def desc
    h = handles.map { |x| x }.map { |x| x.id_value }.join(",")
    display_name.present? ? "#{display_name} - #{h}" : h
  end

  def as_json(ops = {})
    {
      id: self.ROWID,
      desc: desc,
      display_name: display_name,
      service_name: service_name,
      handles: handles.map { |x| x }.map { |x| x.id_value },
    }
  end
end

class ChatHandleJoin < ActiveRecord::Base
  self.table_name = "chat_handle_join"
  belongs_to :chat
  belongs_to :handle
end

class ChatMessageJoin < ActiveRecord::Base
  self.table_name = "chat_message_join"
  belongs_to :chat
  belongs_to :message
end

# puts Message.last.date
# puts "getting count"
# puts Message.where(Message.arel_table[:date].gt(3.days.ago)).count
# puts Message.since_dt(3.days.ago).count
# puts Message.since_dt(3.days.ago).last.date
