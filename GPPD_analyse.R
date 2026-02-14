# Author: Li Ji
# Date: 2025-02-14
# Description: 该脚本用于分析 GPPD 数据与 ADCP 官方记录的一致性，并生成覆盖率报告。

library(tidyverse)
library(lubridate)
library(scales)

#  验证GPPD一致性 ====

##  1. 读入 ADCP (标准集) ----
# 1985-2024.06.30 的公开记录
adcp <- read_csv("/Volumes/main/data_from_cnipa/CN_Athorityfile_202406/INVENTION 19850910-20240630.csv", 
                 col_names = c("country", "number", "kind", "pub_date_adcp"),
                 col_types = "cccc") %>%
  mutate(
    # 构造标准匹配 ID: CN-85100287-A
    publication_number = str_glue("{country}-{number}-{kind}"),
    pub_date_adcp = ymd(pub_date_adcp),
    in_adcp = TRUE
  ) %>%
  select(publication_number, kind, pub_date_adcp, in_adcp)

# pdate重复的publication_number分析
dup_pnr_ids <- adcp$publication_number[duplicated(adcp$publication_number)]

multi_dates_per_pnr <- adcp %>%
  filter(publication_number %in% dup_pnr_ids) %>%
  arrange(publication_number)

# 查看结果
print(multi_dates_per_pnr)
write_delim(multi_dates_per_pnr, "multi_dates_per_pnr.txt", 
            delim = "|", quote = "none")

## 2. 读入 GPPD 数据 ----
# 读入核心 ID 表
gppd_info <- read_delim("/Volumes/main/data_from_GPPD/cn_app_pub_number.txt", 
                        delim = "|", col_names = TRUE, col_types = "cccccc")

# 读入日期表 (第3列是公开日 publication_date)
gppd_date <- read_delim("/Volumes/main/data_from_GPPD/cn_date.txt", 
                        delim = "|", col_names = TRUE, col_types = "cccccc") %>%
                        mutate(pub_date_gppd = ymd(publication_date)) %>%
                        select(publication_number, pub_date_gppd)

# 合并GPPD
gppd_merged <- gppd_info %>%
  left_join(gppd_date, by = "publication_number") %>%
  mutate(in_gppd = TRUE)

rm(gppd_date, gppd_info)

## 3. 生成 Master Key: 对齐 ----
master_key <- full_join(adcp, gppd_merged, by = "publication_number") %>%
  mutate(
    in_adcp = !is.na(in_adcp),
    in_gppd = !is.na(in_gppd),
    
    # 匹配情况
    validation_status = case_when(
      in_adcp & in_gppd  ~ "Matched",
      in_adcp & !in_gppd ~ "ADCP_Only", 
      !in_adcp & in_gppd ~ "GPPD_Only"
    ),

    # 如果 GPPD 日期缺失，则借用 ADCP 的权威日期
    final_pub_date = coalesce(pub_date_gppd, pub_date_adcp),
    pub_date_source = if_else(is.na(pub_date_gppd) & !is.na(pub_date_adcp), "Imputed_from_ADCP", "Original_GPPD")
  )


# 按照2024年6月30日的公开日进行日期对齐
benchmark_set <- master_key %>%
  filter(final_pub_date <= ymd("20240630")) %>%
  mutate(is_multi_pub_date = publication_number %in% dup_pnr_ids) 

print(table(benchmark_set$validation_status))
print(table(benchmark_set$kind))

gppd_only <- benchmark_set %>%
  filter(validation_status == "GPPD_Only") %>%
  mutate(kind_new = str_extract(publication_number, "[^-]+$")) 


print(table(gppd_only$kind_new))

# 4. 准备ADCP索引库 ----
# 提取唯一公开号集合
benchmark_pub_ids <- benchmark_set %>%
  pull(publication_number) %>%
  unique()

# 提取唯一申请号集合 [9778 missing application_number in ADCP records]
benchmark_app_ids <- benchmark_set %>%
  pull(application_number) %>%
  unique()

# 提取只在GPPD中存在的公开号集合
gppd_only_pub_ids <- benchmark_set %>%
  filter(validation_status == "GPPD_Only") %>%
  pull(publication_number) %>%
  unique()

gppd_only_app_ids <- benchmark_set %>%
  filter(validation_status == "GPPD_Only") %>%
  pull(application_number) %>%
  unique()

write_lines(benchmark_pub_ids, "benchmark_pub_ids.txt")
write_lines(benchmark_app_ids, "benchmark_app_ids.txt")
write_lines(gppd_only_pub_ids, "gppd_only_pub_keys.txt")
write_lines(gppd_only_app_ids, "gppd_only_app_keys.txt")

## 5. 导出校对后的 Master Key ----
write_delim(benchmark_set %>% select(
                publication_number, 
                application_number, 
                kind, 
                validation_status,      # 匹配情况
                in_adcp,                
                in_gppd,                 
                pub_date = final_pub_date, # 统一命名
                pub_date_source,   # pub_date 的来源（原始 GPPD 还是 ADCP 补齐）
                is_multi_pub_date       # 重复情况
            ), 
            "GPPD_ADCP_Invention_MasterKey.txt", 
            delim = "|", quote = "none")
            

## 6. 覆盖率分析 ----
# 总体覆盖率
coverage_summary <- benchmark_set %>%
  count(validation_status) %>%
  mutate(percentage = n / sum(n) * 100)

print(coverage_summary)

# 年度覆盖率
yearly_coverage <- benchmark_set %>%
  filter(in_adcp == TRUE) %>% 
  mutate(pub_year = year(pub_date_adcp)) %>%
  select(pub_year, in_gppd) %>%
  group_by(pub_year) %>%
  summarise(
    total_official = n(),
    found_in_gppd = sum(in_gppd),
    coverage_rate = found_in_gppd / total_official
  )

print(n = 40, yearly_coverage)

## 多余记录覆盖率
extra_analysis <- benchmark_set %>%
  filter(validation_status == "GPPD_Only") %>%
  count(kind) %>%
  mutate(percentage = n / sum(n) * 100)

print(extra_analysis)

# 缺失分析
missing_analysis <- benchmark_set %>%
  filter(validation_status == "ADCP_Only") %>%
  mutate(pub_year = year(pub_date_adcp)) 

print(table(missing_analysis$pub_year))
print(table(missing_analysis$kind))
