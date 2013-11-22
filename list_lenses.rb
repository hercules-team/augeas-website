#!/usr/bin/env ruby

require 'augeas'
require 'optparse'

format = 'shell'
lensdir = '/usr/share/augeas/lenses/dist'
rootdir = ''
version = nil

OptionParser.new do |opts|
  opts.banner = "Usage: list_lenses.rb [options]"

  opts.on("-f", "--format FORMAT", "Specify format (html)") do |f|
    format = f
  end
  opts.on("-l", "--lensdir DIR", "Specify lens directory") do |d|
    lensdir = d
  end
  opts.on("-r", "--rootdir DIR", "Root directory for the website") do |r|
    rootdir = r
  end
  opts.on("-v", "--version VERSION", "Augeas release to link to") do |v|
    version = v
  end
end.parse!

class String
  def cleanpath
    gsub(/^#{ENV["HOME"]}/, "~")
  end
end

aug = Augeas.open()

lenses = Hash.new
Dir.glob("#{lensdir}/*.aug").each do |file|
  autoload = false
  mod = nil
  File.open(file).each do |line|
    if line =~ /^\s*module\s+(\w+)\s*=\s*/
      mod = $1
      break
    end
  end

  unless defined? mod
    warn "Could not determine module for file #{file}\n"
    next
  end

  includes = []
  excludes = []
  path = "/augeas/load/#{mod}"
  unless aug.match(path).empty?
    autoload = true
    lns = aug.get("#{path}/lens").sub!(/^@/,"")
    aug.match("#{path}/incl").each do |incl|
      includes << aug.get(incl).cleanpath
    end
    aug.match("#{path}/excl").each do |excl|
      excludes << aug.get(excl).cleanpath
    end
  end

  versiondir = version.nil? ? '' : "#{version}/"
  ref = "#{rootdir}docs/references/#{versiondir}lenses/files/#{File.basename(file).gsub('.','-')}.html"

  lenses[mod] = {
    :lens => lns,
    :autoload => autoload,
    :incl => includes,
    :excl => excludes,
    :ref  => ref,
  }
end

if format == 'shell'
  lenses.keys.sort.each do |lns|
    autoload = lenses[lns][:autoload]
    includes = lenses[lns][:incl]
    excludes = lenses[lns][:excl]
    puts "Lens #{lns}: \n"
    puts "   autoload: #{autoload}\n"
    puts "   incl: #{includes.join(', ')}\n" unless includes.empty?
    puts "   excl: #{excludes.join(', ')}\n" unless excludes.empty?
  end
elsif format == 'rst'
  puts ".. -*- rst -*-
   restindex
     initialheaderlevel: 2
     page-title: Stock Lenses
     encoding: utf8
   /restindex\n\n

=============
Stock lenses
=============

This is the list of all current stock lenses shipped with Augeas,
together with their default includes and excludes.

"

  if lenses.empty?
    puts "No lenses found in this release"
  else
    lens_max = lenses.keys.max {|a,b| a.length <=> b.length }.length+2 # 2 = `
    all_ref = []
    lenses.each_key { |l| all_ref << lenses[l][:ref] }
    ref_max = all_ref.flatten.max {|a,b| a.length <=> b.length }.length+4 # 4 =  <>`_
    all_incl = []
    lenses.each_key { |l| all_incl << lenses[l][:incl] }
    if all_incl.flatten.max
      incl_max = all_incl.flatten.max {|a,b| a.length <=> b.length }.length+8 # 8 = Includes
    else
      incl_max = 8
    end
    all_excl = []
    lenses.each_key { |l| all_excl << lenses[l][:excl] }
    if all_excl.flatten.max
      excl_max = all_excl.flatten.max {|a,b| a.length <=> b.length }.length+8 # 8 = Excludes
    else
      excl_max = 8
    end

    puts "+#{'-' * (lens_max + ref_max)}+#{'-' * 8}+#{'-' * incl_max}+#{'-' * excl_max}+\n"
    puts "|%-#{lens_max + ref_max}s|%-8s|%-#{incl_max}s|%-#{excl_max}s|\n" %
      [ 'Lens', 'Autoload', 'Includes', 'Excludes' ]
    puts "+#{'=' * (lens_max + ref_max)}+#{'=' * 8}+#{'=' * incl_max}+#{'=' * excl_max}+\n"

    lenses.keys.sort.each do |lns|
      autoload = lenses[lns][:autoload]
      ref = lenses[lns][:ref]
      includes = lenses[lns][:incl]
      excludes = lenses[lns][:excl]
      height = [includes.length, excludes.length].max
      puts "|%-#{lens_max + ref_max}s|%-8s|%-#{incl_max}s|%-#{excl_max}s|\n" %
        [ "`#{lns} <#{ref}>`_", autoload,
            includes[0] ? "- ``#{includes[0]}``" : '',
            excludes[0] ? "- ``#{excludes[0]}``" : '' ]
      for i in 1..height-1
        puts "|%-#{lens_max + ref_max}s|%-8s|%-#{incl_max}s|%-#{excl_max}s|\n" %
          [ '', '', '',
            includes[i] ? "- ``#{includes[i]}``" : '',
            excludes[i] ? "- ``#{excludes[i]}``" : '' ]
      end
      puts "+#{'-' * (lens_max + ref_max)}+#{'-' * 8}+#{'-' * incl_max}+#{'-' * excl_max}+\n"
    end
  end
elsif format == 'html'
  puts "<html><head>"
  puts "<style type='text/css'>

    table {
    width:90%;
    border-top:1px solid #e5eff8;
    border-right:1px solid #e5eff8;
    margin:1em auto;
    border-collapse:collapse;
    }
    td {
    color:#678197;
    border-bottom:1px solid #e5eff8;
    border-left:1px solid #e5eff8;
    padding:.3em 1em;
    text-align:center;
    }
</style>"
  puts "</head><body>"
  puts "<table><thead>"
  puts "<th>Lens</th><th>Autoload</th><th>Includes</th><th>Excludes</th>"
  puts "</thead>"
  puts "<tbody>"
  lenses.keys.sort.each do |lns|
    autoload = lenses[lns][:autoload]
    includes = lenses[lns][:incl]
    excludes = lenses[lns][:excl]
    puts "<tr>\n"
    puts "  <td>#{lns}</td>\n"
    puts "  <td>#{autoload}</td>\n"
    puts "  <td>#{autoload ? includes.join('<br />') : 'N/A'}</td>\n"
    puts "  <td>#{autoload ? excludes.join('<br />') : 'N/A'}</td>\n"
    puts "</tr>\n"
  end
  puts "</tbody></table>"
  puts "</body></html>"
end
