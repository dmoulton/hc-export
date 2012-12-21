require 'rubygems'
require "bundler/setup"
require 'sinatra'

post "/img_export" do
  svg = params[:svg]
  filename = (params[:filename].nil? || params[:filename]=="") ? "chart" : params[:filename]


  type,ext = filetype

  if type
    system("rm -f #{settings.root}/tmp/* &") #Can't do it after, so clean up tmp dir before adding to it.

    tempname = SecureRandom.hex(16)
    outfile  = "tmp/#{tempname}.#{ext}"
    infile   = "tmp/#{tempname}.svg"
    width    = "-w #{params[:width]}" if params[:width]

    File.open(infile, 'w') {|f| f.write(svg) }
    cmd = "java -jar #{settings.root + '/lib/batik/batik-rasterizer.jar'} #{type} -d #{outfile} #{width} #{infile}"

    rsp = `#{cmd}`
    if rsp.index("success").nil?
      show_error(rsp)
      File.delete( infile)
      return
    end

    fs = File.size?( outfile)
    if fs.nil? || fs < 10
      show_error( "Output file empty;  #{rsp}")
    else
      send_file(outfile,:disposition => 'attachment', :filename=> "#{filename}.#{ext}", :stream => false)
    end

  elsif ext == "svg"
    response.headers['content_type'] = 'image/svg+xml'
    attachment("#{filename}.svg")
    response.write(svg)
  end

end

def filetype
  if params[:type] == 'image/png'
    type = '-m image/png';
    ext = 'png'
  elsif params[:type] == 'image/jpeg'
    type = '-m image/jpeg'
    ext = 'jpg'
  elsif params[:type]  == 'application/pdf'
    type = '-m application/pdf'
    ext = 'pdf'
  elsif params[:type]  == 'image/svg+xml'
    ext = 'svg'
  else
    show_error "unknown image type: #{params[:type]}"
  end
  [type,ext]
end

def show_error(rsp)
  response.headers['content_type'] = 'text/html'
  response.status = 500
  response.write("Unable to export image; #{rsp}")
end

