require "sinatra"
require_relative "schema"
require_relative "my_ext"

def msg_payload(msg)
  me = "+19179021010"
  other_person = msg.chat.handles.first.id_value
  from_me = (msg.is_from_me == 1)
  {
    body: msg.good_text,
    from: from_me ? me : other_person,
    to: from_me ? other_person : me,
    is_from_me: from_me,
    chat_desc: msg.chat.desc,
    chat: msg.chat,
    event_at: msg.date.iso8601,
    uid: msg.guid,
  }
end

get "/" do
  ensure_connected_to_db
  content_type :json

  page = params[:page].present? ? params[:page].to_i : 1
  per_page = params[:per_page].present? ? params[:per_page].to_i : 300
  offset = (page - 1) * per_page

  base = Message.includes(chat: :handles).order(date: :desc)

  if params[:chat_name].present?
    base = base.where(chat: { display_name: params[:chat_name] })
  end
  # if params[:handle].present?
  #   ms = ms.with_handle_id(params[:handle])
  # end

  paged = base.offset(offset).limit(per_page)
  final = paged.uniq { |x| [x.good_text, x.date] }

  total_count = base.count
  total_pages = (total_count.to_f / per_page).ceil

  response = {
    messages: final.map { |x| msg_payload(x) },
    meta: {
      current_page: page,
      per_page: per_page,
      total_pages: total_pages,
      total_count: total_count,
    },
  }

  response.to_json
end
