class PostsController < ApplicationController
  
  before_filter :authenticate, :except => [:index, :show]
  
  # GET /posts
  # GET /posts.xml
  def index
    @posts = []
    
    Dir.glob(File.join(Jadmin::Application.config.jekyll_folder, '_posts', '*.markdown')).each do |post|
      @posts << File.basename(post, '.markdown')
    end
    
    @posts.reverse!
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show
    
    if File.exists? File.join(Jadmin::Application.config.jekyll_folder, "_posts", "#{params[:id]}.markdown")
      @post = parse_post(params[:id])
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/new
  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /posts/1/edit
  def edit
    @post = parse_post(params[:id])
  end

  # POST /posts
  # POST /posts.xml
  def create
    
    slug = escape(params[:headers][:title])
    timestamp = Date.strptime(params[:date], "%d/%m/%Y").strftime("%Y-%m-%d")
    filepath = File.join(Jadmin::Application.config.jekyll_folder, '_posts', "#{timestamp}-#{slug}.markdown")
    
    unless File.exists? filepath
      File.open(filepath, 'w') do |file|
        file.puts "---"
        params[:headers].each do |key, value|
          file.puts "#{key}: #{value}"
        end
        file.puts "---"
        file.puts params[:content]
      end
      
      g = Git.open(Jadmin::Application.config.jekyll_folder)
      g.add("/_posts/#{timestamp}-#{slug}.markdown")
      g.commit("Add '#{slug}' post")
      g.pull
      g.push
    end

    respond_to do |format|
      format.html { redirect_to("/posts/#{timestamp}-#{slug}/edit", :notice => 'Post was successfully created.') }
      format.xml  { render :xml => @post, :status => :created, :location => @post }
    end
  end

  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    slug = escape(params[:headers][:title])
    timestamp = Date.strptime(params[:date], "%d/%m/%Y").strftime("%Y-%m-%d")
    filepath = File.join(Jadmin::Application.config.jekyll_folder, '_posts', "#{timestamp}-#{slug}.markdown")
    
    if File.exists? filepath
      File.open(filepath, 'w') do |file|
        file.puts "---"
        params[:headers].each do |key, value|
          file.puts "#{key}: #{value}"
        end
        file.puts "---"
        file.puts params[:content]
      end
      
      g = Git.open(Jadmin::Application.config.jekyll_folder)
      g.add("/_posts/#{timestamp}-#{slug}.markdown")
      g.commit("Update '#{slug}' post")
      g.pull
      g.push
    end

    respond_to do |format|
      format.html { redirect_to("/posts/#{timestamp}-#{slug}/edit", :notice => 'Post was successfully created.') }
      format.xml  { render :xml => @post, :status => :created, :location => @post }
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    
    if File.exists? File.join(Jadmin::Application.config.jekyll_folder, "_posts", "#{params[:id]}.markdown")
      g = Git.open(Jadmin::Application.config.jekyll_folder)
      g.remove("/_posts/#{params[:id]}.markdown")
      g.commit("Remove '#{params[:id]}' post")
      g.pull
      g.push
    end
    
    respond_to do |format|
      format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def parse_post(post_id)
    post = {:id => post_id,  :content => "", :headers => []}
    is_header = false
    end_header = false
    
    post_path = File.join(Jadmin::Application.config.jekyll_folder, '_posts', "#{post_id}.markdown")
    
    File.open(post_path, 'r') do |file|
      while (line = file.gets)
        if line == "---\n"
          if is_header
            end_header = true 
            is_header = false
          else
            is_header = true
          end
        else
          if is_header
            p line
            key,  value = line.split(":")
            post[:headers] << {:key => key.strip, :value => value.strip}
          end
          if end_header
            post[:content] << line
          end
        end
      end
    end
    
    post[:content] = Maruku.new(post[:content]).to_html
    post
  end
  
  def escape(string)
    result = Iconv.iconv('ascii//translit//IGNORE', 'utf-8', string).to_s
    result.gsub!(/[^\x00-\x7F]+/, '') # Remove anything non-ASCII entirely (e.g. diacritics).
    result.gsub!(/[^\w_ \-]+/i,   '') # Remove unwanted chars.
    result.gsub!(/[ \-]+/i,      '-') # No more than one of the separator in a row.
    result.gsub!(/^\-|\-$/i,      '') # Remove leading/trailing separator.
    result.downcase!
    result.size.zero? ? random_permalink(string) : result
  rescue
    random_permalink(string)
  end
  
  def random_permalink(seed = nil)
    Digest::SHA1.hexdigest("#{seed}#{Time.now.to_s.split(//).sort_by {rand}}")
  end
  
  def authenticate
    auth_config = Jadmin::Application.config.authenticate
    authenticate_or_request_with_http_basic "My custom message" do |user_name, password|
      user_name == auth_config['username'].to_s && password == auth_config['password'].to_s
    end
  end
end
