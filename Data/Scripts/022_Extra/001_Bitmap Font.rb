def csvGetFields(str)
  str=str.dup
  ret=[]
  loop do
    field=pbCsvField!(str)
    if field==nil || field==""
      return ret
    end
    ret.push(field)
  end
end

def getBitmapFontRecords(filename)
  records={}
  # rr=[]
  Compiler.pbCompilerEachPreppedLine(filename) {|line, lineno|
    record=record = Compiler.get_csv_record(line, [0,"suiuI"])
    record[0] = " " if record[0] == "" # have to hardcode it that way
    # checking optional value
    if !record[4]
      record[4]=record[1]+record[3]
    end
    records[record[0]]=[
      # Offset from end of last glyph to start of this glyph
      record[1]-record[2],
      # Offset from end of this glyph to start of next glyph
      record[4]-(record[1]+record[3]),
      record[1], # source start X
      record[3]   # source width
    ]
  }
  return records
end

##################
#
#   Bitmap Font Class
#

class BitmapFont
  def initialize(bmfont)
    @bmfont = bmfont
    @bitmap=Bitmap.new("Graphics/Pictures/"+bmfont+".png")
    @records=getBitmapFontRecords("Graphics/Pictures/"+bmfont+".txt")
  end
  
  def textSize(string)
    x=0
    textEndX=0
    records=@records
    string.scan(/./m){|c|
      rec=records[c]
      next if !rec
      x+=rec[0] # move x by offset from end of last glyph
      x+=rec[3] # add glyph width
      textEndX=x # set total width to x
      x+=rec[1] # add offset from end of this glyph
    }
    return Rect.new(0,0,textEndX,@bitmap.height)
  end
  
  def drawText(bitmap,x,y,width,height,string,alignment=0,opacity=255)
    return if !string || string.length==0
    positions=[]
    records=@records
    realEndX=x+width
    realEndY=y+height
    return if y>=bitmap.height || height<=0
    return if x>=bitmap.width || width<=0
    dstY=y+(height/2)-(@bitmap.height/2)
    srcHeight=height<@bitmap.height ? height : @bitmap.height
    textStartX=x
    first=true
    textEndX=x
    string.scan(/./m){|c|
      rec=records[c]
      next if !rec
      x+=rec[0] # move x by offset from end of last glyph
      textStartX=x if first
      first=false
      break if x>=realEndX || y>=realEndY
      endx=x+rec[3] # x plus glyph width
      endx=width if endx>realEndX
      next if x>=endx
      positions.push([
         # destination
         x,dstY,
         # source
         Rect.new(rec[2],0,endx-x,srcHeight)
      ])
      x+=rec[3] # add glyph width
      textEndX=x
      x+=rec[1] # add offset from end of this glyph
    }
    totalWidth=textEndX-textStartX
    offset=0
    if alignment==1
       offset=(width/2)-(totalWidth/2)
    elsif alignment==2
       offset=width-totalWidth   
    end
    for pos in positions
      bitmap.blt(
       pos[0]+offset,pos[1],@bitmap,pos[2]
      )
    end
  end
end

module BitmapFontCache
  @cache={}
  def self.load(name)
     if @cache.include?(name)
        return @cache[name]
     end
     bmfont=nil
     begin
        bmfont=BitmapFont.new(name)
     rescue
        bmfont=nil
     end
     @cache[name]=bmfont
     return bmfont
  end
end

class Font
  class << self  
    if !defined?(petero_bitmapfont_exist?)
      alias petero_bitmapfont_exist? exist?
      def exist?(name)
        return true if BitmapFontCache.load(name)
        return petero_bitmapfont_exist?(name)
      end
    end
  end  
    
  
  
  def checkBitmapFont(name)
    return nil if !name
    if name.is_a?(Array)
      for i in name
        bmfont=BitmapFontCache.load(i)
        return bmfont if bmfont
      end
      return nil
    else
      return BitmapFontCache.load(name)
    end
  end
   
  def bitmapFont
    return checkBitmapFont(self.name)
  end
end

class Bitmap
  if !defined?(petero_bitmapfont_text_size)
     alias petero_bitmapfont_text_size text_size
     alias petero_bitmapfont_draw_text draw_text
  end
  def text_size(str)
    bmfont=self.font.bitmapFont
    if bmfont
      return bmfont.textSize(str)
    else
      return petero_bitmapfont_text_size(str)
    end
  end
  def draw_text(*args)
    bmfont=self.font.bitmapFont
    if bmfont
      if args.length==2 || args.length==3
       rc=args[0]
       bmfont.drawText(self,rc.x,rc.y,rc.width,rc.height,
          args[1],args[2] ? args[2] : 0)
      elsif args.length==5 || args.length==6
       bmfont.drawText(self,args[0],args[1],args[2],args[3],
         args[4],args[5] ? args[5] : 0)    
      end
    else
      return petero_bitmapfont_draw_text(*args)    
    end
  end
end