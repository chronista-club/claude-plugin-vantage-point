---
description: 会話文脈からローカルLLM(LM Studio)で日本語セッション名を生成し /rename 用に提示
allowed-tools: Bash
---

# Rename Session — 日本語セッション名をローカルLLMで生成

現在の会話の主題から、LM Studio 上のローカルモデルで簡潔な**日本語セッション名**を生成し、
`/rename` で確定できる形で提示する。生成はローカル完結（オフライン・会話内容を外部に出さない）。

## 手順

1. **文脈要約**: 直近の会話の主題を、日本語 1〜2 文で簡潔に要約する（この会話の文脈から抽出）。

2. **タイトル生成**: 下記を実行し、稼働中のローカルモデルに要約を渡して日本語タイトルを得る。
   `SUMMARY` に手順 1 の要約を入れること。

   ```bash
   SUMMARY="（ここに手順1の日本語要約を入れる）"

   # 稼働中モデルを動的取得（qwen-coder 以外でも動くように）
   MODEL=$(curl -s http://localhost:1234/v1/models \
     | python3 -c 'import sys,json;print(json.load(sys.stdin)["data"][0]["id"])' 2>/dev/null)
   [ -z "$MODEL" ] && { echo "⚠ LM Studio が応答しません（未起動 or モデル未ロード）"; exit 0; }

   PAYLOAD=$(MODEL="$MODEL" SUMMARY="$SUMMARY" python3 -c 'import json,os; print(json.dumps({
     "model": os.environ["MODEL"],
     "messages": [
       {"role":"system","content":"会話に短い日本語タイトルを付ける。全角15字以内・体言止め・記号や引用符なし・タイトルのみ1行で出力。"},
       {"role":"user","content": os.environ["SUMMARY"]}
     ],
     "temperature": 0.3, "max_tokens": 40
   }))')

   curl -s http://localhost:1234/v1/chat/completions \
     -H "Content-Type: application/json" -d "$PAYLOAD" \
     | python3 -c 'import sys,json; print(json.load(sys.stdin)["choices"][0]["message"]["content"].strip())'
   ```

3. **提示**: 生成タイトルを示し、次のように案内する:
   > このセッション名を確定するには `/rename <生成タイトル>` を実行してください（ローカル書き込み・一瞬）。

## 備考

- **完全ローカル**: 命名にクラウド LLM を使わない。機密セッションでも安心して使える。
- **適用が速い理由**: `/rename` は `~/.claude/sessions/<pid>.json` の `name` を書き換えるだけのローカル
  処理で、サーバー通信を伴わない（`nameSource` が `user` になり自動再生成に上書きされない）。
- **前提**: LM Studio (`localhost:1234`) 起動 + 任意のチャット対応モデルがロード済みであること。
