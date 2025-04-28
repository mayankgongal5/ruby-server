Rails.application.routes.draw do
  # Route for file serving - restrict to specific allowed extensions
  get 'files/:filename', to: 'files#show', constraints: { filename: /.+\.(txt|html|pdf|json|xml|md|csv)/i }
  
  # For direct root access with filenames - same restricted extensions
  get ':filename', to: 'files#show', constraints: { filename: /.+\.(txt|html|pdf|json|xml|md|csv)/i }
end
