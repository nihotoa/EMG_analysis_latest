# EMG解析および筋シナジー解析のためのフレームワーク

![MATLAB R2022b+](https://img.shields.io/badge/MATLAB-R2022b%2B-blue.svg)

## 概要
このリポジトリは筋電図（EMG）データ解析と筋シナジー解析のためのスクリプトを提供します。

## 機能と特徴

このフレームワークでは以下のことが可能です：

- **データ統合：** 同じ実験日の複数あるデータファイルを一つのデータファイルに集約
- **信号処理：** カスタマイズ可能なパラメータでEMGデータをフィルタリング
- **イベントタイミング解析：** 行動同期のためのイベントタイミングデータ生成
- **試行分割：** 個々の試行のEMGデータを抽出して保存
- **可視化：** 各実験日の筋活動パターンを明確に可視化
- **相関解析：** 相互相関分析を用いてEMG信号間の類似性を定量化・可視化
- **シナジー抽出：** 非負値行列因子分解（NMF）を用いてEMGデータセットから筋シナジーを抽出
- **シナジー可視化：** 抽出された筋シナジーの可視化
- **性能指標：** 説明分散（VAF）と各筋シナジー間の類似性を定量化し可視化

## はじめに

### 事前準備

解析を開始する前に、以下のセットアップ手順を完了してください：

#### 1. 環境セットアップ

- **MATLABの要件：**
  - MATLAB R2022b以降
  - Signal Processing Toolbox
  - Statistics and Machine Learning Toolbox

- **必要なパスの追加：**
  - MATLABを起動
  - リポジトリのルートディレクトリに移動
  - リポジトリのルートディレクトリをMATLABのパスに追加
  - リポジトリのルートディレクトリを右クリックして「パスに追加」→「選択したディレクトリとサブディレクトリ」を選択
  - または、以下のコマンドを実行：
    ```matlab
    % リポジトリルートの実際のパスに置き換えてください
    addpath(genpath('/path/to/EMG_analysis_latest'));
    ```

#### 2. データ準備
- **データ構成：**
  - リポジトリのルート(`modules`および`executeFunctions`と同じ階層)に`useDataFold`ディレクトリを作成
  - `useDataFold`内に、サル名のサブディレクトリを作成（例：`useDataFold/Hugo`）
  - 各サルのサブディレクトリ内に、実験データの入った実験日の日付ディレクトリを配置

#### 3. リポジトリ構造

リポジトリは以下のように構成されています：

```
EMG_analysis_latest/
├── README.md                # このドキュメントファイル
├── executeFunctions/        # 主要な実行スクリプトが入っているディレクトリ
│   ├── saveLinkageInfo.m    
│   ├── prepareEMGAndTimingData.m  
│   └── ...                  
├── modules/                 # 自作の関数が入っているディレクトリ
│   ├── dataPreparation/     
│   ├── nmfAnalysis/         
│   └── ...                  
├── saveFold/                # 解析の出力結果が保存されるディレクトリ（自動生成）
│   └── [MonkeyName]/        # 例：Hugo
│       └── data/            # 処理結果が含まれる
└── useDataFold/             # 入力データディレクトリ（手動作成）
    └── [MonkeyName]/        # 例：Hugo
        └── [YYYYMMDD]/      # 日付別ディレクトリ（例：20250311）
            └── ...          # 生データファイル
```

> **注意：** `saveFold`ディレクトリは解析スクリプトを実行すると自動的に作成されます。手動で作成する必要はありません。ユーザーが作成する必要があるのは`useDataFold`ディレクトリとそのサブディレクトリのみです。

### 解析ワークフロー

EMG解析と筋シナジー抽出の実行手順を以下に図示します：

<div style="text-align: center; margin: 20px 0;">
  <img src="https://private-user-images.githubusercontent.com/108604104/427816327-3ccecd42-707a-4bb0-aafe-4ac61672a230.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDMxMjk0ODksIm5iZiI6MTc0MzEyOTE4OSwicGF0aCI6Ii8xMDg2MDQxMDQvNDI3ODE2MzI3LTNjY2VjZDQyLTcwN2EtNGJiMC1hYWZlLTRhYzYxNjcyYTIzMC5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMzI4JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDMyOFQwMjMzMDlaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1mYTEyMzIwN2NjNTc2YTI2ZTAxNjFlYmE4ZDM5NzBhOWM4NDQ5Mzc0YTYyMzk0NjNlY2JmMGI5NzgxMGYyODA5JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.WJSmJ2MSiAMxCFqtvWPGmnr_7yQcU2dfRKyHSN1L1_I" alt="EMG解析ワークフロー" style="max-width: 100%; width: 70%; height: auto;">
</div>

各スクリプトの使用方法と処理手順の詳細については、各ファイルの先頭にあるドキュメントを参照してください。

## 各スクリプトのドキュメント規格

このリポジトリの各スクリプトのドキュメントは、`modules`ディレクトリ内にあるか`executeFunctions`ディレクトリ内にあるかに寄ってドキュメントの形式が異なります：

### `executeFunctions`ディレクトリのドキュメント

`executeFunctions`ディレクトリ内のスクリプトは、以下の形式に従って冒頭にドキュメントが書かれています：

| セクション | 説明 |
|---------|-------------|
| **your operation** | 関数を実行するために必要な手順 |
| **role of this code** | 全体的な解析パイプラインにおける目的と機能 |
| **saved data location** | 関数実行時に出力データが保存される場所 |
| **execution procedure** | 前後の実行関数の名前 |

### `modules`ディレクトリのドキュメント

`modules`ディレクトリ内のスクリプトは、以下の形式に従って冒頭にドキュメントが書かれています:

| セクション | 説明 |
|---------|-------------|
| **Function Description** | 関数の詳細な説明 |
| **Input Arguments** | 関数が受け入れるすべてのパラメータの説明 |
| **Output Arguments** | 関数が返すデータの説明 |
| **Caution** | 関数使用に関する重要な注意点や警告 |

## 注意点

> ⚠️ **ディスク容量に関する注意：** この解析は大容量のデータを使用します。このリポジトリを使用する際は、十分な空きディスク容量があることを確認してください。

## 連絡先

質問等ありましたら、以下にお問い合わせください：

**メール**: otanaohito1102@gmail.com