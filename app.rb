require "sinatra"
require "gschool_database_connection"
require "rack-flash"
require "./models/user"
require "./models/fish"
require "pry"

class App < Sinatra::Application
  enable :sessions
  use Rack::Flash

  def initialize
    super
    GschoolDatabaseConnection::DatabaseConnection.establish(ENV["RACK_ENV"])
  end

  get "/" do
    user = current_user

    if current_user
      users = User.where.not(id: "#{user["id"]}")
      fish = Fish.where(user_id: "#{current_user["id"]}")
      # binding.pry
      erb :signed_in, locals: {current_user: user, users: users, fish_list: fish}
    else
      erb :signed_out
    end
  end

  get "/register" do
    erb :register
  end

  post "/registrations" do
    if validate_registration_params
      User.create(username: params[:username], password: params[:password])

      flash[:notice] = "Thanks for registering"
      redirect "/"
    else
      erb :register
    end
  end

  post "/sessions" do
    if validate_authentication_params
      user = authenticate_user

      if user != nil
        session[:user_id] = user["id"]
      else
        flash[:notice] = "Username/password is invalid"
      end
    end

    redirect "/"
  end

  delete "/sessions" do
    session[:user_id] = nil
    redirect "/"
  end

  delete "/users/:id" do
    User.destroy(params[:id])

    redirect "/"
  end

  get "/fish/new" do
    erb :"fish/new"
  end

  get "/fish/:id" do
    fish = Fish.find(params[:id])
    erb :"fish/show", locals: {fish: fish}
  end

  post "/fish" do
    if validate_fish_params
      Fish.create(name: params[:name], wikipedia_page: params[:wikipedia_page], user_id: current_user["id"])

      flash[:notice] = "Fish Created"

      redirect "/"
    else
      erb :"fish/new"
    end
  end

  private

  def validate_registration_params
    if params[:username] != "" && params[:password].length > 3 && username_available?(params[:username])
      return true
    end

    error_messages = []

    if params[:username] == ""
      error_messages.push("Username is required")
    end

    if !username_available?(params[:username])
      error_messages.push("Username has already been taken")
    end

    if params[:password] == ""
      error_messages.push("Password is required")
    elsif params[:password].length < 4
      error_messages.push("Password must be at least 4 characters")
    end

    flash[:notice] = error_messages.join(", ")

    false
  end

  def validate_fish_params
    if params[:name] != "" && params[:wikipedia_page] != ""
      return true
    end

    error_messages = []

    if params[:name] == ""
      error_messages.push("Name is required")
    end

    if params[:wikipedia_page] == ""
      error_messages.push("Wikipedia page is required")
    end

    flash[:notice] = error_messages.join(", ")

    false
  end

  def validate_authentication_params
    if params[:username] != "" && params[:password] != ""
      return true
    end

    error_messages = []

    if params[:username] == ""
      error_messages.push("Username is required")
    end

    if params[:password] == ""
      error_messages.push("Password is required")
    end

    flash[:notice] = error_messages.join(", ")

    false
  end

  def username_available?(username)
    existing_users = User.where(username: username)

    existing_users.length == 0
  end

  def authenticate_user
    User.where(username: params[:username], password: params[:password]).first
  end

  def current_user
    if session[:user_id]
      User.find(session[:user_id])
    else
      nil
    end
  end
end
