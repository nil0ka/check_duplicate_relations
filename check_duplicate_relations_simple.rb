#!/usr/bin/env ruby

# 重複した関連定義をチェックするスクリプト
# 使用方法:
#   ruby check_duplicate_relations_simple.rb                    # 全モデルファイルをチェック
#   ruby check_duplicate_relations_simple.rb path/to/file.rb    # 特定ファイルをチェック

class DuplicateRelationChecker
  RELATION_TYPES = %w[belongs_to has_one has_many has_and_belongs_to_many].freeze

  def self.check_file(file_path)
    relations = {}
    duplicates = []
    
    File.readlines(file_path).each_with_index do |line, index|
      line_number = index + 1
      
      RELATION_TYPES.each do |relation_type|
        if match = line.match(/^\s*#{relation_type}\s+:(\w+)/)
          relation_name = match[1]
          key = "#{relation_type}:#{relation_name}"
          
          relations[key] ||= []
          relations[key] << {
            line_number: line_number,
            content: line.strip,
            relation_type: relation_type,
            relation_name: relation_name
          }
        end
      end
    end
    
    # 重複をチェック
    relations.each do |key, lines|
      if lines.length > 1
        duplicates << {
          relation_name: lines.first[:relation_name],
          relation_type: lines.first[:relation_type],
          lines: lines
        }
      end
    end
    
    duplicates
  end

  def self.check_all_models(root_path = '.')
    model_files = Dir.glob("#{root_path}/app/models/**/*.rb")
    total_duplicates = 0

    model_files.each do |file_path|
      duplicates = check_file(file_path)
      next if duplicates.empty?

      puts "=" * 60
      puts "ファイル: #{file_path}"
      puts "=" * 60
      
      duplicates.each do |duplicate|
        total_duplicates += 1
        puts "#{duplicate[:relation_type]} :#{duplicate[:relation_name]} (重複)"
        duplicate[:lines].each do |line_info|
          puts "  行 #{line_info[:line_number]}: #{line_info[:content]}"
        end
        puts
      end
    end

    if total_duplicates == 0
      puts "重複した関連定義は見つかりませんでした。"
    else
      puts "=" * 60
      puts "合計 #{total_duplicates} 個の重複した関連定義が見つかりました。"
    end
  end
end

# メイン処理
if __FILE__ == $0
  if ARGV.length > 0
    file_path = ARGV[0]
    if File.exist?(file_path)
      duplicates = DuplicateRelationChecker.check_file(file_path)
      
      if duplicates.any?
        puts "ファイル: #{file_path}"
        puts "=" * 50
        duplicates.each do |duplicate|
          puts "#{duplicate[:relation_type]} :#{duplicate[:relation_name]} (重複)"
          duplicate[:lines].each do |line_info|
            puts "  行 #{line_info[:line_number]}: #{line_info[:content]}"
          end
          puts
        end
      else
        puts "#{file_path} に重複した関連定義は見つかりませんでした。"
      end
    else
      puts "エラー: ファイル '#{file_path}' が見つかりません。"
      exit 1
    end
  else
    puts "モデルファイルの重複関連定義をチェックしています..."
    puts
    DuplicateRelationChecker.check_all_models
  end
end
