#!/bin/bash

# Author: Li Ji
# Date: 2025-02-14
# Description: 使用ADCP作为benchmark，裁剪GPPD导出的子集，并计算字段级 Coverage

export LC_ALL=C

# --- 1. 输入文件配置  ---
PUB_BENCHMARK="benchmark_pub_keys.txt" 
APP_BENCHMARK="benchmark_app_keys.txt"
EXTRA_PUB_KEYS="gppd_only_pub_keys.txt"
EXTRA_APP_KEYS="gppd_only_app_keys.txt"

# 自动生成的中间变量文件名
OFFICIAL_PUB="tmp_official_pub.txt"
OFFICIAL_APP="tmp_official_app.txt"

DATA_DIR="."
OUT_DIR="./CN_records_from_GPPD"
REPORT_FILE="GPPD_Final_Coverage_Report.txt"

mkdir -p "$OUT_DIR"

# --- 2. 生成官方基准 (Official = Benchmark - Extra) ---
echo "正在计算官方基准 (Denominator)..."

# 使用 awk 进行集合减法：读取 Extra 到内存，遍历 Benchmark，输出不在 Extra 中的行
awk 'NR==FNR{a[$1];next} !($1 in a)' "$EXTRA_PUB_KEYS" "$PUB_BENCHMARK" > "$OFFICIAL_PUB"
awk 'NR==FNR{a[$1];next} !($1 in a)' "$EXTRA_APP_KEYS" "$APP_BENCHMARK" > "$OFFICIAL_APP"

total_pub_n=$(wc -l < "$OFFICIAL_PUB")
total_app_n=$(wc -l < "$OFFICIAL_APP")
extra_pub_n=$(wc -l < "$EXTRA_PUB_KEYS")
extra_app_n=$(wc -l < "$EXTRA_APP_KEYS")

# 初始化报告表头
printf "%-20s | %-10s | %-15s | %-15s | %-12s | %-12s | %-12s\n" \
    "File Name" "Key Type" "Matched(ADCP)" "Denominator" "Coverage(%)" "Extra(GPPD)" "Total(Bench)" > "$REPORT_FILE"
echo "------------------------------------------------------------------------------------------------------------------------" >> "$REPORT_FILE"

# --- 3. 定义文件配置 (文件名|类型|表头) ---
FILES_CONFIG=(
    "cn_abstract.txt|PUB|publication_number|language|truncated|text"
    "cn_backward.txt|PUB|publication_number|cited_publication_number|cited_application_number|type|category"
    "cn_date.txt|PUB|publication_number|application_number|publication_date|filing_date|grant_date|priority_date"
    "cn_embedding.txt|PUB|publication_number|embedding"
    "cn_examiner.txt|PUB|publication_number|examiner_name|level"
    "cn_npc.txt|PUB|publication_number|npl_text|category"
    "cn_title.txt|PUB|publication_number|language|truncated|text"
    "cn_top_term.txt|PUB|publication_number|top_terms"
    "cn_assignee.txt|APP|application_number|assignee"
    "cn_child.txt|APP|application_number|child_application_number|type"
    "cn_inventor.txt|APP|application_number|inventor"
    "cn_ipc.txt|APP|application_number|ipc_code"
)

# --- 4. 核心循环 ---
for config in "${FILES_CONFIG[@]}"; do
    IFS='|' read -r f_name key_type header_str <<< "$config"
    
    if [ ! -f "$DATA_DIR/$f_name" ]; then
        echo "警告: 找不到文件 $f_name，跳过。"
        continue
    fi

    echo "正在处理: $f_name ..."

    # 确定当前文件对应的索引和分母
    if [ "$key_type" == "PUB" ]; then
        BENCH_IDX="$PUB_BENCHMARK"
        OFFICIAL_IDX="$OFFICIAL_PUB"
        DENOM="$total_pub_n"
        EXTRA_N="$extra_pub_n"
    else
        BENCH_IDX="$APP_BENCHMARK"
        OFFICIAL_IDX="$OFFICIAL_APP"
        DENOM="$total_app_n"
        EXTRA_N="$extra_app_n"
    fi

    # A. 对齐裁剪 (Benchmark = ADCP + GPPD_Only)
    # 直接根据 benchmark_ids 过滤原始数据
    echo "$header_str" > "$OUT_DIR/$f_name"
    awk -F'|' 'NR==FNR{a[$1]; next} ($1 in a)' "$BENCH_IDX" "$DATA_DIR/$f_name" >> "$OUT_DIR/$f_name"

    # B. 统计 Unique Matched
    # 统计子集中有多少唯一 ID 属于官方集合
    matched_unique=$(tail -n +2 "$OUT_DIR/$f_name" | cut -d'|' -f1 | awk 'NR==FNR{a[$1];next} ($1 in a){if(!seen[$1]++) count++} END{print count+0}' "$OFFICIAL_IDX" -)
    
    # C. 计算指标
    coverage=$(awk "BEGIN {if($DENOM==0) printf \"%.4f\", 0; else printf \"%.4f\", ($matched_unique/$DENOM)*100}")
    total_expected=$((DENOM + EXTRA_N))

    # D. 写入报告
    printf "%-20s | %-10s | %-15s | %-15s | %-12s | %-12s | %-12s\n" \
        "$f_name" "$key_type" "$matched_unique" "$DENOM" "$coverage%" "$EXTRA_N" "$total_expected" >> "$REPORT_FILE"
done

# 清理临时生成的官方索引文件
rm "$OFFICIAL_PUB" "$OFFICIAL_APP"