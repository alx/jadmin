class PostsController < ApplicationController
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
    
    @post = parse_post(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/1/edit
  def edit
    @post = parse_post(params[:id])
  end

  # POST /posts
  # POST /posts.xml
  def create
    @post = parse_post(params[:id])

    respond_to do |format|
      if @post.save
        format.html { redirect_to(@post, :notice => 'Post was successfully created.') }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    @post = parse_post(params[:id])

    respond_to do |format|
      if @post.update_attributes(params[:post])
        format.html { redirect_to(@post, :notice => 'Post was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @post = parse_post(params[:id])

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
end
