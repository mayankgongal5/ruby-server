class FilesController < ApplicationController
  FILES_DIRECTORY = Rails.root.join('files') # ./files/ folder
  ALLOWED_EXTENSIONS = %w[.txt .html .htm .pdf .json .xml .md .csv]
  MAX_FILE_SIZE = 10.megabytes

  def show
    filename = params[:filename]
    
    # Sanitize filename to prevent directory traversal
    sanitized_filename = File.basename(filename)
    
    # Additional extension validation
    extension = File.extname(sanitized_filename).downcase
    unless ALLOWED_EXTENSIONS.include?(extension)
      render plain: "Invalid file type", status: :forbidden
      return
    end
    
    filepath = FILES_DIRECTORY.join(sanitized_filename)
    
    # Ensure the file is within the FILES_DIRECTORY (prevent symlink attacks)
    real_path = File.realpath(filepath) rescue nil
    if !real_path || !real_path.start_with?(File.realpath(FILES_DIRECTORY))
      render plain: "Access denied", status: :forbidden
      return
    end

    # Check if file exists and is a regular file
    if !File.exist?(filepath) || !File.file?(filepath)
      render plain: "File not found", status: :not_found
      return
    end
    
    # Check file size
    if File.size(filepath) > MAX_FILE_SIZE
      render plain: "File too large", status: :forbidden
      return
    end

    # Read and send file content
    content = File.read(filepath)
    
    # Set proper content type
    content_type = detect_content_type(filepath)
    
    # Set security headers
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    
    send_data content, type: content_type, disposition: 'inline'
  rescue => e
    logger.error("File access error: #{e.message}")
    render plain: "Error accessing file", status: :internal_server_error
  end
  
  private
  
  def detect_content_type(filepath)
    case File.extname(filepath).downcase
    when '.txt', '.md'
      'text/plain'
    when '.html', '.htm'
      'text/html'
    when '.json'
      'application/json'
    when '.xml'
      'application/xml'
    when '.pdf'
      'application/pdf'
    when '.csv'
      'text/csv'
    else
      'text/plain' # Default to text/plain
    end
  end
end
