# check_duplicate_relations
This is a tool that finds duplicate relations.

## 1. check_duplicate_relations_simple.rb (推奨)

シンプルで効率的なスクリプトです：

使用方法:

```
# 特定のファイルをチェック
ruby check_duplicate_relations_simple.rb app/models/role_template.rb

# 全モデルファイルをチェック
ruby check_duplicate_relations_simple.rb
```

機能:

* belongs_to, has_one, has_many, has_and_belongs_to_many の重複をチェック
* 行番号付きで重複箇所を表示
* 軽量で高速

## 2. check_duplicate_relations.rb (高機能版)

より詳細な機能を持つスクリプトです：

* モデルファイルの自動検出
* より詳細な出力
* lib/ ディレクトリも対象
