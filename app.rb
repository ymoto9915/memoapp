require "sinatra"
require "sinatra/reloader"
require "securerandom"
require "json"
require "net/http"

get "/" do
  @titles = []
  array = Dir.glob("memos/*.json").sort_by { |fn| File.mtime(fn) }.reverse
  array.each do |memo|
    json = open("#{memo}").read
    hash = JSON.parse(json)
    @id = hash["id"]
    @title = hash["title"]
    title = "<a href=show/#{@id}>#{@title}</a>"
    @titles << title
  end
  erb :index
end

get "/form" do
  erb :form
end

post "/new" do
  if params[:content] == ""
    @content_or_title = "ないよう"
    erb :error_new
  elsif params[:title] == ""
    @content_or_title = "タイトル"
    erb :error_new
  else
    @id = SecureRandom.uuid
    @title = params[:title]
    @content = params[:content]
    File.open("memos/memo-#{@id}.json", "w") do |file|
      hash = {
        "id" => @id,
        "title" => @title,
        "content" => @content }
      JSON.dump(hash, file)
    end
    redirect "/"
  end
end

get "/show/:id" do
  json = open("memos/memo-#{params[:id]}.json").read
  hash = JSON.parse(json)
  @content = hash["content"]
  @title = hash["title"]
  @id = hash["id"]
  erb :show
end

get "/edit/:id" do
  json = open("memos/memo-#{params[:id]}.json").read
  hash = JSON.parse(json)
  @content = hash["content"]
  @title = hash["title"]
  @id = hash["id"]
  erb :edit
end

patch "/patch/:id" do
  @id = params[:id]
  if params[:edited_content] == ""
    @content_or_title = "ないよう"
    erb :error_patch
  elsif params[:edited_title] == ""
    @content_or_title = "タイトル"
    erb :error_patch
  else
    path = "memos/memo-#{params[:id]}.json"
    json = open(path) do |io|
      JSON.load(io)
    end
    json["content"] = params[:edited_content]
    json["title"] = params[:edited_title]
    open(path, "w") do |io|
      JSON.dump(json, io)
    end
    redirect "/show/#{@id}"
  end
end

get "/confirm/:id" do
  @id = params[:id]
  erb :delete
end

delete "/delete/:id" do
  path = "memos/memo-#{params[:id]}.json"
  File.delete(path)
  redirect "/"
end
