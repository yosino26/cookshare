# README
# 🍳 CookShare

**設計・テスト・保守性を意識して構築した、レシピ共有SNSアプリ**

家庭料理を中心に、**レシピをSNS感覚で共有・交流できる**Webアプリです。  
料理初心者・主婦層・レシピを記録したい人を対象に、  
「同じ趣味・趣向の人と気軽につながれる場」を目指しています。

URL: [https://cookshare-ygta.onrender.com/](https://cookshare-ygta.onrender.com/)

---

## 📘 アプリ概要（目的・対象・できること）

**CookShare** は、料理を通じて人とつながるSNSです。  
ユーザーは自分のレシピを投稿し、他の人の投稿を閲覧・コメント・お気に入り登録できます。  
管理者機能や通報システムを備え、安全なコミュニティ運営を実現しています。

- 👩‍🍳 **対象ユーザー**  
  - 料理初心者、主婦層、料理を趣味とする一般ユーザー  
  - 自分のレシピを記録・共有したい人  
  - 同じ趣味を持つ人と交流したい人

- 🎯 **このアプリでできること**  
  - レシピの投稿・検索・評価・コメント  
  - お気に入り登録・フォローによる交流  
  - 管理者による違反通報の確認・対応  
  - 自分の料理記録として活用可能

- 💡 **開発の目的**  
  - Ruby on RailsによるフルスタックWeb開発を体系的に学習  
  - 設計・テスト・保守を意識した開発プロセスの実践  
  - 技術理解と再現性のある設計力の向上
---

## 🚀 URL情報

| 種類 | URL |
|------|------|
| **アプリURL** | https://cookshare-ygta.onrender.com/ |
| **GitHubリポジトリ** | https://github.com/yosino26?tab=repositories |

> ※テストアカウント  
> ：user1@example.com / userpass1

---

## 🛠 使用技術

| カテゴリ | 技術 |
|-----------|------|
| フレームワーク | Ruby on Rails 7.1 |
| フロントエンド | Bootstrap 5 / Turbo |
| データベース | PostgreSQL |
| 認証 | Devise |
| ストレージ | Active Storage（画像投稿） |
| デプロイ | Render（無料プラン） |
| テスト | RSpec / FactoryBot / Shoulda-Matchers |

---

## 🔧 機能一覧

| 分類 | 機能 | 状況 |
|------|------|------|
| ユーザー | 登録・ログイン（Devise） | ✅ |
| | プロフィール編集 | ✅ |
| | フォロー / フォロワー機能 | ✅ |
| レシピ | 投稿・編集・削除 | ✅ |
| | 画像アップロード（ActiveStorage） | ✅ |
| | 材料・手順の動的フォーム | ✅ |
| | カテゴリ分類 / 検索 | ✅ |
| インタラクション | お気に入り / コメント / 評価(★1〜5) | ✅ |
| 管理機能 | 管理者ダッシュボード | ✅ |
| | 通報管理（一般ユーザー・管理者） | ✅ |
| | ユーザー / レシピ / コメント管理 | ✅ |
| テスト | モデル / バリデーション / 一意制約テスト | ⏳進行中 |

---
## 💡 工夫・こだわりポイント

- **管理画面の設計**  
  - 管理者専用の`Admin`名前空間を設け、アクセス制御を明確化。  
  - ダッシュボードに「未対応通報数バッジ」を実装し、運営効率を向上。

- **通報機能（Phase 32–33）**  
  - Polymorphic設計で `User / Recipe / Comment` のいずれも通報可能に。  
  - 状態管理を `enum` で管理（`pending / investigating / resolved / dismissed`）。

- **保守性を意識した構成**  
  - モデル間の依存を `Concern`（例：Reportable）に切り出し再利用性を向上。  
  - バリデーションやenum定義を明確化して不整合を防止。  
  - N+1問題対策として `includes` を徹底。

- **テストコード導入**  
  - FactoryBotとShoulda-Matchersを利用し、バリデーション・関連・一意制約を自動テスト。  
  - Phase 34ではController・Systemテストも拡充予定。

---
## 🧪 テスト・品質保証（Phase 34予定）

- Model単体テスト  
- Controller権限制御テスト  
- Systemテスト（通報フロー / 管理画面操作）  
- CSRF/XSS/SQL Injection対策確認  
- パフォーマンス最適化（N+1 / Index確認）

---

## 🌱 今後の展望

- コメント通報機能の追加（User / Recipeに加えて）  
- SNS共有・印刷機能の追加  
- ActiveStorage × S3連携による本番運用化  
- アクセシビリティ対応・UI改善

---

## 👤 作者情報

| 項目 | 内容 |
|------|------|
| **名前** | 溝内 慎吾 |
| **学習歴** | 2024年10月〜現在（約1年） |
| **使用環境** | Windows 11 + Ubuntu (WSL2) |
| **目標** | 設計と品質を重視したWebアプリ開発ができるエンジニアを目指しています。 |

---

## 🗂 ディレクトリ構成（抜粋）

```text
app/
├── controllers/
│   ├── admin/                 # 管理者画面
│   ├── reports_controller.rb  # 通報UI
│   ├── recipes_controller.rb
│   ├── comments_controller.rb
│   ├── favorites_controller.rb
│   └── follows_controller.rb
├── models/
│   ├── concerns/
│   │   └── reportable.rb
│   ├── report.rb
│   ├── recipe.rb
│   └── user.rb
└── views/
    ├── admin/
    ├── reports/
    ├── recipes/
    └── users/


---

このプロジェクトは個人ポートフォリオ目的で作成されています。  
学習・面接資料としての利用を目的としています。