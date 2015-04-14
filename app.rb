require 'pry'
require 'sinatra'
require 'sinatra/contrib/all'
require 'httparty'
require 'uri'
require 'pg' #auto on req active_record

require_relative 'config'
require_relative 'movie'
require_relative 'history_line'

get '/' do
  erb :index
end

get '/about' do
  erb :about
end

get '/history' do
  @full_history = History_line.all
  erb :history
end

post '/history/clear' do
  History_line.all.each do |line|
    line.delete
  end
  redirect to '/history'
end

get '/donate' do
  erb :donate
end

get '/list' do
  url = "http://www.omdbapi.com/?s=#{params["search"]}"
  @movie_data = HTTParty.get(URI.escape(url))
  (@movie_data["Response"] == "False") ? (erb :error) : (erb :list)
end

get '/movie/:movie_title' do

  cleaned_movie_title = params[:movie_title].gsub("'","&#39;")
  selected_movie = Movie.where(:title => cleaned_movie_title)
  if selected_movie.empty?
    new_movie = Movie.create(:title => cleaned_movie_title)

    url = "http://www.omdbapi.com/?t=#{params[:movie_title]}"
    @omdb_data = HTTParty.get(URI.escape(url))
    new_movie.year = @omdb_data["Year"]
    new_movie.rated = @omdb_data["Rated"]
    new_movie.released = @omdb_data["Released"]
    new_movie.runtime = @omdb_data["Runtime"]
    new_movie.genre = @omdb_data["Genre"]
    new_movie.director = @omdb_data["Director"]
    new_movie.writer = @omdb_data["Writer"]
    new_movie.actors = @omdb_data["Actors"]
    new_movie.plot = @omdb_data["Plot"]
    new_movie.language = @omdb_data["Language"]
    new_movie.country = @omdb_data["Country"]
    new_movie.awards = @omdb_data["Awards"]
    new_movie.poster = @omdb_data["Poster"]
    new_movie.metascore = @omdb_data["Metascore"]
    new_movie.imdbrating = @omdb_data["imdbRating"]
    new_movie.imdbvotes = @omdb_data["imdbVotes"]
    new_movie.imdbid = @omdb_data["imdbID"]
    new_movie.movie_type = @omdb_data["Type"]
    new_movie.response = @omdb_data["Response"]
    new_movie.save

    selected_movie = Movie.where(:title => cleaned_movie_title)
  end

  @movie = selected_movie[0]
  if History_line.where(:title => cleaned_movie_title).empty?
    History_line.create(:title => cleaned_movie_title, :year => @movie["year"], :link => "/movie/#{cleaned_movie_title}")
  end

  (@movie["response"] == "False") ? (erb :error) : (erb :movie)

end

# make responsive etc