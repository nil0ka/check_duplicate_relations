#!/usr/bin/env ruby

require 'pathname'

class DuplicateRelationChecker
  RELATION_TYPES = %w[
    belongs_to
    has_one
    has_many
    has_and_belongs_to_many
  ].freeze

  def initialize(root_path = '.')
    @root_path = Pathname.new(root_path)
  end

  def check_all_models
    model_files = find_model_files
    puts "見つかったモデルファイル数: #{model_files.length}"
    duplicates_found = false

    model_files.each do |file_path|
      duplicates = check_file(file_path)
      if duplicates.any?
        duplicates_found = true
        puts "=" * 80
        puts "ファイル: #{file_path}"
        puts "=" * 80
        duplicates.each do |duplicate|
          puts "重複した関連定義: #{duplicate[:relation_name]}"
          duplicate[:lines].each do |line_info|
            puts "  行 #{line_info[:line_number]}: #{line_info[:content].strip}"
          end
          puts
        end
      end
    end

    unless duplicates_found
      puts "重複した関連定義は見つかりませんでした。"
    end
  end

  def check_file(file_path)
    relations = extract_relations(file_path)
    find_duplicates(relations)
  end

  private

  def find_model_files
    model_paths = [
      @root_path / 'app' / 'models' / '**' / '*.rb',
      @root_path / 'lib' / '**' / '*.rb'
    ]

    model_files = []
    model_paths.each do |pattern|
      model_files.concat(Dir.glob(pattern.to_s))
    end

    model_files.select do |file|
      # モデルファイルかどうかの簡単な判定
      content = File.read(file)
      content.match?(/class\s+\w+.*<.*Base|ActiveRecord::Base|ApplicationRecord/)
    end
  end

  def extract_relations(file_path)
    relations = {}
    
    File.readlines(file_path).each_with_index do |line, index|
      line_number = index + 1
      
      RELATION_TYPES.each do |relation_type|
        if match = line.match(/^\s*#{relation_type}\s+:(\w+)/)
          relation_name = match[1]
          key = "#{relation_type}:#{relation_name}"
          
          relations[key] ||= []
          relations[key] << {
            line_number: line_number,
            content: line,
            relation_type: relation_type,
            relation_name: relation_name
          }
        end
      end
    end
    
    relations
  end

  def find_duplicates(relations)
    duplicates = []
    
    relations.each do |key, lines|
      if lines.length > 1
        relation_name = lines.first[:relation_name]
        duplicates << {
          relation_name: relation_name,
          lines: lines
        }
      end
    end
    
    duplicates
  end
end

# スクリプトの使用方法
if __FILE__ == $0
  if ARGV.length > 0
    # 特定のファイルをチェック
    file_path = ARGV[0]
    if File.exist?(file_path)
      checker = DuplicateRelationChecker.new
      duplicates = checker.check_file(file_path)
      
      if duplicates.any?
        puts "ファイル: #{file_path}"
        puts "=" * 50
        duplicates.each do |duplicate|
          puts "重複した関連定義: #{duplicate[:relation_name]}"
          duplicate[:lines].each do |line_info|
            puts "  行 #{line_info[:line_number]}: #{line_info[:content].strip}"
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
    # 全モデルファイルをチェック
    puts "モデルファイルの重複関連定義をチェックしています..."
    puts
    
    checker = DuplicateRelationChecker.new
    checker.check_all_models
  end
end
