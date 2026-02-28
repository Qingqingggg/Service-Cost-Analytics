# analysis.R
# Service Cost Analytics 
# Author: Qingqing Ye

library(tidyverse)
library(lubridate)
library(scales)
library(janitor)
library(ggthemes)

# ---------------------------
# parameters
# ---------------------------

BMW_BLUE <- "#0066B1"
BMW_BLUE_DARK <- "#003D78"

theme_set(
  theme_economist_white() +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11),
      panel.grid.minor = element_blank()
    )
)

label_euro <- label_currency(prefix = "€",big.mark = ".",decimal.mark = ",",
                             scale_cut = NULL
)


DPI <- 300
dir.create("figures", showWarnings = FALSE)

# ---------------------------
# Load data
# ---------------------------

service_records <- read_csv("service_records.csv", show_col_types = FALSE)
service_records <- clean_names(service_records)

line_items <- read_csv("line_items.csv", show_col_types = FALSE)
line_items <- clean_names(line_items)

# ---------------------------
# Clean + parse + main metric
# ---------------------------

service_records <- mutate(
  service_records,
  visit_date = str_trim(visit_date),
  visit_date = na_if(visit_date, ""),
  date  = mdy(visit_date, quiet = TRUE),
  month = floor_date(date, "month"),
  cost  = total_payment_due
)

# --------------------------------
# Quick data checks and summaries
# --------------------------------

missing_rate <- summarise(
  service_records,
  across(everything(), function(x) mean(is.na(x)))
)
missing_rate <- pivot_longer(missing_rate, everything(), names_to = "col", values_to = "na_rate")
missing_rate <- arrange(missing_rate, desc(na_rate))
print(missing_rate)

summary_cost <- summarise(
  service_records,
  n = n(),
  n_na_cost   = sum(is.na(cost)),
  n_zero      = sum(cost == 0, na.rm = TRUE),
  n_negative  = sum(cost < 0,  na.rm = TRUE),
  min_cost    = min(cost, na.rm = TRUE),
  median_cost = median(cost, na.rm = TRUE),
  mean_cost   = mean(cost, na.rm = TRUE),
  max_cost    = max(cost, na.rm = TRUE)
)
print(summary_cost)

tmp_top <- filter(service_records, !is.na(cost))
tmp_top <- arrange(tmp_top, desc(cost))
top3 <- slice_head(tmp_top, n = 3)
top3 <- select(top3, service_id, invoice_number, date, vehicle_make, vehicle_model, cost)
print(top3)

# ---------------------------
# Plots
# ---------------------------

# 1) Total payment due per service visit
tmp_cost <- filter(service_records, !is.na(cost), cost >= 0)

p1 <- ggplot(tmp_cost, aes(cost)) +
  geom_histogram(bins = 30, fill = BMW_BLUE) +
  scale_x_continuous(labels = label_euro) +
  labs(
    title = "Invoice cost distribution",
    subtitle = "",
    x = "Cost",
    y = "Count"
  )

ggsave("figures/01_cost_hist.png", p1, width = 8, height = 5, dpi = DPI)

# 2) Monthly total cost
tmp_month <- filter(service_records, !is.na(month))
monthly <- summarise(
  group_by(tmp_month, month),
  total_cost = sum(cost, na.rm = TRUE),
  n_invoices = n(),
  .groups = "drop"
)

p2 <- ggplot(monthly, aes(month, total_cost)) +
  geom_line(color = BMW_BLUE_DARK, linewidth = 1) +
  geom_point(color = BMW_BLUE, size = 2) +
  scale_x_date(date_breaks = "1 month", date_labels = "%Y-%m") +
  scale_y_continuous(labels = label_euro) +
  labs(
    title = "Total cost per month",
    subtitle = "",
    x = "Month",
    y = "Total cost"
  )

ggsave("figures/02_cost_over_time.png", p2, width = 9, height = 5, dpi = DPI)


# 3) Cost drivers : What contributes most to total cost
drivers <- summarise(
  service_records,
  labor       = sum(labor_total, na.rm = TRUE),
  parts       = sum(parts_total, na.rm = TRUE),
  gas_oil     = sum(gas_oil_lube_total, na.rm = TRUE),
  sublet      = sum(sublet_total, na.rm = TRUE),
  misc        = sum(misc_charges, na.rm = TRUE),
  sales_tax   = sum(sales_tax, na.rm = TRUE),
  adjustments = sum(adjustments, na.rm = TRUE)
)

# driver = name of the cost component, total_cost = its value
drivers_long <- pivot_longer(
  drivers,
  cols = everything(),
  names_to = "driver",
  values_to = "total_cost"
)

drivers_long <- arrange(drivers_long, desc(total_cost))
drivers_long <- mutate(
  drivers_long,
  driver = fct_reorder(driver, total_cost)
)

#total cost per cost component
p3 <- ggplot(drivers_long, aes(x = total_cost, y = driver)) +
  geom_point(size = 3, color = BMW_BLUE) +
  scale_x_continuous(labels = label_euro) +
  labs(
    title = "Cost drivers (sum of components)",
    x = "Total cost",
    y = NULL
  )

ggsave("figures/03_cost_drivers.png", p3, width = 8, height = 5, dpi = DPI)

# 4) Service types from line_items: Aggregate line-item costs by service_type, then plot the top 15

#Summarise total cost per service type
service_type_cost <- summarise(
  group_by(line_items, service_type),
  total_line_cost = sum(line_total, na.rm = TRUE),
  n_lines = n(),
  .groups = "drop"  
)

#Sort service types by total cost 
service_type_cost <- arrange(service_type_cost, desc(total_line_cost))
top15 <- slice_head(service_type_cost, n = 15)
#sort by total_line_cost
top15 <- mutate(top15, service_type = fct_reorder(service_type, total_line_cost))

p4 <- ggplot(top15, aes(x = service_type, y = total_line_cost)) +
  geom_col(fill = BMW_BLUE) +
  coord_flip() +
  scale_y_continuous(labels = label_euro) +
  labs(
    title = "Top service types by line-item cost",
    subtitle = "",
    x = "Service type",
    y = "Total line-item cost"
  )

ggsave("figures/04_service_type_cost.png", p4, width = 9, height = 6, dpi = DPI)