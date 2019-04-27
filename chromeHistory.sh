#!/bin/sh

#
# Chromeの閲覧履歴をfzfで絞り込んで選択したURLをChromeで開くスクリプト
#
# [使い方]
# ▶sh chromeHistory.sh [PATTERN or -d]
# 第一引数にgrepしたい単語を入力することが可能。grep時はURL、タイトル、日付込の出力からgrepする。
# -d を指定した場合、日付を選択して表示することが可能。
#
# [思想]
# sqliteで絞れるところは絞る。絞りきれなかった部分をshellコマンドで整形する。
#

# ChromeのDBの内容をcsvで一時保存するパス
PATH_CHROME_HISTORY=/Users/`whoami`/chrome_history.csv

function export_chrome_history() {
    local USER=`whoami`
    # Chromeを開いているとdbがロックされるのでコピーしたものを参照する
    cp ~/Library/Application\ Support/Google/Chrome/Default/History ~/

    local SQL="
    SELECT
        url,
        title,
        DATETIME(last_visit_time / 1000000 + (strftime('%s', '1601-01-01') ), 'unixepoch', '+9 hours') AS date
    FROM
        urls
    GROUP BY
        title
    ORDER BY
        date DESC
    LIMIT
        10000
    ;
    "
    # そのままSQLを流すとエラーが出るので改行を消す
    local SQL=$(echo "${SQL}" | tr '\n' ' ')

    # コマンドで参照できるようにDBの内容をcsvに書き出す
    # expect内では~が使えないのでフルパス指定。tsvで出力することも考えられたが、awkでタイトルが途中で切れる現象があったので、csv形式にした。
    expect -c "
        spawn sqlite3 /Users/$USER/History
        expect \">\"
        send \".mode csv\r\"
        expect \">\"
        send \".output $PATH_CHROME_HISTORY\r\"
        expect \">\"
        send \"$SQL\r\"
        expect \">\"
    " >/dev/null
}

function show_chrome_history() {
    local filter=${1:-""}
    local chrome_history=$(cat $PATH_CHROME_HISTORY | tr -d '"')

    # 見栄えを良くするためURLは表示しない
    local select_history=$(
        echo ",,export\n$chrome_history" \
        | grep -P "(,,export|$filter)" \
        | awk -F ',' '!a[$2]++' \
        | awk -F ',' '{print $3"\t"$2}' \
        | tr -d "\r" \
        | fzf \
        | tr -d "\n"
    )

    # terminalに出力したいときのため
    if [ `echo $select_history | tr -d " "` = "export" ]; then 
        echo "$chrome_history" \
        | grep "$filter" \
        | awk -F ',' '!a[$2]++' \
        | awk -F ',' '{print $3"\t"$2}' \
        | tr -d "\r" 
        return
    fi

    # URL取得処理
    if [ -n "$select_history" ]; then
        # 選択したものにはタイトルと日付の間のカンマが削除されており、
        # そのままだとgrepができないのでタイトルだけ抽出したものを用意
        local title=`echo "$select_history" | awk -F '\t' '{print $1}'`
        local url=`echo "$chrome_history" | grep "$title"  | head -n 1 |awk -F ',' '{print $1}'`
        open $url
    fi
}


function show_by_date() {
    local chrome_history=$(cat $PATH_CHROME_HISTORY | tr -d '"')
    # 表示したい日付を選択する
    local select_date=$(
        echo "$chrome_history" \
        | awk -F ',' '{print $3}' \
        | awk -F ' ' '{print $1}' \
        | grep -P '^[0-9]{4}-.*' \
        | sort -ur \
        | tr -d "\r" \
        | xargs -I {} gdate '+%Y-%m-%d (%a)' -d {} \
        | fzf \
        | awk -F '(' '{print $1}'
    )
    show_chrome_history $select_date
}

function main() {
    export_chrome_history
    if [ "$1" = '-d' ]; then 
        show_by_date
    else
        show_chrome_history $1
    fi
}

main $1
