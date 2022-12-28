
# require 'file'
# $LOAD_PATH << '.'
require 'fileutils'
require 'find'
# -*- coding: UTF-8 -*-

class UnDefineKeyItem
  def initialize(key,path)
    @key = key
    @filePath = path
  end

  def printKey
  @key
  end

  def printFilePath
    @filePath
    end

  def to_s
    keystring = @key.decoder('utf-8')
    "未定义key:#{keystring},filePath:#{@filePath}"  # 对象的字符串格式
  end
end

class LanguageModel
  
  def initialize
    @key = ''
    @map = {"key"=>"key"}
  end

  def setKey(key)
    @key = key
  end

  def setLanguageValue(newKey,value)
    @map.store(newKey,value)
  end

  def to_s
    "(key:#{@key},map:#{@map})"  # 对象的字符串格式
  end
end

class LocalizedScan
  @@defineKeyDic = Hash.new
  @@undefineKeyDic = Hash.new
  #把资源包中的key都load进内存

  def initialize
    
  end

  def self.loadBundleKey
    bundPath = nil
    #查找bundle路径
    Find.find("./") do |filePath|
      if  filePath.end_with?("LMFramework.bundle")
        bundPath = filePath
        break
      end
    end
    puts bundPath
    Find.find(bundPath) do |filePath|
      if filePath.end_with?("Localizable.strings")
        self.findKey(filePath)
      end
    end
  end

    #提取出key
  def self.findKey(filePath)
      if File.exist?(filePath) == false
        puts "#{filePath} 不存在-"
        return
      end
      str = filePath.split('/')[-2]
      lang =  str.split('.')[0]
      # puts  "lang:#{lang}"
      block = ""
      File.open(filePath,"r").each_line{|line|
        block += line
        if line.end_with?("\";\n") and line.end_with?("\\\";\n") == false
          left = block.index('"')
          right = block.index('"',left+1)
          key = block[left+1...right]
          left = block.index('"',right+1)
          right = block.rindex('"')
          value = block[left+1...right]
          if @@defineKeyDic[key] == nil
            model = LanguageModel.new
            model.setKey key
            @@defineKeyDic[key] = model
          else
            # puts lang,value
            model = @@defineKeyDic[key]
            model.setLanguageValue(lang,value)
          end
          block = ""
        end
      }
  end

  def self.scan
  
    Find.find ("./") do |fileName|
#      puts fileName
       if fileName.end_with?".m"
         self.scanKeyInOcCode(fileName)
       elsif fileName.end_with?".swift"
         self.scanKeyInSwiftCode(fileName)
       end
    end
  end

  def self.scanKeyInOcCode(path)

    file = File.open(path,"r:utf-8") do |file|
      block = ""
      file.each_line do |line|
        block += line
        if line.end_with?";\n"
          #处理block
          self.filterKeyInOcBLock(block,path)
          block = ""
        end
      end
    end
    file.close

  end

  def self.scanKeyInSwiftCode(path)
  
    file = File.open(path,"r:utf-8") do |file|
      block = ""
      file.each_line do |line|
        block += line
        if line.end_with?"\n"
          #处理block
          self.filterKeyInSwiftBLock(block,path)
          block = ""
        end
      end
    end
    file.close

  end
  
  def self.filterKeyInSwiftBLock(block,filePath)
    keywords = ['LMBundleNSLocalizedString(','LHLocalizedTool.localizedString(forKey:']
    keywords.each do |keyword|
      tempBlock = block
      while tempBlock.index(keyword) != nil do
        #左引号
        left = tempBlock.index(keyword)
        # puts left
        # puts tempBlock[left]
        left = tempBlock.index('"',left+1)
        right = tempBlock.index('"',left+1)
        # puts right
        # puts tempBlock[right]
        key = tempBlock[left+1...right]
        if @@defineKeyDic[key] == nil
          print 'swift未定义的key:',key,"\n"
          item = UnDefineKeyItem.new(key,filePath)
          @@undefineKeyDic[key] = item
        end
        tempBlock = tempBlock[right+1..tempBlock.length-1]
      end
    end
  end

  def self.filterKeyInOcBLock(block,filePath)
    keywords = ['localizedStringForKey:@"',
                'LMCALanuage(@"',
                'LMCTLanuage(@"',
       'LMIrcodeLocalizedString(@"',
      'LMLTLanuage(@"',
       'LMMDLocalizedString(@"',
      'kLMPositionFrameworkNSLocalized(@"']
    keywords.each do |keyword|
      tempBlock = block
      while tempBlock.index(keyword) != nil do
        #左引号
        left = tempBlock.index(keyword) + keyword.length-1
        # puts left
        # puts tempBlock[left]
        right = tempBlock.index('"',left+1)
        # puts right
        # puts tempBlock[right]
        key = tempBlock[left+1...right]
        #
        if @@defineKeyDic[key] == nil
          # print '未定义的key:',key,"\n"
          item = UnDefineKeyItem.new(key,filePath)
          @@undefineKeyDic[key] = item
        end
        tempBlock = tempBlock[right+1..tempBlock.length-1]
      end
    end
  end

  def self.pipLine
    self.loadBundleKey
    self.scan
    # @@defineKeyDic.each_value do |model|
    #   puts model
    # end

    num = 0
    @@undefineKeyDic.each_value do |item|
      num += 1
      puts "#{num}:#{item.printKey} filepath:#{item.printFilePath}"
    end
  end

end


# str = 'localizedStringForKey:@"key"'
# LocalizedScan.filterKeyInBLock(str)

