#usual suspects
require(data.table)
require(reshape2)
require(ggplot2)
require(tidyverse)
require(RColorBrewer)
library(plm)
library(lattice)
library(plotly)
library(stargazer)
library(Amelia)
library(ineq)
library(xtable)
library(stringr)
library(gglorenz)
library(gridExtra)
library(ggpubr)
library(ggrepel)
library(grid)
library(igraph)
#library(tidygeocoder)  # [S2-ENV] package not installed and never called
#library(pacman)  # [S2-ENV] package not installed and never called
#library(rnaturalearth)
#library(rnaturalearthdata)
library(tm)
library(wordcloud)
library(readxl)
library(writexl)
library(scales)
library(janitor)
library(ineq)
library(patchwork)
#library(ggstream)  # [S2-ENV] package not installed and never called
#library(circlize)  # [S2-ENV] package not installed and never called
library(ggridges)
require(foreign)
require(RColorBrewer)
require(readxl)
require(dummies)
library(purrr)
library(fmsb)

rm(list = ls())

#setwd("C:\\Users\\johanf\\Dropbox\\3 Cape Panel\\Research\\2024F_Inequality")  # [S2-ENV]
setwd(Sys.getenv("P29_RUNDIR"))  # [S2-ENV] run directory on D:
.S2DIR <- Sys.getenv("P29_HOOKDIR"); .S2 <- function(name, obj) saveRDS(obj, file.path(.S2DIR, paste0(name, ".rds")))  # [S2-HOOK extraction only]


#Revise and resubmit: April 2025


################################Cleaning the data################################

# Define the file path and sheet name
file_path <- "stellenbosch_clean_april2025.xlsx"
sheet_name <- "stellenbosch_long_linked_apr202"

# Determine the number of columns
temp_df <- read_excel(file_path, sheet = sheet_name, n_max = 1)
num_columns <- ncol(temp_df)

# Create a vector of "text" types for each column
col_types <- rep("text", num_columns)

# Read the Excel file and specify all columns as text
opgaaf <- read_excel(file_path, sheet = sheet_name, col_types = col_types)
.S2("n_raw", nrow(opgaaf))  # [S2-HOOK extraction only]

opgaaf_new <- data.table(opgaaf)


columns_to_convert <- c(
  "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
  "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", "horse_breeding",
  "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether",
  "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed",
  "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", "potatoes_vol",
  "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", "barleyzk_vol",
  "bzkoorn", "bzkoorn1", "vines", "wine", "brandy"
)

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to the specified columns
opgaaf2 <- clean_and_convert_columns_to_numeric(opgaaf_new, columns_to_convert)


# Function to replace NAs with zeros based on year only
replace_na_with_zero <- function(dt, columns, year_col = "year") {
  for (col in columns) {
    # Identify years where there are non-NA entries for the specific column
    non_na_years <- dt[!is.na(get(col)), unique(get(year_col))]
    
    # Loop through each year where there are non-NA entries
    for (year_val in non_na_years) {
      # Replace NAs with zeros for the specific year
      dt[get(year_col) == year_val & is.na(get(col)), (col) := 0]
    }
  }
  return(dt)
}

columns_to_convert2 <- c(
  "settler_men", "settler_women", "settler_sons", "settler_daughters", "settler_children",
  "servants", "servant_coachman", "servant_personal", "servant_home", "servant_cook",
  "slave_men", "slave_women", "slave_sons", "slave_daughters", "slave_children",
  "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters", "freeblack_men", "freeblack_women",
  "freeblack_sons", "freeblack_daughters", "prizenegro_men", "prizenegro_women", "prizenegro_sons",
  "prizenegro_daughters", "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
  "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", "horse_breeding",
  "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether",
  "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed",
  "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", "potatoes_vol",
  "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", "barleyzk_vol",
  "bzkoorn", "bzkoorn1", "vines", "wine", "brandy", "swords", "side_arm", "pistols", "rifle",
  "wagons", "carts", "wagons_pleasure", "carts_pleasure"
)


# Apply the NA replacement function to the specified columns
opgaaf2 <- replace_na_with_zero(opgaaf2, columns_to_convert2)


# Now clean opgaaf
opgaaf <- data.table(opgaaf2)


## Livestock

# Function to replace NAs in the specified column with the sum of related columns
replace_na_with_sum <- function(dt, main_col, related_columns) {
  # Calculate the sum of the related columns
  dt[, temp_sum := rowSums(.SD, na.rm = TRUE), .SDcols = related_columns]
  
  # Replace NAs in the main column with the calculated sum
  dt[is.na(get(main_col)), (main_col) := temp_sum]
  
  # Drop the temporary column
  dt[, temp_sum := NULL]
  
  return(dt)
}

# Define the related columns for horses, cattle, and sheep
horse_columns <- c("horse_foals", "horse_work", "horse_breeding", "horse_pleasure")
cattle_columns <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves")
sheep_columns <- c("sheep_breeding", "sheep_wool", "sheep_wether", "sheep_goats")

# Apply the function to the data table for horses
opgaaf <- replace_na_with_sum(opgaaf, "horses", horse_columns)

# Apply the function to the data table for cattle
opgaaf[, cattle := rowSums(.SD, na.rm = TRUE), .SDcols = cattle_columns]

# Apply the function to the data table for sheep
opgaaf <- replace_na_with_sum(opgaaf, "sheep", sheep_columns)

#write_xlsx(opgaaf, "opgaaf .xlsx")
#opgaaf <- read_excel("opgaaf.xlsx")

# Convert your data.table to a CSV file
#fwrite(opgaaf_new, "opgaaf.csv")

# Read the CSV file back into R
#opgaaf <- fread("opgaaf.csv")

### People

# Convert opgaaf to a data.table if it isn't already
opgaaf <- as.data.table(opgaaf)

# Define the columns for slaves
slave_columns <- c("slave_men", "slave_women", "slave_sons", "slave_daughters")

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to opgaaf for slave columns
opgaaf <- clean_and_convert_columns_to_numeric(opgaaf, slave_columns)

# Create the new variable 'slaves' by summing up the specified columns using dplyr
opgaaf <- opgaaf %>%
  mutate(slaves = rowSums(select(., all_of(slave_columns)), na.rm = TRUE))


# Define the columns for slaves
khoe_columns <- c("khoe_men", "khoe_women", "khoe_sons", "khoe_daughters")


# Apply the cleaning function to opgaaf for slave columns
opgaaf <- clean_and_convert_columns_to_numeric(opgaaf, khoe_columns)

# Create the new variable 'slaves' by summing up the specified columns using dplyr
opgaaf <- opgaaf %>%
  mutate(khoe = rowSums(select(., all_of(khoe_columns)), na.rm = TRUE))



### Settlers

# Convert opgaaf to a data.table if it isn't already
opgaaf <- as.data.table(opgaaf)

# Define the columns for settlers
settler_columns <- c("settler_men", "settler_women", "settler_sons", "settler_daughters")

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to opgaaf for settler columns
opgaaf <- clean_and_convert_columns_to_numeric(opgaaf, settler_columns)

# Create the new variable 'settlers' by summing up the specified columns using dplyr within data.table
opgaaf <- opgaaf %>%
  mutate(settlers = rowSums(select(., all_of(settler_columns)), na.rm = TRUE))

# Convert your data.table to an Excel file
write_xlsx(opgaaf, "opgaaf.xlsx")
#opgaaf <- read_excel("opgaaf.xlsx")


################################Begin the analysis################################

###Price data###

prices <- read_excel("price_series.xlsx")


###Opgaafrolle###

# Convert opgaaf to a data.table if it isn't already
opgaaf_save <- as.data.table(opgaaf)
#opgaaf <- as.data.table(opgaaf_save)
opgaaf <- as.data.table(opgaaf)

rm(opgaaf_new, opgaaf2)

# Ensure the year column is numeric
opgaaf[, year := as.numeric(year)]

# Check for any NAs introduced by coercion and handle them if necessary
opgaaf <- opgaaf[!is.na(year)]
.S2("n_year", nrow(opgaaf))  # [S2-HOOK extraction only]

# Create the decade variable using the data.table syntax
opgaaf[, decade := (year %/% 10) * 10]

# Define the columns to keep
columns_to_keep <- c("year", "decade", "names_men", "settler_men", "settlers", "slave_men", "slaves", "khoe", "slave_women", "slave_sons", "slave_daughters",
                     "horses", "cattle", "sheep", "wheat_vol", "vines", "wine")


# Subset the data.table to keep only the specified columns
opgaaf <- opgaaf[, ..columns_to_keep]



########Identify outliers################

# Function to extract the top 0.01% observations for each variable separately
extract_top_0.01_percent <- function(data, vars) {
  top_observations <- list()
  
  for (var in vars) {
    # Filter the top 0.01% for each variable individually
    top_threshold <- quantile(data[[var]], probs = 0.9999, na.rm = TRUE)
    top_observations[[var]] <- data %>% filter(.data[[var]] >= top_threshold)
  }
  
  # Combine all results into a single dataframe
  bind_rows(top_observations, .id = "variable")
}

# Add row numbers
opgaaf <- opgaaf %>%
  mutate(original_row = row_number())

# Define the columns of interest
columns_to_keep <- c("slaves", "khoe", "horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Run your function
top_0.01_percent_dataset <- extract_top_0.01_percent(opgaaf, columns_to_keep)
.S2("top001", top_0.01_percent_dataset)  # [S2-HOOK extraction only]

###Removing outliers after manual inspection###

# Create new dataset with specified rows removed
opgaaf <- opgaaf[-c(9802, 21124, 15515, 41686, 137633, 50115, 87634, 115473,
                        7082, 17822, 18358, 35500, 35534, 36546, 36548, 41765,
                        90267, 107007, 128102), ]
.S2("n_after_outliers", nrow(opgaaf))  # [S2-HOOK extraction only]



# Convert opgaaf to a data.table if it isn't already
opgaaf_save2 <- as.data.table(opgaaf)


####This is where you have to return to work with slaves

#opgaaf <- as.data.table(opgaaf_save2)
opgaaf <- as.data.table(opgaaf)

# Ensure that all relevant columns are numeric
opgaaf[, horses := as.numeric(horses)]
opgaaf[, cattle := as.numeric(cattle)]
opgaaf[, sheep := as.numeric(sheep)]
opgaaf[, wheat_vol := as.numeric(wheat_vol)]
opgaaf[, vines := as.numeric(vines)]
opgaaf[, wine := as.numeric(wine)]

# Modify the descriptive statistics calculation to handle missing values and ensure consistent types
descriptive_stats <- opgaaf[, .(
  horses_mean = mean(as.numeric(horses), na.rm = TRUE),
  horses_sd = sd(as.numeric(horses), na.rm = TRUE),
  horses_max = ifelse(all(is.na(horses)), as.numeric(NA), max(horses, na.rm = TRUE)),
  horses_count = sum(!is.na(horses)),
  
  cattle_mean = mean(as.numeric(cattle), na.rm = TRUE),
  cattle_sd = sd(as.numeric(cattle), na.rm = TRUE),
  cattle_max = ifelse(all(is.na(cattle)), as.numeric(NA), max(cattle, na.rm = TRUE)),
  cattle_count = sum(!is.na(cattle)),
  
  sheep_mean = mean(as.numeric(sheep), na.rm = TRUE),
  sheep_sd = sd(as.numeric(sheep), na.rm = TRUE),
  sheep_max = ifelse(all(is.na(sheep)), as.numeric(NA), max(sheep, na.rm = TRUE)),
  sheep_count = sum(!is.na(sheep)),
  
  wheat_vol_mean = mean(as.numeric(wheat_vol), na.rm = TRUE),
  wheat_vol_sd = sd(as.numeric(wheat_vol), na.rm = TRUE),
  wheat_vol_max = ifelse(all(is.na(wheat_vol)), as.numeric(NA), max(wheat_vol, na.rm = TRUE)),
  wheat_vol_count = sum(!is.na(wheat_vol)),
  
  vines_mean = mean(as.numeric(vines), na.rm = TRUE),
  vines_sd = sd(as.numeric(vines), na.rm = TRUE),
  vines_max = ifelse(all(is.na(vines)), as.numeric(NA), max(vines, na.rm = TRUE)),
  vines_count = sum(!is.na(vines)),
  
  wine_mean = mean(as.numeric(wine), na.rm = TRUE),
  wine_sd = sd(as.numeric(wine), na.rm = TRUE),
  wine_max = ifelse(all(is.na(wine)), as.numeric(NA), max(wine, na.rm = TRUE)),
  wine_count = sum(!is.na(wine))
), by = decade]

# View the result
print(descriptive_stats)

# Calculate the number of observations for each variable by decade and the total
observations_by_decade <- opgaaf[, .(
  horses_obs = sum(!is.na(horses)),
  cattle_obs = sum(!is.na(cattle)),
  sheep_obs = sum(!is.na(sheep)),
  wheat_vol_obs = sum(!is.na(wheat_vol)),
  vines_obs = sum(!is.na(vines)),
  wine_obs = sum(!is.na(wine))
), by = decade]


# Display the results
observations_by_decade




# Define the variables to be used
variables_to_plot <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Replace NAs with 0 for the specified variables
opgaaf[, (variables_to_plot) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = variables_to_plot]

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot)))) != length(variables_to_plot))

# Calculate the Gini coefficient for each variable by year
gini_values <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), ~ Gini(.x, na.rm = TRUE)))

# Calculate the number of observations per year
obs_per_year <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(count = n())
.S2("fig1_assets_annual", list(gini_values = gini_values, obs_per_year = obs_per_year))  # [S2-HOOK extraction only]

# Transform Gini data to long format for ggplot
gini_long <- gini_values %>%
  pivot_longer(cols = -year, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels <- c("horses" = "Horses", "cattle" = "Cattle", "sheep" = "Sheep", 
            "wheat_vol" = "Wheat", "vines" = "Vines", "wine" = "Wine")

# Create a custom scale for line types and colors
line_types <- c("horses" = "dotted", "cattle" = "dotdash", "sheep" = "longdash", 
                "wheat_vol" = "twodash", "vines" = "dotted", "wine" = "solid")

line_colors <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                 "wheat_vol" = "grey70", "vines" = "grey30", "wine" = "black")

# Plot the Gini coefficients over time
opgaafgini_rev = ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long$year, na.rm = TRUE), max(gini_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_color_manual(values = line_colors, name = NULL, labels = labels) +
  labs(x = "Year",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border

opgaafgini_rev
ggsave("opgaafgini_rev.jpg", width = 9, height = 6, dpi = 300)


#################OUR LONG WALK GRAPH##################

# Libraries ---------------------------------------------------------------
library(tidyverse)
library(scales)
library(grid)   # for unit()

# Custom colours ----------------------------------------------------------
custom_colours <- c(
  "#693e23", "#8f8844", "#db6a11",
  "#ba1a20", "#4492a0", "#eccba7", "#c29500"
)

# Nice legend labels ------------------------------------------------------
label_map <- c(
  cattle    = "Cattle",
  sheep     = "Sheep",
  wheat_vol = "Wheat",
  vines     = "Vines",
  wine      = "Wine",
  horses    = "Horses"
)

gini_long_clean <- gini_long %>%
  mutate(
    variable = factor(label_map[variable], levels = label_map)
  )

# Map colours in same order as labels ------------------------------------
colour_map <- setNames(custom_colours[seq_along(label_map)], label_map)

# SIMPLE line graph ------------------------------------------------------
opgaafgini_simple <- ggplot(
  gini_long_clean,
  aes(x = year, y = gini, colour = variable)
) +
  # use `size` so legend inherits it automatically
  geom_line(size = 1.6, lineend = "round") +
  
  scale_colour_manual(values = colour_map, name = NULL) +
  
  scale_x_continuous(
    breaks = seq(min(gini_long_clean$year),
                 max(gini_long_clean$year),
                 by = 10)
  ) +
  scale_y_continuous(
    expand = c(0, 0),
    limits = c(0, NA)
  ) +
  
  labs(
    x = NULL,
    y = "Gini coefficient",
    caption = "Source: Fourie (2025) • Visualised: ourlongwalk.com"
  ) +
  
  guides(
    colour = guide_legend(
      nrow  = 2,
      byrow = TRUE
    )
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    legend.position   = "bottom",
    legend.box        = "horizontal",
    legend.text       = element_text(colour = "grey20"),
    legend.key.width  = unit(1.5, "cm"),
    legend.key.height = unit(0.4, "cm"),
    legend.key        = element_rect(fill = "#f7f5f2", colour = NA),
    axis.text         = element_text(colour = "grey20"),
    panel.grid.minor  = element_blank(),
    plot.caption      = element_text(colour = "grey40", size = 10),
    plot.background   = element_rect(fill = "#f7f5f2", colour = NA),
    panel.background  = element_rect(fill = "#f7f5f2", colour = NA)
  )

opgaafgini_simple
  
#setwd("C:\\Users\\johanf\\Dropbox\\15 Our Long Walk\\Graphs")  # [S2-ENV] Our Long Walk folder; graph saved in run directory instead

ggsave(
  "opgaaf_gini_lines.jpg",
  opgaafgini_simple,
  width = 10,
  height = 6,
  dpi = 300,
  bg = "#f7f5f2"
)















# Calculate the total number of non-NA observations for each variable
total_observations <- opgaaf %>%
  summarise(
    horses_obs = sum(!is.na(horses)),
    cattle_obs = sum(!is.na(cattle)),
    sheep_obs = sum(!is.na(sheep)),
    wheat_vol_obs = sum(!is.na(wheat_vol)),
    vines_obs = sum(!is.na(vines)),
    wine_obs = sum(!is.na(wine))
  )

# View the results
print(total_observations)


### Inequality with a bundle

# Create a 'period' column in opgaaf3 to match the decades in the prices data
opgaaf <- opgaaf %>%
  mutate(period = case_when(
    year >= 1680 & year < 1690 ~ 1680,
    year >= 1690 & year < 1700 ~ 1690,
    year >= 1700 & year < 1710 ~ 1700,
    year >= 1710 & year < 1720 ~ 1710,
    year >= 1720 & year < 1730 ~ 1720,
    year >= 1730 & year < 1740 ~ 1730,
    year >= 1740 & year < 1750 ~ 1740,
    year >= 1750 & year < 1760 ~ 1750,
    year >= 1760 & year < 1770 ~ 1760,
    year >= 1770 & year < 1780 ~ 1770,
    year >= 1780 & year < 1790 ~ 1780,
    year >= 1790 & year < 1800 ~ 1790,
    year >= 1800 & year < 1810 ~ 1800,
    year >= 1810 & year < 1820 ~ 1810,
    year >= 1820 & year < 1830 ~ 1820,
    year >= 1830 & year < 1840 ~ 1830
  ))

# Now perform the left join on the 'period' column
opgaaf_filtered <- opgaaf %>%
  left_join(prices, by = "period")

# Calculate the bundle value for each good (multiply quantity by price)
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(cattle_value = cattle * cattle_breeding,
         sheep_value = sheep.x * sheep.y,
         horses_value = horses.x * horses.y,
         wheat_value = wheat_vol.x * wheat_vol.y,
         wine_value = wine.x * wine.y)

# Define the new variables to be used (the total value of the goods)
variables_to_plot_bundle <- c("cattle_value", "sheep_value", "horses_value", "wheat_value", "wine_value")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_filtered %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot_bundle)))) != length(variables_to_plot_bundle))

# Calculate the Gini coefficient for each variable by period (decade)
gini_values_bundle <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(across(all_of(variables_to_plot_bundle), ~ Gini(.x, na.rm = TRUE)))

# Transform Gini data to long format for ggplot
gini_long_bundle <- gini_values_bundle %>%
  pivot_longer(cols = -period, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels_bundle <- c("cattle_value" = "Cattle Value", "sheep_value" = "Sheep Value", 
                   "horses_value" = "Horses Value", "wheat_value" = "Wheat Value", 
                   "wine_value" = "Wine Value")

# Create a custom scale for line types and colors
line_types_bundle <- c("cattle_value" = "dotted", "sheep_value" = "dotdash", 
                       "horses_value" = "longdash", "wheat_value" = "twodash", 
                       "wine_value" = "solid")

line_colors_bundle <- c("cattle_value" = "grey60", "sheep_value" = "black", 
                        "horses_value" = "grey50", "wheat_value" = "grey70", 
                        "wine_value" = "black")

# Plot the Gini coefficients over time for the bundle values
opgaafgini_bundle_rev = ggplot(gini_long_bundle, aes(x = period, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long_bundle$period, na.rm = TRUE), max(gini_long_bundle$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_linetype_manual(values = line_types_bundle, name = NULL, labels = labels_bundle) +
  scale_color_manual(values = line_colors_bundle, name = NULL, labels = labels_bundle) +
  labs(x = "Period",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border

opgaafgini_bundle_rev
ggsave("opgaafgini_bundle_rev.jpg", width = 9, height = 6, dpi = 300)


#Basket

# Calculate the total value of all goods combined for each period
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

# Summarize total value by period
total_values_by_period <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(total_value = sum(total_value, na.rm = TRUE))

# Plot the total production value over time
opgaaf_total_value_rev = ggplot(total_values_by_period, aes(x = period, y = total_value)) +
  geom_line(size = 0.8, color = "black") +
  scale_x_continuous(breaks = seq(min(total_values_by_period$period, na.rm = TRUE), max(total_values_by_period$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  labs(x = "Period",
       y = "Total Production Value") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank())  # Remove the black border

opgaaf_total_value_rev
ggsave("opgaaf_total_value_rev.jpg", width = 9, height = 6, dpi = 300)


##Gini

# Calculate the total production value for each household (row) by summing the values of the five goods
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

# Calculate the Gini coefficient of the total production value for each period (decade)
gini_total_production <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(gini_total_value = Gini(total_value, na.rm = TRUE))

# Plot the Gini coefficient of the total production value over time
opgaafgini_total_rev = ggplot(gini_total_production, aes(x = period, y = gini_total_value)) +
  geom_line(size = 0.8, color = "black") +
  scale_x_continuous(breaks = seq(min(gini_total_production$period, na.rm = TRUE), max(gini_total_production$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  labs(x = "Period",
       y = "Gini coefficient (total value)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank())  # Remove the black border

opgaafgini_total_rev
ggsave("opgaafgini_total_value_rev.jpg", width = 9, height = 6, dpi = 300)
.S2("pre_slaves", list(gini_long = gini_long, gini_total_production = gini_total_production, tv = opgaaf_filtered[, c("period", "year", "total_value")]))  # [S2-HOOK extraction only]



### Inequality of slave ownership

# Define the variables to be used
variables_to_plot <- c("slave_men", "slave_women", "slave_sons", "slave_daughters")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot)))) != length(variables_to_plot))

# Calculate the Gini coefficient for each variable by year
gini_values <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), ~ Gini(.x, na.rm = TRUE)))
.S2("slave_gini_annual", gini_values)  # [S2-HOOK extraction only]

# Calculate the number of observations per year
obs_per_year <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(count = n())

# Transform Gini data to long format for ggplot
gini_long <- gini_values %>%
  pivot_longer(cols = -year, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels <- c("slave_men" = "Slave men", "slave_women" = "Slave women", "slave_sons" = "Slave sons", 
            "slave_daughters" = "Slave daughters")

# Create a custom scale for line types and colors
line_types <- c("slave_men" = "dotted", "slave_women" = "dotdash", "slave_sons" = "longdash", 
                "slave_daughters" = "solid")

line_colors <- c("slave_men" = "grey60", "slave_women" = "black", "slave_sons" = "grey50", 
                 "slave_daughters" = "grey30")

# Plot the Gini coefficients over time
opgaafginislave_rev = ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long$year, na.rm = TRUE), max(gini_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_color_manual(values = line_colors, name = NULL, labels = labels) +
  labs(x = "Year",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border


# Display the plot
opgaafginislave_rev

# Save the plot as a jpg file
ggsave("opgaafginislave_rev.jpg", plot = opgaafginislave_rev, width = 9, height = 6, dpi = 300)


### Add slaves as separate households

# Ensure opgaaf3 is a data.table
opgaaf <- as.data.table(opgaaf)

# Define the columns to set to zero for new observations, including year and decade
columns_to_keep <- c("year", "decade", "settler_men", "settlers", "slave_men", "slaves", 
                     "horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Replace NAs with zeros for the specified columns
opgaaf <- opgaaf %>%
  mutate(across(all_of(columns_to_keep), ~ ifelse(is.na(.), 0, .)))

# Calculate total slaves per year
total_slaves_per_year <- opgaaf %>%
  filter(slave_men > 0) %>%
  group_by(year, decade) %>%
  summarise(total_slaves = sum(slave_men, na.rm = TRUE))

# Create additional rows with zero assets for each year
additional_rows <- total_slaves_per_year %>%
  pmap_dfr(function(year, decade, total_slaves) {
    data.frame(year = rep(year, total_slaves),
               decade = rep(decade, total_slaves),
               settler_men = 0,
               settlers = 0,
               slave_men = 0,
               slaves = 0,
               horses = 0,
               cattle = 0,
               sheep = 0,
               wheat_vol = 0,
               vines = 0,
               wine = 0,
               stringsAsFactors = FALSE)
  })

# Combine the original data with the new rows
opgaaf_with_zeros <- bind_rows(opgaaf, additional_rows)


# Ensure opgaaf_with_zeros is a data.table
opgaaf_with_zeros <- as.data.table(opgaaf_with_zeros)

# Define the variables to be used
variables_to_plot <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Filter the data until the year 1828 and remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_with_zeros %>%
  filter(year <= 1828) %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot)))) != length(variables_to_plot))

# Calculate the Gini coefficient for each variable by year
gini_values <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), ~ Gini(.x, na.rm = TRUE)))

# Calculate the number of observations per year
obs_per_year <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(count = n())

# Transform Gini data to long format for ggplot
gini_long <- gini_values %>%
  pivot_longer(cols = -year, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels <- c("horses" = "Horses", "cattle" = "Cattle", "sheep" = "Sheep", 
            "wheat_vol" = "Wheat", "vines" = "Vines", "wine" = "Wine")

# Create a custom scale for line types and colors
line_types <- c("horses" = "dotted", "cattle" = "dotdash", "sheep" = "longdash", 
                "wheat_vol" = "twodash", "vines" = "dotted", "wine" = "solid")

line_colors <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                 "wheat_vol" = "grey70", "vines" = "grey30", "wine" = "black")

# Plot the Gini coefficients over time
opgaafgini_withslaves_rev <- ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long$year, na.rm = TRUE), max(gini_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_color_manual(values = line_colors, name = NULL, labels = labels) +
  labs(x = "Year",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border

# Display the plot
print(opgaafgini_withslaves_rev)

# Save the plot as a jpg file
ggsave("opgaafgini_withslaves_rev.jpg", plot = opgaafgini_withslaves_rev, width = 9, height = 6, dpi = 300)
.S2("withslaves_annual", gini_values)  # [S2-HOOK extraction only]

### Slaves as extra settler households - bundles

# Calculate total slaves per year
total_slaves_per_year <- opgaaf %>%
  filter(slave_men > 0) %>%
  group_by(year, decade) %>%
  summarise(total_slaves = sum(slave_men, na.rm = TRUE))

# Create additional rows with zero assets for each year
additional_rows <- total_slaves_per_year %>%
  pmap_dfr(function(year, decade, total_slaves) {
    data.frame(year = rep(year, total_slaves),
               decade = rep(decade, total_slaves),
               settler_men = 1,
               settlers = 0,
               slave_men = 0,
               slaves = 0,
               horses = 0,
               cattle = 0,
               sheep = 12,
               wheat_vol = 0,
               vines = 0,
               wine = 0,
               stringsAsFactors = FALSE)
  })

# Combine the original data with the new rows
opgaaf_with_zeros <- bind_rows(opgaaf, additional_rows)


# Ensure opgaaf3_with_zeros is a data.table
opgaaf_with_zeros <- as.data.table(opgaaf_with_zeros)


# Create a 'period' column in opgaaf3 to match the decades in the prices data
opgaaf_with_zeros <- opgaaf_with_zeros %>%
  mutate(period = case_when(
    year >= 1700 & year < 1710 ~ 1700,
    year >= 1710 & year < 1720 ~ 1710,
    year >= 1720 & year < 1730 ~ 1720,
    year >= 1730 & year < 1740 ~ 1730,
    year >= 1740 & year < 1750 ~ 1740,
    year >= 1750 & year < 1760 ~ 1750,
    year >= 1760 & year < 1770 ~ 1760,
    year >= 1770 & year < 1780 ~ 1770,
    year >= 1780 & year < 1790 ~ 1780,
    year >= 1790 & year < 1800 ~ 1790,
    year >= 1800 & year < 1810 ~ 1800,
    year >= 1810 & year < 1820 ~ 1810,
    year >= 1820 & year < 1830 ~ 1820,
    year >= 1830 & year < 1840 ~ 1830
  ))

# Filter data to only include records from 1700 onwards
opgaaf_filtered <- opgaaf_with_zeros %>%
  filter(year >= 1700)

# Now perform the left join on the 'period' column
opgaaf_filtered <- opgaaf_with_zeros %>%
  left_join(prices, by = "period")

# Calculate the bundle value for each good (multiply quantity by price)
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(cattle_value = cattle * cattle_breeding,
         sheep_value = sheep.x * sheep.y,
         horses_value = horses.x * horses.y,
         wheat_value = wheat_vol.x * wheat_vol.y,
         wine_value = wine.x * wine.y)

# Define the new variables to be used (the total value of the goods)
variables_to_plot_bundle <- c("cattle_value", "sheep_value", "horses_value", "wheat_value", "wine_value")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_filtered %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot_bundle)))) != length(variables_to_plot_bundle))

# Calculate the total value of all goods combined for each period
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

# Calculate the total production value for each household (row) by summing the values of the five goods
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

### Calculate Gini for Settlers Only

# Filter for settlers (exclude slaves)
settler_only <- opgaaf_filtered %>%
  filter(settler_men > 0) %>%
  mutate(total_value_settlers = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Calculate Gini for settlers only
gini_settlers <- settler_only %>%
  group_by(period) %>%
  summarize(gini_settler_value = Gini(total_value_settlers, na.rm = TRUE))

### Calculate Gini for Settlers and Slaves Combined (As Done Previously)

# Calculate Gini for settlers + slaves combined (already in your code)
gini_total_production <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(gini_total_value = Gini(total_value, na.rm = TRUE))

### Combine Both Gini Dataframes for Plotting

# Merge the two Gini data frames into one for comparison
gini_combined <- gini_settlers %>%
  left_join(gini_total_production, by = "period")
.S2("basket12", gini_combined)  # [S2-HOOK extraction only]

### Plot Both Gini Coefficients on the Same Graph

opgaafgini_combined_rev <- ggplot(gini_combined, aes(x = period)) +
  geom_line(aes(y = gini_settler_value, color = "Settlers and slaves"), size = 0.8) +
  geom_line(aes(y = gini_total_value, color = "Settlers"), size = 0.8) +
  scale_x_continuous(breaks = seq(1700, max(gini_combined$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  labs(x = "Period",
       y = "Gini coefficient") +
  scale_color_manual(values = c("Settlers" = "grey60", "Settlers and slaves" = "black")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank(),
        legend.position = "bottom",           # Move legend to the bottom
        legend.title = element_blank(),
        legend.box = "horizontal")            # Combine legend into one box

opgaafgini_combined_rev
ggsave("opgaafgini_settlersslaves_basket_rev.jpg", opgaafgini_combined_rev, width = 9, height = 6, dpi = 300)

###Averages for the text

# Step 1: Count observations per year
obs_per_year <- opgaaf %>%
  group_by(year) %>%
  summarise(num_obs = n()) %>%
  arrange(year)

# Step 2: Calculate averages
first_10_avg <- obs_per_year %>%
  slice_head(n = 10) %>%
  summarise(avg_first_10 = mean(num_obs))

last_10_avg <- obs_per_year %>%
  slice_tail(n = 10) %>%
  summarise(avg_last_10 = mean(num_obs))

overall_avg <- obs_per_year %>%
  summarise(avg_overall = mean(num_obs))

# Step 3: Combine results
summary_avgs <- bind_cols(first_10_avg, last_10_avg, overall_avg)

print(obs_per_year)
print(summary_avgs)
.S2("obs_avgs", list(obs_per_year = obs_per_year, summary_avgs = summary_avgs))  # [S2-HOOK extraction only]

###Figure 1

##Run until before slaves

# Prepare total Gini data
gini_total_clean <- gini_total_production %>%
  rename(year = period, gini_total = gini_total_value) %>%
  select(year, gini_total)

# Create total Gini line as a 'variable'
gini_total_long <- gini_total_clean %>%
  mutate(variable = "total_value",
         gini = gini_total) %>%
  select(year, variable, gini)

# Combine with individual Gini variables
gini_all_long <- bind_rows(gini_long, gini_total_long)
.S2("fig1_linear", gini_all_long)  # [S2-HOOK extraction only]

# Define all levels
all_vars <- unique(gini_all_long$variable)

# Define styling for each variable
labels_ext <- c("horses" = "Horses", "cattle" = "Cattle", "sheep" = "Sheep", 
                "wheat_vol" = "Wheat", "vines" = "Vines", "wine" = "Wine",
                "total_value" = "Total value")

line_types_ext <- c("horses" = "dotted", "cattle" = "dotdash", "sheep" = "longdash", 
                    "wheat_vol" = "twodash", "vines" = "dotted", "wine" = "solid",
                    "total_value" = "solid")

line_colors_ext <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                     "wheat_vol" = "grey70", "vines" = "grey30", "wine" = "black",
                     "total_value" = "black")

line_sizes_ext <- c("horses" = 0.8, "cattle" = 0.8, "sheep" = 0.8, 
                    "wheat_vol" = 0.8, "vines" = 0.8, "wine" = 0.8,
                    "total_value" = 1.4)

# Plot
opgaafgini_combined <- ggplot(gini_all_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable, size = variable)) +
  scale_x_continuous(breaks = seq(min(gini_all_long$year, na.rm = TRUE),
                                  max(gini_all_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_linetype_manual(values = line_types_ext, name = NULL, labels = labels_ext) +
  scale_color_manual(values = line_colors_ext, name = NULL, labels = labels_ext) +
  scale_size_manual(values = line_sizes_ext, name = NULL, labels = labels_ext) +
  labs(x = "Year", y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1),
         color = guide_legend(nrow = 1),
         size = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())

# Show plot
opgaafgini_combined
ggsave("opgaafgini_combined_rev.jpg", opgaafgini_combined, width = 9, height = 6, dpi = 300)


compute_top_shares <- function(x) {
  x <- sort(x[!is.na(x)], decreasing = TRUE)
  n <- length(x)
  total <- sum(x)
  
  idx_1pct <- ceiling(n * 0.01)
  idx_0_1pct <- ceiling(n * 0.001)
  idx_0_01pct <- ceiling(n * 0.0001)
  
  share_1pct <- sum(x[1:idx_1pct]) / total
  share_0_1pct <- if (idx_0_1pct >= 1) sum(x[1:idx_0_1pct]) / total else NA
  share_0_01pct <- if (idx_0_01pct >= 1) sum(x[1:idx_0_01pct]) / total else NA
  
  tibble(
    top_1_share = share_1pct,
    top_0_1_share = share_0_1pct,
    top_0_01_share = share_0_01pct
  )
}

top_shares_by_period <- opgaaf_filtered %>%
  group_by(period) %>%
  reframe(compute_top_shares(total_value))

# View results
print(top_shares_by_period)

# New top share calculation by percentile cutoffs
compute_top_shares_ranked <- function(df, value_col = "total_value", group_col = "period") {
  
  df %>%
    group_by(.data[[group_col]]) %>%
    arrange(desc(.data[[value_col]]), .by_group = TRUE) %>%
    mutate(
      rank = row_number(),
      n = n(),
      percentile = rank / n,
      share = .data[[value_col]] / sum(.data[[value_col]])
    ) %>%
    summarise(
      top_1_share = sum(share[percentile <= 0.01]),
      top_0_1_share = sum(share[percentile <= 0.001]),
      top_0_01_share = sum(share[percentile <= 0.0001]),
      .groups = "drop"
    )
}

# Run on your data
top_shares_by_period2 <- compute_top_shares_ranked(opgaaf_filtered, value_col = "total_value", group_col = "period")

# View the output
print(top_shares_by_period2)
.S2("topshares_linear", list(a = top_shares_by_period, b = top_shares_by_period2))  # [S2-HOOK extraction only]

###Figure 2

library(dplyr)
library(tidyr)
library(ineq)
library(ggplot2)
library(data.table)
library(purrr)

# Load your base dataset
opgaaf <- as.data.table(opgaaf_save2)

# Ensure asset columns are numeric and replace NAs with zeros
opgaaf[, c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine",
           "slave_men", "slave_women", "slave_sons", "slave_daughters",
           "settler_men") := lapply(.SD, function(x) ifelse(is.na(x), 0, as.numeric(x))),
       .SDcols = c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine",
                   "slave_men", "slave_women", "slave_sons", "slave_daughters",
                   "settler_men")]

# Create period variable: two-decade intervals
opgaaf <- opgaaf %>%
  mutate(period = case_when(
    year >= 1680 & year < 1700 ~ 1680,
    year >= 1700 & year < 1720 ~ 1700,
    year >= 1720 & year < 1740 ~ 1720,
    year >= 1740 & year < 1760 ~ 1740,
    year >= 1760 & year < 1780 ~ 1760,
    year >= 1780 & year < 1800 ~ 1780,
    year >= 1800 & year < 1820 ~ 1800,
    year >= 1820 & year < 1840 ~ 1820
  ))

### 1. Settlers only (no slaves as assets or households)
settlers_only <- opgaaf %>%
  filter(settler_men > 0) %>%
  mutate(total_value = horses + cattle + sheep + wheat_vol + vines + wine) %>%
  group_by(period) %>%
  summarise(gini = ineq::Gini(total_value, na.rm = TRUE)) %>%
  mutate(scenario = "Settlers only (no slaves)")

### 2. Settlers with slave assets (but no slave households)
# Settlers with slaves treated as assets (e.g. each slave = 12 sheep)
# Here we assume a standard value conversion: 1 slave = 12 sheep
settlers_with_slave_assets <- opgaaf %>%
  filter(settler_men > 0) %>%
  mutate(slave_value = 200 * (slave_men + slave_women + slave_sons + slave_daughters),
         total_value = horses + cattle + sheep + wheat_vol + vines + wine + slave_value) %>%
  group_by(period) %>%
  summarise(gini = ineq::Gini(total_value, na.rm = TRUE)) %>%
  mutate(scenario = "Settlers + slave assets (slaves not as households)")

### 3. Settlers + slaves as households with zero assets
slave_households <- opgaaf %>%
  filter(slave_men > 0) %>%
  group_by(year, period) %>%
  summarise(n = sum(slave_men, na.rm = TRUE), .groups = "drop")

slave_zero_rows <- slave_households %>%
  pmap_dfr(function(year, period, n) {
    data.frame(
      year = rep(year, n),
      period = rep(period, n),
      horses = 0, cattle = 0, sheep = 0, wheat_vol = 0, vines = 0, wine = 0
    )
  })

combined_zero <- bind_rows(opgaaf, slave_zero_rows)

gini_slaves_zero <- combined_zero %>%
  mutate(total_value = horses + cattle + sheep + wheat_vol + vines + wine) %>%
  group_by(period) %>%
  summarise(gini = ineq::Gini(total_value, na.rm = TRUE)) %>%
  mutate(scenario = "Settlers + slaves (slaves as households with zero assets)")

### 4. Settlers + slaves as households earning 12 sheep per year
slave_sheep_rows <- slave_households %>%
  pmap_dfr(function(year, period, n) {
    data.frame(
      year = rep(year, n),
      period = rep(period, n),
      horses = 0, cattle = 0, sheep = 12, wheat_vol = 0, vines = 0, wine = 0
    )
  })

combined_sheep <- bind_rows(opgaaf, slave_sheep_rows)

gini_slaves_sheep <- combined_sheep %>%
  mutate(total_value = horses + cattle + sheep + wheat_vol + vines + wine) %>%
  group_by(period) %>%
  summarise(gini = ineq::Gini(total_value, na.rm = TRUE)) %>%
  mutate(scenario = "Settlers + slaves (slaves with 12 sheep/year)")

### Combine all four series
gini_combined_all <- bind_rows(
  settlers_only,
  settlers_with_slave_assets,
  gini_slaves_zero,
  gini_slaves_sheep
)
.S2("fig2", gini_combined_all)  # [S2-HOOK extraction only]

### Plot
line_colors <- c(
  "Settlers only (no slaves)" = "black",
  "Settlers + slave assets (slaves not as households)" = "grey30",
  "Settlers + slaves (slaves as households with zero assets)" = "grey50",
  "Settlers + slaves (slaves with 12 sheep/year)" = "grey70"
)

line_types <- c(
  "Settlers only (no slaves)" = "solid",
  "Settlers + slave assets (slaves not as households)" = "dashed",
  "Settlers + slaves (slaves as households with zero assets)" = "dotdash",
  "Settlers + slaves (slaves with 12 sheep/year)" = "twodash"
)

figure2 <- ggplot(gini_combined_all, aes(x = period, y = gini, color = scenario, linetype = scenario)) +
  geom_line(size = 0.9) +
  scale_x_continuous(breaks = seq(min(gini_combined_all$period, na.rm = TRUE),
                                  max(gini_combined_all$period, na.rm = TRUE), by = 20)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  scale_color_manual(values = line_colors, name = NULL) +
  scale_linetype_manual(values = line_types, name = NULL) +
  labs(x = "Period", y = "Gini coefficient") +
  guides(color = guide_legend(nrow = 2), linetype = guide_legend(nrow = 2)) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",
    legend.box = "horizontal",
    panel.border = element_blank()
  )

# Print to Viewer
print(figure2)

# Save the image
ggsave("figure2_gini_slavery_scenarios.jpg", plot = figure2, width = 9, height = 6, dpi = 300)








###1825

# Read different districts into R

## Cape Town

# Read the Excel file, assuming the sheet name is "Cape district 1825"
df <- read_excel("1825 series.xlsx", sheet = "Cape district 1825", col_names = FALSE)

# Extract column names from the first three rows and combine them
col_names <- df %>%
  slice(1:3) %>%
  t() %>%
  as.data.frame() %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Ensure column names are unique
col_names <- make.unique(col_names)

# Assign unique column names to the dataframe
colnames(df) <- col_names

# Remove the first three rows used for column names
df <- df %>% slice(-1:-3)

# Filter rows where the second column (Names) is not NA
df <- df %>% filter(!is.na(col_names[2]))


# Select and rename the specified columns
district_ct <- df %>%
  select(
    settler_men = `MALES ABOVE 16; FEMALES ABOVE 20_Whites_Males`,
    settler_women = Females,
    khoe_men = `Hottentots_Males`,
    khoe_women = `Females.1`,
    freeblacks_men = `Free Blacks_Males`,
    freeblacks_women = `Females.2`,
    prize_men = `Prize Negroes_Males`,
    prize_women = `Females.3`,
    slaves_men = `Slaves_Males`,
    slaves_women = `Females.4`,
    settler_sons = `MALES BELOW 16; FEMALES BELOW 20_Whites_Males`,
    settler_daughters = `Females.5`,
    khoe_sons = `Hottentots_Males.1`,
    khoe_daughters = `Females.6`,
    freeblacks_sons = `Free Blacks_Males.1`,
    freeblacks_daughters = `Females.7`,
    prize_sons = `Prize Negroes_Males.1`,
    prize_daughters = `Females.8`,
    slaves_sons = `Slaves_Males.1`,
    slaves_daughters = `Females.9`,
    horses_saddle = `Horses_Saddle`,
    horses_breeding = Breeding,
    cattle_oxen = `Cattle_Draught Oxen`,
    cattle_breeding = `Breeding stock`,
    sheep_wethers = Wethers,
    sheep_breeding = `Sheep_Breeding`,
    sheep_spanish = Spanish,
    donkeys = `Asses and Mules`,
    goats = Goats,
    pigs = Pigs,
    wheat_sown = `Quantity of Muids sown_Wheat`,
    barley_sown = Barley,
    rye_sown = Rye,
    oats_sown = Oats,
    wheat_reaped = `Quantity of Muids reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    hay = `Pounds of Hay`,
    wine = `Leaguers of wine made`,
    brandy = `Leaguers of Brandy made`
  )

## Stellenbosch

# Read the Excel file, assuming the sheet name is "Stellenbosch 1825"
df_stellenbosch <- read_excel("1825 series.xlsx", sheet = "Stellenbosch 1825", col_names = FALSE)

# Extract column names from the first three rows and combine them
col_names_stellenbosch <- df_stellenbosch %>%
  slice(1:3) %>%
  t() %>%
  as.data.frame() %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Ensure column names are unique
col_names_stellenbosch <- make.unique(col_names_stellenbosch)

# Assign unique column names to the dataframe
colnames(df_stellenbosch) <- col_names_stellenbosch

# Remove the first three rows used for column names
df_stellenbosch <- df_stellenbosch %>% slice(-1:-3)

# Filter rows where the second column (Names) is not NA
df_stellenbosch <- df_stellenbosch %>% filter(!is.na(df_stellenbosch[[2]]))

# Select and rename the specified columns
district_sb <- df_stellenbosch %>%
  select(
    settler_men = `White Inhabitants_Males`,
    settler_women = `Females`,
    khoe_men = `Hottentots_Males above 16`,
    khoe_women = `Females above 14.1`,
    freeblacks_men = `Free Blacks_Males`,
    freeblacks_women = `Females.1`,
    prize_men = `Prize Negroes (including those born in this colony)_Males above 16`,
    prize_women = `Females above 14`,
    slaves_men = `Slaves_Males above 16`,
    slaves_women = `Females above 14.2`,
    settler_sons = `Sons below 16`,
    settler_daughters = `Daughters below 20`,
    khoe_sons = `Males below 16.1`,
    khoe_daughters = `Females below 14.1`,
    freeblacks_sons = `Sons below 16.1`,
    freeblacks_daughters = `Daughters below 20.1`,
    prize_sons = `Males below 16`,
    prize_daughters = `Females below 14`,
    slaves_sons = `Males below 16.2`,
    slaves_daughters = `Females below 14.2`,
    horses_saddle = `Horses_Saddle & Waggon`,
    horses_breeding = `Breeding`,
    cattle_oxen = `Black Cattle_Draught Oxen`,
    cattle_breeding = `Breeding Stock`,
    sheep_wethers = `Sheep_Wethers`,
    sheep_breeding = `Breeding.1`,
    sheep_spanish = `Spanish`,
    donkeys = `Asses & Mules`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Quantity of Muids Sown in 1824_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Quantity of Muids Reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    hay = `Pounds of Hay`,
    wine = `Leagers made of_Wine`,
    brandy = `Brandy`
  )

## Graaff-Reinet

# Read the Excel file, assuming the sheet name is "Graaff-Reinet 1825"
df_graaff_reinet <- read_excel("1825 series.xlsx", sheet = "Graaff-Reinet 1825", col_names = FALSE)

# Preview the first few rows to see the data structure
head(df_graaff_reinet)

# Extract column names from the first four rows and combine them
col_names_graaff_reinet <- df_graaff_reinet %>%
  slice(1:4) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_graaff_reinet[col_names_graaff_reinet == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_graaff_reinet <- make.unique(col_names_graaff_reinet)

# Assign the unique column names to the dataframe
colnames(df_graaff_reinet) <- col_names_graaff_reinet

# Remove the first four rows used for column names
df_graaff_reinet <- df_graaff_reinet %>% slice(-1:-4)

# Filter rows where the second column (Names) is not NA
df_graaff_reinet <- df_graaff_reinet %>% filter(!is.na(df_graaff_reinet[[2]]))

# Select and rename the specified columns based on the updated column labels
district_gr <- df_graaff_reinet %>%
  select(
    settler_men = `Families_Men`,
    settler_women = `Women.1`,
    khoe_men = `Hottentots_Males_above 16`,
    khoe_women = `Females_above 20`,
    freeblacks_men = `Free Blacks_Males_above 16`,
    freeblacks_women = `Females_above 20.1`,
    prize_men = `Prize Negroes_Males_above 16`,
    prize_women = `Females_above 20.3`,
    slaves_men = `Slaves_Males_above 16`,
    slaves_women = `Females_above 20.2`,
    settler_sons = `Sons`,
    settler_daughters = `Daughters`,
    khoe_sons = `Males_below 16`,
    khoe_daughters = `Females_below 20`,
    freeblacks_sons = `Males_below 16.1`,
    freeblacks_daughters = `Females_below 20.1`,
    prize_sons = `Males_below 16.3`,
    prize_daughters = `Females_below 20.3`,
    slaves_sons = `Males_below 16.2`,
    slaves_daughters = `Females_below 20.2`,
    horses_saddle = `Livestock_Wagon &_saddle_horses`,
    horses_breeding = `Breeding_horses`,
    cattle_oxen = `Oxen`,
    cattle_breeding = `Breeding_cattle`,
    sheep_wethers = `Wethers`,
    sheep_breeding = `Breeding_sheep`,
    sheep_spanish = `Spanish_sheep`,
    donkeys = `Asses`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Muids sown_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Muids reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    wine = `Leggers_of wine`,
    brandy = `Leggers_of brandy`
  )

##Swellendam

# Read the Excel file, assuming the sheet name is "Swellendam 1825"
df_swellendam <- read_excel("1825 series.xlsx", sheet = "Swellendam 1825", col_names = FALSE)

# Extract column names from the first two rows and combine them
col_names_swellendam <- df_swellendam %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_swellendam[col_names_swellendam == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_swellendam <- make.unique(col_names_swellendam)

# Assign the unique column names to the dataframe
colnames(df_swellendam) <- col_names_swellendam

# Remove the first two rows used for column names
df_swellendam <- df_swellendam %>% slice(-1:-2)

# Convert the `Nr.` column to numeric and handle any non-numeric entries
df_swellendam$Nr. <- as.numeric(df_swellendam$Nr.)


# Create a new column for `settler_women_names`
df_swellendam$settler_women_names <- NA

# Loop over the rows to assign the `settler_women_names`
for(i in seq_len(nrow(df_swellendam) - 1)) {
  # Check if the current row is numbered and the next row is not numbered
  if(!is.na(df_swellendam$Nr.[i]) & is.na(df_swellendam$Nr.[i + 1])) {
    # Assign the name from the next row as `settler_women_names`
    df_swellendam$settler_women_names[i] <- df_swellendam$`Names_Of Inhabitants above 16 years of age`[i + 1]
  }
}

# Now we delete the unnumbered rows that follow numbered rows (except if the next row is also numbered)
rows_to_delete <- c()
for(i in seq_len(nrow(df_swellendam) - 1)) {
  # If the current row is numbered and the next row is unnumbered, mark the next row for deletion
  if(!is.na(df_swellendam$Nr.[i]) & is.na(df_swellendam$Nr.[i + 1])) {
    rows_to_delete <- c(rows_to_delete, i + 1)
  }
}

# Remove the unnumbered rows that follow numbered rows
df_swellendam_cleaned <- df_swellendam[-rows_to_delete, ]

# Remove rows where `Names_Of Inhabitants above 16 years of age` is NA
df_swellendam <- df_swellendam_cleaned[!is.na(df_swellendam_cleaned$`Names_Of Inhabitants above 16 years of age`), ]


# Select and rename the specified columns based on the updated column labels
district_sw <- df_swellendam %>%
  select(
    settler_men = `Families_Men`,
    settler_women = `Women`,
    khoe_men = `Hottentots_Males above 16`,
    khoe_women = `Females above 20`,
    freeblacks_men = `Free Blacks_Males above 16`,
    freeblacks_women = `Females above 20.1`,
    prize_men = `Prize Negroes_Males above 16`,
    prize_women = `Females above 20.3`,
    slaves_men = `Slaves_Males above 16`,
    slaves_women = `Females above 20.2`,
    settler_sons = `Sons`,
    settler_daughters = `Daughters`,
    khoe_sons = `Males below 16`,
    khoe_daughters = `Females below 20`,
    freeblacks_sons = `Males below 16.1`,
    freeblacks_daughters = `Females below 20.1`,
    prize_sons = `Males below 16.3`,
    prize_daughters = `Females below 20.3`,
    slaves_sons = `Males below 16.2`,
    slaves_daughters = `Females below 20.2`,
    horses_saddle = `Horses_Saddle & Waggon`,
    horses_breeding = `Breeding`,
    cattle_oxen = `Black Cattle_Draught Oxen`,
    cattle_breeding = `Breeding Stock`,
    sheep_wethers = `Sheep_Wethers`,
    sheep_breeding = `Breeding.1`,
    sheep_spanish = `Spanish`,
    donkeys = `Asses & Mules`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Muids Sown_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Muids Reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    wine = `Leagers made of_Wine`,
    brandy = `Brandy`
  )

##Albany

# Read the Excel file, assuming the sheet name is "Albany 1825"
df_albany <- read_excel("1825 series.xlsx", sheet = "Albany 1825", col_names = FALSE)

# Preview the first few rows to see the data structure
head(df_albany)

# Extract column names from the first four rows and combine them
col_names_albany <- df_albany %>%
  slice(1:3) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_albany[col_names_albany == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_albany <- make.unique(col_names_albany)

# Assign the unique column names to the dataframe
colnames(df_albany) <- col_names_albany

# Remove the first three rows used for column names
df_albany <- df_albany %>% slice(-1:-3)

# Select and rename the specified columns based on the updated column labels
district_al <- df_albany %>%
  select(
    settler_men = `Families_Men`,
    settler_women = `Women.1`,
    khoe_men = `Hottentots_Males above 16`,
    khoe_women = `Females above 20`,
    freeblacks_men = `Free Blacks_Males above 16`,
    freeblacks_women = `Females above 20.1`,
    prize_men = `Prize Negroes_Males above 16`,
    prize_women = `Females above 20.3`,
    slaves_men = `Slaves_Males above 16`,
    slaves_women = `Females above 20.2`,
    settler_sons = `Sons`,
    settler_daughters = `Daughters`,
    khoe_sons = `Males under 16`,
    khoe_daughters = `Females under 20`,
    freeblacks_sons = `Males under 16.1`,
    freeblacks_daughters = `Females under 20.1`,
    prize_sons = `Males under 16.3`,
    prize_daughters = `Females under 20.3`,
    slaves_sons = `Males under 16.2`,
    slaves_daughters = `Females under 20.2`,
    horses_saddle = `Cattle_Waggon & Saddle Horses`,
    horses_breeding = `Breeding Horses`,
    cattle_oxen = `Oxen`,
    cattle_breeding = `Breeding Cattle`,
    sheep_wethers = `Wethers`,
    sheep_breeding = `Breeding Sheep`,
    sheep_spanish = `Spanish Sheep`,
    donkeys = `Asses`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Muids Sown_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Muids Reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    wine = `Leggers of wine made`,
    brandy = `Leggers of Brandy made`
  )

##Beaufort

# Read the Excel file, assuming the sheet name is "Albany 1825"
df_beaufort <- read_excel("1825 series.xlsx", sheet = "Beaufort 1825", col_names = FALSE)

# Extract column names from the first four rows and combine them
col_names_beaufort <- df_beaufort %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_beaufort[col_names_beaufort == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_beaufort <- make.unique(col_names_beaufort)

# Assign the unique column names to the dataframe
colnames(df_beaufort) <- col_names_beaufort

# Remove the first three rows used for column names
df_beaufort <- df_beaufort %>% slice(-1:-2)

# Select and rename the specified columns based on the updated column labels
district_bf <- df_beaufort %>%
  select(
    settler_men = `Families_Men`,
    settler_women = `Women.1`,
    khoe_men = `Hottentots_Males above 16`,
    khoe_women = `Females above 20`,
    freeblacks_men = `Free Blacks_Males above 16`,
    freeblacks_women = `Females above 20.1`,
    prize_men = `Prize Negroes_Males above 16`,
    prize_women = `Females above 20.3`,
    slaves_men = `Slaves_Males above 16`,
    slaves_women = `Females above 20.2`,
    settler_sons = `Sons`,
    settler_daughters = `Daughters`,
    khoe_sons = `Males under 16`,
    khoe_daughters = `Females under 20`,
    freeblacks_sons = `Males under 16.1`,
    freeblacks_daughters = `Females under 20.1`,
    prize_sons = `Males under 16.3`,
    prize_daughters = `Females under 20.3`,
    slaves_sons = `Males under 16.2`,
    slaves_daughters = `Females under 20.2`,
    horses_saddle = `Cattle_Waggon & Saddle Horses`,
    horses_breeding = `Breeding Horses`,
    cattle_oxen = `Oxen`,
    cattle_breeding = `Breeding Cattle`,
    sheep_wethers = `Wethers`,
    sheep_breeding = `Breeding Sheep`,
    sheep_spanish = `Spanish Sheep`,
    donkeys = `Asses`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Muids Sown_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Muids Reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    wine = `Leggers of wine made`,
    brandy = `Leggers of Brandy made`
  )

##George

# Read the Excel file, assuming the sheet name is "Albany 1825"
df_george <- read_excel("1825 series.xlsx", sheet = "George 1825", col_names = FALSE)

# Extract column names from the first four rows and combine them
col_names_george <- df_george %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_george[col_names_george == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_george <- make.unique(col_names_george)

# Assign the unique column names to the dataframe
colnames(df_george) <- col_names_george

# Remove the first three rows used for column names
df_george <- df_george %>% slice(-1:-2)

# Select and rename the specified columns based on the updated column labels
district_ge <- df_george %>%
  select(
    settler_men = `Families_Men`,
    settler_women = `Women.1`,
    khoe_men = `Hottentots_Males above 16`,
    khoe_women = `Females above 20`,
    freeblacks_men = `Free Blacks_Males above 16`,
    freeblacks_women = `Females above 20.1`,
    prize_men = `Prize Negroes_Males above 16`,
    prize_women = `Females above 20.3`,
    slaves_men = `Slaves_Males above 16`,
    slaves_women = `Females above 20.2`,
    settler_sons = `Sons`,
    settler_daughters = `Daughters`,
    khoe_sons = `Males under 16`,
    khoe_daughters = `Females under 20`,
    freeblacks_sons = `Males under 16.1`,
    freeblacks_daughters = `Females under 20.1`,
    prize_sons = `Males under 16.3`,
    prize_daughters = `Females under 20.3`,
    slaves_sons = `Males under 16.2`,
    slaves_daughters = `Females under 20.2`,
    horses_saddle = `Cattle_Waggon & Saddle Horses`,
    horses_breeding = `Breeding Horses`,
    cattle_oxen = `Oxen`,
    cattle_breeding = `Breeding Cattle`,
    sheep_wethers = `Wethers`,
    sheep_breeding = `Breeding Sheep`,
    sheep_spanish = `Spanish Sheep`,
    donkeys = `Asses`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Muids Sown_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Muids Reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    wine = `Leggers of wine made`,
    brandy = `Leggers of Brandy made`
  )

##Uitenhage

# Read the Excel file, assuming the sheet name is "Albany 1825"
df_uitenhage <- read_excel("1825 series.xlsx", sheet = "Uitenhage 1825", col_names = FALSE)

# Extract column names from the first four rows and combine them
col_names_uitenhage <- df_uitenhage %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_uitenhage[col_names_uitenhage == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_uitenhage <- make.unique(col_names_uitenhage)

# Assign the unique column names to the dataframe
colnames(df_uitenhage) <- col_names_uitenhage

# Remove the first three rows used for column names
df_uitenhage <- df_uitenhage %>% slice(-1:-2)

# Select and rename the specified columns based on the updated column labels
district_ui <- df_uitenhage %>%
  select(
    settler_men = `Families_Men`,
    settler_women = `Women.1`,
    khoe_men = `Hottentots_Males above 16`,
    khoe_women = `Females above 20`,
    freeblacks_men = `Free Blacks_Males above 16`,
    freeblacks_women = `Females above 20.1`,
    prize_men = `Prize Negroes_Males above 16`,
    prize_women = `Females above 20.3`,
    slaves_men = `Slaves_Males above 16`,
    slaves_women = `Females above 20.2`,
    settler_sons = `Sons`,
    settler_daughters = `Daughters`,
    khoe_sons = `Males under 16`,
    khoe_daughters = `Females under 20`,
    freeblacks_sons = `Males under 16.1`,
    freeblacks_daughters = `Females under 20.1`,
    prize_sons = `Males under 16.3`,
    prize_daughters = `Females under 20.3`,
    slaves_sons = `Males under 16.2`,
    slaves_daughters = `Females under 20.2`,
    horses_saddle = `Cattle_Waggon & Saddle Horses`,
    horses_breeding = `Breeding Horses`,
    cattle_oxen = `Oxen`,
    cattle_breeding = `Breeding Cattle`,
    sheep_wethers = `Wethers`,
    sheep_breeding = `Breeding Sheep`,
    sheep_spanish = `Spanish Sheep`,
    donkeys = `Asses`,
    goats = `Goats`,
    pigs = `Pigs`,
    wheat_sown = `Muids Sown_Wheat`,
    barley_sown = `Barley`,
    oats_sown = `Oats`,
    rye_sown = `Rye`,
    wheat_reaped = `Muids Reaped_Wheat`,
    barley_reaped = `Barley.1`,
    rye_reaped = `Rye.1`,
    oats_reaped = `Oats.1`,
    wine = `Leggers of wine made`,
    brandy = `Leggers of Brandy made`
  )

##Clanwilliam

# Read the Excel file, assuming the sheet name is "Clanwilliam 1824"
df_clanwilliam <- read_excel("1825 series.xlsx", sheet = "Clanwilliam 1824", col_names = FALSE)

# Preview the first few rows to see the data structure
head(df_clanwilliam)

# Extract column names from the first two rows and combine them
col_names_clanwilliam <- df_clanwilliam %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_clanwilliam[col_names_clanwilliam == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_clanwilliam <- make.unique(col_names_clanwilliam)

# Assign the unique column names to the dataframe
colnames(df_clanwilliam) <- col_names_clanwilliam

# Remove the first two rows used for column names
df_clanwilliam <- df_clanwilliam %>% slice(-1:-2)

# Select and rename the specified columns based on the Dutch column labels
district_cl <- df_clanwilliam %>%
  select(
    settler_men = `Mans`,  # Men
    settler_women = `Vrouwen`,  # Women
    khoe_men = `Hottentotten_Mans boven de 16 jaren`,  
    khoe_women = `Vrouwen boven de 14 jaren`, 
    prize_men = `Prysnegers_Mans`, 
    prize_women = `Vrouwen.2`,  
    slaves_men = `Slaven_Mans boven de 16 jaren`,  
    slaves_women = `Vrouwen boven de 14 jaren.1`, 
    settler_sons = `Zoons beneden 16 jaren`,  
    settler_daughters = `Dogters beneden 20 jaren`, 
    khoe_sons = `Mans beneden de 16 jaren`,  
    khoe_daughters = `Vrouwen beneden de 14 jaren`,  
    freeblacks_sons = `Zoons in de Colonie geboren`,  
    freeblacks_daughters = `Dogters in de Colonie geboren`,  
    prize_sons = `Zoons in de Colonie aan gebragt`,
    prize_daughters = `Dogters in de Colonie aan gebragt`,
    slaves_sons = `Mans beneden de 16 jaren.1`,
    slaves_daughters = `Vrouwen beneden de 14 jaren.1`,
    horses_saddle = `Wagen & Ryd Paarden`,
    horses_breeding = `Aanfok Paarden`,  # Breeding horses
    cattle_oxen = `Trek Ossen`,  # Oxen
    cattle_breeding = `Aanteel Beesten`,  # Breeding cattle
    sheep_wethers = `Schapen_Hamels`,  # Wethers
    sheep_breeding = `Aanteel`,  # Breeding sheep
    sheep_spanish = `Wolgevende`,
    goats = `Bokken`,  # Goats
    pigs = `Varkens`,  # Pigs
    wheat_sown = `Mudden Gezaaid_Tarwe`,  # Wheat sown
    barley_sown = `Garst`,  # Barley sown
    oats_sown = `Haver`,  # Oats sown
    rye_sown = `Rogge`,  # Rye sown
    wheat_reaped = `Mudden Gewonnen_Tarwe`,  # Wheat reaped
    barley_reaped = `Garst.1`,  # Barley reaped
    oats_reaped = `Haver.1`,  # Oats reaped
    rye_reaped = `Rogge.1`,  # Rye reaped
    wine = `Leggers Gewonnen_Wyn`,  # Wine
    brandy = `Brandewyn`  # Brandy
  )

##Cradock

# Read the Excel file, assuming the sheet name is "Cradock 1823"
df_cradock <- read_excel("1825 series.xlsx", sheet = "Cradock 1823", col_names = FALSE)

# Extract column names from the first two rows and combine them
col_names_cradock <- df_cradock %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_cradock[col_names_cradock == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_cradock <- make.unique(col_names_cradock)

# Assign the unique column names to the dataframe
colnames(df_cradock) <- col_names_cradock

# Remove the first two rows used for column names
df_cradock <- df_cradock %>% slice(-1:-2)

# Select and rename the specified columns based on the Dutch column labels
district_cr <- df_cradock %>%
  select(
    settler_men = `Families_Mans`,  # Men
    settler_women = `Vrouwens`,  # Women
    khoe_men = `Hottentotten_Mans boven de 16 jaren`,  
    khoe_women = `Vrouwen boven de 14 jaren`, 
    prize_men = `Apprentice_Mans`, 
    prize_women = `Vrouwens.1`,  
    slaves_men = `Slaven_Mans boven de 16 jaren`,  
    slaves_women = `Vrouwen boven de 14 jaren.1`, 
    settler_sons = `Zoons`,  
    settler_daughters = `Dogters`, 
    khoe_sons = `Mans beneden de 16 jaren`,  
    khoe_daughters = `Vrouwen beneden de 14 jaren`,  
    slaves_sons = `Mans beneden de 16 jaren.1`,
    slaves_daughters = `Vrouwen beneden de 14 jaren.1`,
    horses_saddle = `Paarden_Wagen en Ryd`,
    horses_breeding = `Aanteel Paarden`,  # Breeding horses
    cattle_oxen = `Trek ossen`,  # Oxen
    cattle_breeding = `Aanteel Beesten`,  # Breeding cattle
    sheep_wethers = `Schaapen_Hamels`,  # Wethers
    sheep_breeding = `Aanteel Schaapen`,  # Breeding sheep
    sheep_spanish = `Spaansche`,
    goats = `Bokken`,  # Goats
    pigs = `Varkens`,  # Pigs
    wheat_sown = `Mudden Gezaaid_Tarwe`,  # Wheat sown
    barley_sown = `Garst`,  # Barley sown
    oats_sown = `Haver`,  # Oats sown
    rye_sown = `Rogge`,  # Rye sown
    wheat_reaped = `Mudden Gewonnen_Tarwe`,  # Wheat reaped
    barley_reaped = `Garst.1`,  # Barley reaped
    oats_reaped = `Haver.1`,  # Oats reaped
    rye_reaped = `Rogge.1`,  # Rye reaped
    wine = `Leggens Gewonnen_Wyn`,  # Wine
    brandy = `Brandewyn`  # Brandy
  )

##Woes, Worcester

# Read the Excel file, assuming the sheet name is "Worcester 1824"
df_worcester <- read_excel("1825 series.xlsx", sheet = "Worcester 1824", col_names = FALSE)

# Extract column names from the first two rows and combine them
col_names_worcester <- df_worcester %>%
  slice(1:2) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_worcester[col_names_worcester == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_worcester <- make.unique(col_names_worcester)

# Assign the unique column names to the dataframe
colnames(df_worcester) <- col_names_worcester

# Remove the first two rows used for column names
df_worcester <- df_worcester %>% slice(-1:-2)

# Select and rename the specified columns based on the Dutch column labels
district_wo <- df_worcester %>%
  select(
    settler_men = `Mans`,  # Men
    settler_women = `Vrouwen`,  # Women
    khoe_men = `Hottentotten_Mans boven de 16 jaren`,  
    khoe_women = `Vrouwen boven de 14 jaren`, 
    prize_men = `Prysnegers_Mans`, 
    prize_women = `Vrouwen.2`,  
    slaves_men = `Slaven_Mans boven de 16 jaren`,  
    slaves_women = `Vrouwen boven de 14 jaren.1`, 
    settler_sons = `Zoons beneden 16 jaren`,  
    settler_daughters = `Dochters`, 
    khoe_sons = `Mans beneden de 16 jaren`,  
    khoe_daughters = `Vrouwen beneden de 14 jaren`,  
    freeblacks_sons = `Zoons in de Colonie geboren`,  
    freeblacks_daughters = `Dochters in de Colonie geboren`,  
    prize_sons = `Zoons in de Colonie aan gebragt`,
    prize_daughters = `Dochters in de Colonie aan gebragt`,
    slaves_sons = `Mans beneden de 16 jaren.1`,
    slaves_daughters = `Vrouwen beneden de 14 jaren.1`,
    horses_saddle = `Wagen & Ryd Paarden`,
    horses_breeding = `Aanfok Paarden`,  # Breeding horses
    cattle_oxen = `Trek Ossen`,  # Oxen
    cattle_breeding = `Aanteel Beesten`,  # Breeding cattle
    sheep_wethers = `Schapen_Hamels`,  # Wethers
    sheep_breeding = `Aanfok`,  # Breeding sheep
    sheep_spanish = `Wolgevende`,
    donkeys = `Ezels`,
    goats = `Bokken`,  # Goats
    pigs = `Varkens`,  # Pigs
    wheat_sown = `Mudden Gezaaid_Tarwe`,  # Wheat sown
    barley_sown = `Garst`,  # Barley sown
    oats_sown = `Haver`,  # Oats sown
    rye_sown = `Rogge`,  # Rye sown
    wheat_reaped = `Mudden Gewonnen_Tarwe`,  # Wheat reaped
    barley_reaped = `Garst.1`,  # Barley reaped
    oats_reaped = `Haver.1`,  # Oats reaped
    rye_reaped = `Rogge.1`,  # Rye reaped
    wine = `Leggers Gewonnen_Wyn`,  # Wine
    brandy = `Brandewyn`  # Brandy
  )

#Analysis of the 1825 districts

# Combine all districts into one dataframe
all_districts <- bind_rows(
  district_al %>% mutate(district = "district_al"),
  district_bf %>% mutate(district = "district_bf"),
  district_cl %>% mutate(district = "district_cl"),
  district_cr %>% mutate(district = "district_cr"),
  district_ct %>% mutate(district = "district_ct"),
  district_ge %>% mutate(district = "district_ge"),
  district_gr %>% mutate(district = "district_gr"),
  district_sb %>% mutate(district = "district_sb"),
  district_sw %>% mutate(district = "district_sw"),
  district_ui %>% mutate(district = "district_ui"),
  district_wo %>% mutate(district = "district_wo")
)

# Relabel the districts
district_labels <- c(
  "district_al" = "Albany",
  "district_bf" = "Beaufort",
  "district_cl" = "Clanwilliam",
  "district_cr" = "Cradock",
  "district_ct" = "Cape",
  "district_ge" = "George",
  "district_gr" = "Graaff-Reinet",
  "district_sb" = "Stellenbosch",
  "district_sw" = "Swellendam",
  "district_ui" = "Uitenhage",
  "district_wo" = "Worcester"
)

district_counts <- all_districts %>%
  count(district, name = "num_observations")

print(district_counts)

nrow(all_districts)

stellenbosch_share <- all_districts %>%
  summarise(share = mean(district == "Stellenbosch"))

print(stellenbosch_share)
.S2("districts_pre", list(district_counts = district_counts, n = nrow(all_districts), stellenbosch_share = stellenbosch_share))  # [S2-HOOK extraction only]

# Step 1: Update the district names in the dataset
all_districts <- all_districts %>%
  mutate(district = recode(district, !!!district_labels))

# Step 2: Remove observations where there isn't a 1 in either settler_men or settler_women
all_districts <- all_districts %>%
  filter(settler_men == 1 | settler_women == 1)

# Step 3: Ensure all columns except "district" are numeric
all_districts <- all_districts %>%
  mutate(across(-district, as.numeric))

# Step 4: Replace NAs in all columns except "district" with 0
all_districts <- all_districts %>%
  mutate(across(-district, ~ ifelse(is.na(.), 0, .)))

# Step 5: Create a new variable "household_count" which is 1 for each household
all_districts <- all_districts %>%
  mutate(household_count = 1)
.S2("n1825_filtered", nrow(all_districts))  # [S2-HOOK extraction only]

# Create a new variable "horses" as the sum of horses_saddle and horses_breeding
all_districts <- all_districts %>%
  mutate(horses = horses_saddle + horses_breeding)

# Step 6: Calculate total slaves_men and number of households by district
slave_ownership_by_district <- all_districts %>%
  group_by(district) %>%
  summarise(
    total_slaves_men = sum(slaves_men, na.rm = TRUE),
    total_households = sum(household_count)
  )

# Step 7: Calculate slaves_men per household
slave_ownership_by_district <- slave_ownership_by_district %>%
  mutate(slaves_men_per_household = total_slaves_men / total_households)

# Plot with household count at the bottom of the bars and average number of slave men per household above the bars
slaves1825 = ggplot(slave_ownership_by_district, aes(x = district, y = slaves_men_per_household)) +
  geom_bar(stat = "identity", fill = "white", color = "black") +
  
  # Add text for the number of households near the bottom of the bars
  geom_text(aes(label = total_households), vjust = 1.5, color = "black", position = position_stack(vjust = 0)) +
  
  # Add text for the average number of slave men per household above the bars
  geom_text(aes(label = round(slaves_men_per_household, 2)), vjust = -0.5, color = "black") +
  
  theme_minimal() +
  labs(y = "Average Number of Slave Men Per Household") +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none",  # Remove the legend
    plot.title = element_blank(),  # Remove the title
    axis.title.x = element_blank()  # Remove X-axis label
  )

# Display the plot
print(slaves1825)

# Save the plot as a jpg file
ggsave("slaves1825.jpg", plot = slaves1825, width = 9, height = 6, dpi = 300)

# Step 1: Reshape the data to long format for plotting
pyramid_data <- all_districts %>%
  select(district, slaves_men, slaves_women, slaves_sons, slaves_daughters) %>%
  mutate(
    slaves_men = -slaves_men,  # Negative values for men (so they appear on the left)
    slaves_sons = -slaves_sons  # Negative values for boys (so they appear on the left)
  ) %>%
  pivot_longer(cols = c(slaves_men, slaves_women, slaves_sons, slaves_daughters),
               names_to = "category",
               values_to = "count") %>%
  mutate(gender = case_when(
    category %in% c("slaves_men", "slaves_sons") ~ "Male",
    category %in% c("slaves_women", "slaves_daughters") ~ "Female"
  ),
  age_group = case_when(
    category %in% c("slaves_men", "slaves_women") ~ "Above Age",
    category %in% c("slaves_sons", "slaves_daughters") ~ "Below Age"
  ))

# Step 2: Set the order of age groups to have "Above Age" displayed first
pyramid_data$age_group <- factor(pyramid_data$age_group, levels = c("Below Age", "Above Age"))


# Step 3: Create the population pyramid plot
ggplot(pyramid_data, aes(x = age_group, y = count, fill = gender)) +
  geom_bar(stat = "identity") +
  coord_flip() +  # Flip coordinates for a horizontal bar chart
  scale_y_continuous(labels = abs, breaks = c(-2000, 0, 2000)) +  # Set x-axis labels at -2000, 0, and 2000
  facet_wrap(~ district) +  # Create one pyramid per district
  theme_minimal() +
  scale_fill_manual(values = c("Male" = "grey50", "Female" = "grey80")) +  # Black/white color scheme
  labs(x = "Age Group", y = "Population Count", fill = "Gender") +
  theme(
    legend.position = "bottom",
    plot.title = element_blank(),
    axis.title.y = element_blank(),
    strip.text = element_text(size = 8)
  )


##Lorenz curves

# Step 1: Prepare the data by filtering out massive outliers in wheat_sown (values > 1000)
all_districts <- all_districts %>%
  filter(wheat_sown <= 100 | is.na(wheat_sown))  # Keep values less than or equal to 1000 or NA
.S2("n1825_wheatfilter", nrow(all_districts))  # [S2-HOOK extraction only]


# Step 2: Calculate the Lorenz curve for wheat_sown by district
lorenz_data <- all_districts %>%
  group_by(district) %>%
  summarise(
    Lc_obj = list(Lc(wheat_sown[!is.na(wheat_sown)]))  # Remove NA values before calculating Lorenz curve
  ) %>%
  rowwise() %>%
  mutate(p = list(Lc_obj$p), L = list(Lc_obj$L)) %>%  # Extract the p and L components from the Lc object
  unnest(cols = c(p, L))  # Unnest the results to create a long format dataframe

# Step 1: Filter the data for the specified districts
selected_districts <- c("Cradock", "Stellenbosch", "Swellendam", "Cape")

# Filter the data for the four districts
lorenz_data_filtered <- lorenz_data %>%
  filter(district %in% selected_districts)

# Step 2: Plot the Lorenz curves for the selected districts, in black and white with labels
wheatineq = ggplot(lorenz_data_filtered, aes(x = p, y = L, color = district)) +
  geom_line(size = 1, color = "black", aes(linetype = district)) +  # Black lines with different line types for distinction
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey") +  # Line of equality
  labs(x = "Cumulative Share of Households", y = "Cumulative Share of Wheat Sown") +
  theme_minimal() +
  theme(
    legend.position = "none",  # Remove the legend
    plot.title = element_blank(),
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10)
  ) +
  
  # Add text labels directly on the lines in the lower half, with black color
  geom_text_repel(data = lorenz_data_filtered %>% group_by(district) %>% filter(L == max(L[L <= 0.2])),  # Position at lower half
                  aes(label = district), 
                  size = 3, color = "black", hjust = 0, nudge_y = -0.05)  # Set text color to black


# Display the plot
print(wheatineq)

# Save the plot as a jpg file
ggsave("wheatineq.jpg", plot = wheatineq, width = 9, height = 6, dpi = 300)

#Livestock inequality

# Step 1: Filter for the four variables and rename them accordingly
colony_data <- all_districts %>%
  select(horses_saddle, cattle_oxen, cattle_breeding, sheep_breeding) %>%
  rename(
    Horses = horses_saddle,
    Oxen = cattle_oxen,
    Cattle = cattle_breeding,
    Sheep = sheep_breeding
  ) %>%
  mutate(across(everything(), as.numeric))  # Ensure all columns are numeric

# Step 2: Calculate the Lorenz curve for each variable
lorenz_data <- colony_data %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "value") %>%
  group_by(variable) %>%
  summarise(
    Lc_obj = list(Lc(value[!is.na(value)]))  # Calculate Lorenz curve, ignoring NA values
  ) %>%
  rowwise() %>%
  mutate(p = list(Lc_obj$p), L = list(Lc_obj$L)) %>%  # Extract cumulative shares (p, L)
  unnest(cols = c(p, L))  # Unnest the lists to get a long format dataframe

# Step 3: Plot the Lorenz curves for all four variables, with black text labels
livestock = ggplot(lorenz_data, aes(x = p, y = L, color = variable)) +
  geom_line(size = 1, color = "black", aes(linetype = variable)) +  # Black lines with different line types
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "grey") +  # Add line of equality
  labs(x = "Cumulative Share of Households", y = "Cumulative Share of Ownership") +
  theme_minimal() +
  theme(
    legend.position = "none",  # Remove the legend
    plot.title = element_blank(),
    axis.title.x = element_text(size = 10),
    axis.title.y = element_text(size = 10)
  ) +
  
  # Add text labels directly on the lines in the lower half (below 0.2) with black text
  geom_text_repel(data = lorenz_data %>% group_by(variable) %>% filter(L == max(L[L <= 0.2])),  # Position at lower half
                  aes(label = variable), 
                  size = 3, color = "black", hjust = 0, nudge_y = -0.05)  # Set text color to black

# Display the plot
print(livestock)

# Save the plot as a jpg file
ggsave("livestock.jpg", plot = wheatineq, width = 9, height = 6, dpi = 300)


###Spider Gini

# Define the function to calculate the Gini coefficient
calculate_gini <- function(x) {
  if (all(x == 0)) {
    return(0)  # If all values are zero, return 0
  } else {
    return(Gini(x, na.rm = TRUE))  # Calculate Gini and handle NAs
  }
}

# Step 1: Calculate the Gini coefficients for each crop/variable by district
gini_data <- all_districts %>%
  group_by(district) %>%
  summarise(
    Horses = calculate_gini(horses),
    Oxen = calculate_gini(cattle_oxen),
    Cattle = calculate_gini(cattle_breeding),
    Sheep = calculate_gini(sheep_breeding),
    Wheat = calculate_gini(wheat_sown),
    Wine = calculate_gini(wine)
  )

# Step 2: Prepare data for radar chart (normalize the data between 0 and 1)
gini_data_radar <- as.data.frame(gini_data)
rownames(gini_data_radar) <- gini_data_radar$district
gini_data_radar <- gini_data_radar[, -1]  # Remove district column

# Add rows with min and max values for scaling the radar chart (required by fmsb)
gini_data_radar <- rbind(rep(1, ncol(gini_data_radar)), rep(0, ncol(gini_data_radar)), gini_data_radar)

# Prepare the radar chart data
gini_data_radar <- as.data.frame(gini_data)
rownames(gini_data_radar) <- gini_data_radar$district
gini_data_radar <- gini_data_radar[, -1]  # Remove district column

# Add rows with min and max values for scaling the radar chart (as required by radarchart)
gini_data_radar <- rbind(rep(1, ncol(gini_data_radar)), rep(0, ncol(gini_data_radar)), gini_data_radar)


# Specify the file path and name
jpeg("radar_chart_large.jpg", width = 9, height = 6, units = "in", res = 300)

# Remove white space by adjusting margins using par()
par(mar = c(1, 1, 1, 1))  # Set margins to minimal values (bottom, left, top, right)

# Plot the Radar Chart with Smaller Text and Less White Space
radarchart(gini_data_radar, axistype = 1,
           # Black lines
           pcol = c(rep("black", nrow(gini_data_radar) - 2)),  # All lines in black
           pfcol = c(rep(NA, nrow(gini_data_radar) - 2)),  # No fill
           plwd = 3,  # Line width
           cglcol = "black",  # Grid line color
           cglty = 1,  # Grid line type
           axislabcol = "black",  # Axis label color
           vlcex = 0.8,  # Reduce variable label size for less bulk
           caxislabels = seq(0, 1, 0.2),  # Axis labels
           cglwd = 1.5)  # Grid line width

# Close the file
dev.off()

# Check which districts have a Gini coefficient of zero for wine
zero_gini_wine <- gini_data %>%
  filter(Wine == 0)

# View the districts with zero Gini for wine
print(zero_gini_wine)

###Dot plot

# Define the function to calculate the Gini coefficient
calculate_gini <- function(x) {
  if (all(x == 0)) {
    return(0)  # If all values are zero, return 0
  } else {
    return(Gini(x, na.rm = TRUE))  # Calculate Gini and handle NAs
  }
}

# Step 1: Calculate the Gini coefficients for each crop/variable by district
gini_data <- all_districts %>%
  group_by(district) %>%
  summarise(
    Horses = calculate_gini(horses),
    Oxen = calculate_gini(cattle_oxen),
    Cattle = calculate_gini(cattle_breeding),
    Sheep = calculate_gini(sheep_breeding),
    Wheat = calculate_gini(wheat_sown),
    Wine = calculate_gini(wine)
  )

# Step 1: Restructure the Gini data for plotting, excluding Wine for Albany
gini_long_radar <- gini_data %>%
  pivot_longer(cols = c(Horses, Oxen, Cattle, Sheep, Wheat, Wine), 
               names_to = "asset", values_to = "gini_coefficient") %>%
  filter(!(district == "Albany" & asset == "Wine"))  # Exclude Wine for Albany

# Step 2: Create the dot plot in black and white with different shapes for each asset
gini_radar_dot_plot <- ggplot(gini_long_radar, aes(x = district, y = gini_coefficient, shape = asset)) +
  geom_point(size = 4, color = "black", position = position_dodge(width = 0.6)) +  # Set points to black
  labs(x = "District", y = "Gini coefficient") +  # Set x and y axis labels
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",  # Move the legend to the bottom
    legend.title = element_blank(),  # Remove the legend title
    legend.box = "horizontal"  # Put all legend items in one row
  ) +
  guides(shape = guide_legend(nrow = 1)) +  # Ensure the legend items are in one row
  scale_y_continuous(limits = c(0, 1)) +  # Set y-axis limits between 0 and 1
  scale_shape_manual(values = c(16, 17, 18, 15, 3, 8))  # Different shapes for each asset

# Step 3: Print the plot
print(gini_radar_dot_plot)

# Optionally, save the plot as a jpg
ggsave("gini_radar_dot_plot.jpg", plot = gini_radar_dot_plot, width = 9, height = 6, dpi = 300)


#Figure 3


# Step 1: Pivot into long format to calculate Gini and totals more clearly
gini_size_data <- all_districts %>%
  select(district, horses, cattle_oxen, cattle_breeding, sheep_breeding, wheat_sown, wine) %>%
  pivot_longer(cols = -district, names_to = "asset", values_to = "value") %>%
  filter(!is.na(value)) %>%
  group_by(district, asset) %>%
  summarise(
    gini = Gini(value, na.rm = TRUE),
    total = sum(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    asset = recode(asset,
                   horses = "Horses",
                   cattle_oxen = "Oxen",
                   cattle_breeding = "Cattle",
                   sheep_breeding = "Sheep",
                   wheat_sown = "Wheat",
                   wine = "Wine"),
    log_total = log1p(total)  # log(1 + x) to handle 0s and preserve skew
  )
.S2("fig3", gini_size_data)  # [S2-HOOK extraction only]

# Step 1: Normalize asset totals within each asset (0–1 scaling)
gini_size_data_scaled <- gini_size_data %>%
  group_by(asset) %>%
  mutate(
    size_scaled = total / max(total, na.rm = TRUE)  # scale 0–1
  ) %>%
  ungroup()

# Step 2: Plot with no legend, size scaled within facet
gini_bubble_plot_scaled <- ggplot(gini_size_data_scaled, aes(x = district, y = gini, size = size_scaled)) +
  geom_point(shape = 21, fill = "black", colour = "white", alpha = 0.85) +
  facet_wrap(~ asset, ncol = 2) +
  scale_size(range = c(1, 10), guide = "none") +  # no legend
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "District", y = "Gini coefficient") +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold"),
    legend.position = "none"
  )

# Step 3: Print the plot
print(gini_bubble_plot_scaled)

# Optionally, save the plot as a jpg
ggsave("gini_bubble_plot_scaled.jpg", plot = gini_bubble_plot_scaled, width = 9, height = 6, dpi = 300)




###Opgaafrolle for Khoe and mission stations

#Groenekloof (Mamre)

# Read the Excel file, assuming the sheet name is "Worcester 1824"
df_groenekloof <- read_excel("Groenekloof.xlsx", sheet = "1825", col_names = FALSE)

# Extract column names from the first two rows and combine them
col_names_groenekloof <- df_groenekloof %>%
  slice(1:3) %>%
  t() %>%  # Transpose the rows into columns
  as.data.frame(stringsAsFactors = FALSE) %>%
  unite("col_name", sep = "_", na.rm = TRUE) %>%
  pull(col_name)

# Handle any zero-length column names by replacing them with "Unnamed"
col_names_groenekloof[col_names_groenekloof == ""] <- "Unnamed"

# Ensure the column names are unique
col_names_groenekloof <- make.unique(col_names_groenekloof)

# Assign the unique column names to the dataframe
colnames(df_groenekloof) <- col_names_groenekloof

# Remove the first three rows used for column names
df_groenekloof <- df_groenekloof %>% slice(-1:-3)

# Replace all NA values in the dataset with 0 for columns that contain at least one non-NA value
df_groenekloof <- df_groenekloof %>%
  mutate_all(~ ifelse(is.na(.), 0, .))

# Select and rename the specified columns based on the Dutch column labels
district_gk <- df_groenekloof %>%
  select(
    khoe_men = `Hottentots_Males`,  
    khoe_women = `Females.1`, 
    khoe_sons = `Hottentots_Males.1`,  
    khoe_daughters = `Females.6`,  
    horses_saddle = `Horses_Saddle`,
    horses_breeding = `Breeding`,  # Breeding horses
    cattle_oxen = `Cattle_Draught Oxen`,  # Oxen
    cattle_breeding = `Breeding stock`,  # Breeding cattle
    sheep_wethers = `Wethers`,  # Wethers
    sheep_breeding = `Sheep_Breeding`,  # Breeding sheep
    sheep_spanish = `Spanish`,
    donkeys = `Asses and Mules`,
    goats = `Goats`,  # Goats
    pigs = `Pigs`,  # Pigs
    wheat_sown = `Quantity of Muids sown_Wheat`,  # Wheat sown
    barley_sown = `Barley`,  # Barley sown
    oats_sown = `Rye`,  # Oats sown
    rye_sown = `Oats`,  # Rye sown
    wheat_reaped = `Quantity of Muids reaped_Wheat`,  # Wheat reaped
    barley_reaped = `Barley.1`,  # Barley reaped
    oats_reaped = `Rye.1`,  # Oats reaped
    rye_reaped = `Oats.1`,  # Rye reaped
    wine = `Leaguers of wine made`,  # Wine
    brandy = `Leaguers of Brandy made`  # Brandy
  )

# Convert relevant columns to numeric, replacing non-numeric values with NA
district_gk <- district_gk %>%
  mutate(across(
    c(khoe_men, khoe_women, khoe_sons, khoe_daughters, horses_saddle, horses_breeding, 
      cattle_oxen, cattle_breeding, sheep_wethers, sheep_breeding, sheep_spanish, donkeys, 
      goats, pigs, wheat_sown, barley_sown, oats_sown, rye_sown, wheat_reaped, barley_reaped, 
      oats_reaped, rye_reaped, wine, brandy),
    ~ as.numeric(as.character(.))
  ))

# Create a function to calculate Gini coefficient, ignoring NA values
calculate_gini <- function(x) {
  if (all(is.na(x))) return(NA)  # Return NA if all values are missing
  Gini(x, na.rm = TRUE)  # Calculate Gini coefficient, excluding NA values
}

# Create the new 'horses' variable by adding 'horses_saddle' and 'horses_breeding'
district_gk <- district_gk %>%
  mutate(horses = horses_saddle + horses_breeding)

# Create the new 'sheep' variable by adding 'sheep_wethers', 'sheep_breeding', and 'sheep_spanish'
district_gk <- district_gk %>%
  mutate(sheep = sheep_wethers + sheep_breeding + sheep_spanish)

# Calculate Gini coefficients for the specified variables
gini_results_gk <- district_gk %>%
  summarise(
    gini_horses = calculate_gini(horses),
    gini_oxen = calculate_gini(cattle_oxen),
    gini_cattle = calculate_gini(cattle_breeding),
    gini_sheep = calculate_gini(sheep),
    gini_wheat_reaped = calculate_gini(wheat_reaped)
  )

# View the results
print(gini_results_gk)


###Swartrivier

# Read the Excel file, assuming the sheet name is "Worcester 1824"
df_swartrivier <- read_excel("Swartrivier.xlsx", sheet = "Data", col_names = TRUE)

# Replace all NA values in the dataset with 0 for columns that contain at least one non-NA value
df_swartrivier <- df_swartrivier %>%
  mutate_all(~ ifelse(is.na(.), 0, .))

# Select and rename the specified columns based on the Dutch column labels
district_sr <- df_swartrivier %>%
  select(
    khoe_men = `Men`,  
    khoe_women = `Women`, 
    khoe_sons = `Sons`,  
    khoe_daughters = `Daughters`,  
    horses_saddle = `Wagon and Saddle Horses`,
    horses_breeding = `Breeding Horses`,  # Breeding horses
    cattle_oxen = `Oxen`,  # Oxen
    cattle_breeding = `Breeding cattle`,  # Breeding cattle
    sheep_wethers = `Wethers`,  # Wethers
    sheep_breeding = `Breeding Sheep`,  # Breeding sheep
    goats = `Goats`,  # Goats
    pigs = `Pigs`,  # Pigs
    wheat_sown = `Wheat sown`,  # Wheat sown
    barley_sown = `Barley sown`,  # Barley sown
    oats_sown = `Rye sown`,  # Oats sown
    rye_sown = `Oats sown`,  # Rye sown
    wheat_reaped = `Wheat`,  # Wheat reaped
    barley_reaped = `barley`,  # Barley reaped
    oats_reaped = `Rye`,  # Oats reaped
    rye_reaped = `Oats`,  # Rye reaped
  )


# Convert relevant columns to numeric and replace NAs with zeros
district_sr <- district_sr %>%
  mutate(across(
    c(khoe_men, khoe_women, khoe_sons, khoe_daughters, horses_saddle, horses_breeding, 
      cattle_oxen, cattle_breeding, sheep_wethers, sheep_breeding, goats, pigs, 
      wheat_sown, barley_sown, oats_sown, rye_sown, wheat_reaped, barley_reaped, 
      oats_reaped, rye_reaped),
    ~ as.numeric(as.character(.))  # Convert to numeric
  )) %>%
  mutate(across(
    everything(), 
    ~ replace_na(., 0)  # Replace all NA values with 0
  ))

# Create the new 'horses' variable by adding 'horses_saddle' and 'horses_breeding'
district_sr <- district_sr %>%
  mutate(horses = horses_saddle + horses_breeding)

# Create the new 'sheep' variable by adding 'sheep_wethers', 'sheep_breeding', and 'sheep_spanish'
district_sr <- district_sr %>%
  mutate(sheep = sheep_wethers + sheep_breeding)

# Create a function to calculate Gini coefficient, ignoring NA values
calculate_gini <- function(x) {
  if (all(is.na(x))) return(NA)  # Return NA if all values are missing
  Gini(x, na.rm = TRUE)  # Calculate Gini coefficient, excluding NA values
}

# Calculate Gini coefficients for the specified variables
gini_results_sr <- district_sr %>%
  summarise(
    gini_horses = calculate_gini(horses),
    gini_oxen = calculate_gini(cattle_oxen),
    gini_cattle = calculate_gini(cattle_breeding),
    gini_wheat_reaped = calculate_gini(wheat_reaped)
  )

# View the results
print(gini_results_sr)

###Bethelsdorp

# Read the Excel file, assuming the sheet name is "Worcester 1824"
df_bethelsdorp <- read_excel("EBTstation.xlsx", sheet = "Bethelsdorp1825", col_names = TRUE)

# Select and rename the specified columns based on the Dutch column labels
district_bd <- df_bethelsdorp %>%
  select(
    khoe_men = `men`,  
    khoe_women = `women`, 
    khoe_sons = `sonsunder16`,  
    khoe_daughters = `daughters`,  
    horses_saddle = `horseM`,
    horses_breeding = `horseF`,  # Breeding horses
    cattle_oxen = `cattleM`,  # Oxen
    cattle_breeding = `cattleF`,  # Breeding cattle
    sheep_breeding = `sheep_goats`,  # Breeding sheep
  )

# Convert relevant columns to numeric, replacing non-numeric values with NA
district_bd <- district_bd %>%
  mutate(across(
    c(khoe_men, khoe_women, khoe_sons, khoe_daughters, horses_saddle, horses_breeding, 
      cattle_oxen, cattle_breeding, sheep_breeding),
    ~ as.numeric(as.character(.))
  ))

# Create the new 'horses' variable by adding 'horses_saddle' and 'horses_breeding'
district_bd <- district_bd %>%
  mutate(horses = horses_saddle + horses_breeding)

# Calculate Gini coefficients for the specified variables
gini_results_bd <- district_bd %>%
  summarise(
    gini_horses = calculate_gini(horses),
    gini_oxen = calculate_gini(cattle_oxen),
    gini_cattle = calculate_gini(cattle_breeding),
    gini_sheep = calculate_gini(sheep_breeding)
  )

# View the results
print(gini_results_bd)

# Calculate the number of households with at least one horse in Bethelsdorp
households_with_horses_bd <- district_bd %>%
  filter(horses > 0) %>%
  summarise(total_households = n())

# Calculate the number of households with at least one horse in Groenekloof
households_with_horses_gk <- district_gk %>%
  filter(horses > 0) %>%
  summarise(total_households = n())

# Print results
cat("Households with horses in Bethelsdorp:", households_with_horses_bd$total_households, "\n")
cat("Households with horses in Groenekloof:", households_with_horses_gk$total_households, "\n")

# Calculate the number of households with at least one sheep in Bethelsdorp
households_with_sheep_bd <- district_bd %>%
  filter(sheep_breeding > 0) %>%
  summarise(total_households = n())

# Calculate the number of households with at least one sheep in Groenekloof
households_with_sheep_gk <- district_gk %>%
  filter(sheep > 0) %>%
  summarise(total_households = n())

# Print results
cat("Households with sheep in Bethelsdorp:", households_with_sheep_bd$total_households, "\n")
cat("Households with sheep in Groenekloof:", households_with_sheep_gk$total_households, "\n")
.S2("khoe_counts", list(gk = nrow(district_gk), sr = nrow(district_sr), bd = nrow(district_bd), sheep_bd = households_with_sheep_bd$total_households, sheep_gk = households_with_sheep_gk$total_households, horses_bd = households_with_horses_bd$total_households, horses_gk = households_with_horses_gk$total_households))  # [S2-HOOK extraction only]

###Combine

# Add a region column to each dataset and combine them
gini_results_gk <- gini_results_gk %>% mutate(region = "Groenekloof")
gini_results_sr <- gini_results_sr %>% mutate(region = "Swartrivier")
gini_results_bd <- gini_results_bd %>% mutate(region = "Bethelsdorp")

# Combine all the Gini results into one dataframe
gini_combined <- bind_rows(gini_results_gk, gini_results_sr, gini_results_bd)

# Reshape the combined dataframe to long format for plotting
gini_long <- gini_combined %>%
  pivot_longer(cols = starts_with("gini_"), names_to = "asset", values_to = "gini_coefficient") %>%
  # Rename the assets to more readable labels
  mutate(asset = case_when(
    asset == "gini_cattle" ~ "Cattle",
    asset == "gini_horses" ~ "Horses",
    asset == "gini_oxen" ~ "Oxen",
    asset == "gini_sheep" ~ "Sheep",
    asset == "gini_wheat_reaped" ~ "Wheat reaped",
    TRUE ~ asset  # Keep any other asset names unchanged
  ))

# Plot the Gini Coefficients using a dot plot with the updated x-axis label
gini_dot_plot <- ggplot(gini_long, aes(x = region, y = gini_coefficient, shape = asset)) +
  geom_point(size = 4, color = "black", position = position_dodge(width = 0.6)) +  # Set points to black
  labs(x = "Settlement", y = "Gini coefficient") +  # Update x-axis label to 'Settlement'
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",  # Move the legend to the bottom
    legend.title = element_blank()  # Remove the legend title
  ) +
  scale_y_continuous(limits = c(0, 1)) +  # Set y-axis limits between 0 and 1
  scale_shape_manual(values = c(16, 17, 18, 15, 3))  # Different shapes for each asset


# Print the plot
print(gini_dot_plot)

# Optionally, save the plot
ggsave("gini_dot_plot.jpg", plot = gini_dot_plot, width = 9, height = 6, dpi = 300)

#New figure 6

# Step 1: Combine data and prepare totals per region/asset
gini_long_with_totals <- bind_rows(
  gini_results_gk %>% mutate(region = "Groenekloof"),
  gini_results_sr %>% mutate(region = "Swartrivier"),
  gini_results_bd %>% mutate(region = "Bethelsdorp")
) %>%
  pivot_longer(cols = starts_with("gini_"), names_to = "asset", values_to = "gini") %>%
  mutate(asset = case_when(
    asset == "gini_cattle" ~ "Cattle",
    asset == "gini_horses" ~ "Horses",
    asset == "gini_oxen" ~ "Oxen",
    asset == "gini_sheep" ~ "Sheep",
    asset == "gini_wheat_reaped" ~ "Wheat reaped",
    TRUE ~ asset
  ))
.S2("fig6", gini_long_with_totals)  # [S2-HOOK extraction only]

# Step 2: Add total asset values per region (assumes you have totals in same format or compute them)
# If you already have them, just bind with `gini_long_with_totals`
# Here's an example assuming totals are already in similar shape

asset_totals <- gini_long_with_totals %>%
  group_by(region, asset) %>%
  summarise(total = runif(1, 100, 10000), .groups = "drop")  # Replace with actual totals

# Step 3: Merge Gini and total data
gini_bubble_data <- gini_long_with_totals %>%
  left_join(asset_totals, by = c("region", "asset")) %>%
  group_by(asset) %>%
  mutate(size_scaled = total / max(total, na.rm = TRUE)) %>%
  ungroup()

# Step 4: Create bubble plot
gini_bubble_plot <- ggplot(gini_bubble_data, aes(x = region, y = gini, size = size_scaled)) +
  geom_point(shape = 21, fill = "black", colour = "white", alpha = 0.85) +
  facet_wrap(~ asset, ncol = 2) +
  scale_size(range = c(1, 10), guide = "none") +
  scale_y_continuous(limits = c(0, 1)) +
  labs(x = "Settlement", y = "Gini coefficient") +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "none"
  )

# Step 5: Display and save the plot
print(gini_bubble_plot)
ggsave("gini_bubble_plot_settlements.jpg", plot = gini_bubble_plot, width = 9, height = 6, dpi = 300)

### PROBATES

# Read the Excel file, assuming the sheet name is "MOOC_probates"
probates <- read_excel("MOOC_probates.xlsx", sheet = "Sheet1", col_names = TRUE)

# Remove observations with years before 1700 or after 1839
probates <- probates %>%
  filter(year >= 1700 & year <= 1839)
.S2("n_probates", nrow(probates))  # [S2-HOOK extraction only]

# Step 1: Create the decade (period) variable using case_when()
probates <- probates %>%
  mutate(period = case_when(
    year >= 1700 & year < 1710 ~ 1700,
    year >= 1710 & year < 1720 ~ 1710,
    year >= 1720 & year < 1730 ~ 1720,
    year >= 1730 & year < 1740 ~ 1730,
    year >= 1740 & year < 1750 ~ 1740,
    year >= 1750 & year < 1760 ~ 1750,
    year >= 1760 & year < 1770 ~ 1760,
    year >= 1770 & year < 1780 ~ 1770,
    year >= 1780 & year < 1790 ~ 1780,
    year >= 1790 & year < 1800 ~ 1790,
    year >= 1800 & year < 1810 ~ 1800,
    year >= 1810 & year < 1820 ~ 1810,
    year >= 1820 & year < 1830 ~ 1820,
    year >= 1830 & year < 1840 ~ 1830
  ))

# Step 2: Function to calculate Gini coefficients
calculate_gini <- function(x) {
  if (all(is.na(x))) return(NA)  # Return NA if all values are missing
  Gini(x, na.rm = TRUE)  # Calculate the Gini coefficient, removing NA values
}

# Step 3: Calculate the Gini coefficients by period for the specified variables
gini_by_period <- probates %>%
  group_by(period) %>%
  summarise(
    horses_gini = calculate_gini(horse_nr),
    cattle_gini = calculate_gini(cattle_nr),
    sheep_gini = calculate_gini(sheep_nr),
    plough_gini = calculate_gini(plough_nr),
    wagon_gini = calculate_gini(wagon_nr)
  )

# View the result
print(gini_by_period)
.S2("fig4", gini_by_period)  # [S2-HOOK extraction only]


# Reshape the data for a slope graph
gini_long <- gini_by_period %>%
  pivot_longer(cols = -period, names_to = "variable", values_to = "gini_value")

# Plot the Slope Graph
ggplot(gini_long, aes(x = period, y = gini_value, group = variable, color = variable)) +
  geom_line(size = 1.5) +
  geom_point(size = 2) +
  theme_minimal() +
  labs(x = "Period", y = "Gini Coefficient", title = "Changes in Gini Coefficients Over Time") +
  theme(legend.position = "bottom")


# Plot the Slope Graph with line types, renamed variables, unified legend, and restricted x-axis limits
gini_probate_graph <- ggplot(gini_long, aes(x = period, y = gini_value, group = variable)) +
  geom_line(aes(color = variable, linetype = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(1700, 1830, by = 10), limits = c(1700, 1830)) +  # Set x-axis limits and breaks
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +  # Set y-axis limits to match the style
  labs(x = "Period",
       y = "Gini coefficient") +
  scale_color_manual(values = c("horses_gini" = "grey60", 
                                "cattle_gini" = "black", 
                                "sheep_gini" = "grey40", 
                                "plough_gini" = "grey20", 
                                "wagon_gini" = "black"),
                     labels = c("Cattle", "Horses", "Sheep", "Ploughs", "Wagons")) +  # Renamed variables
  scale_linetype_manual(values = c("horses_gini" = "solid", 
                                   "cattle_gini" = "dashed", 
                                   "sheep_gini" = "twodash", 
                                   "plough_gini" = "solid", 
                                   "wagon_gini" = "dotted"),
                        labels = c("Cattle", "Horses", "Sheep", "Ploughs", "Wagons")) +  # Match line types with labels
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank(),
        legend.position = "bottom",           # Move legend to the bottom
        legend.title = element_blank(),
        legend.box = "horizontal")            # Combine legend into one box

# Print the plot
gini_probate_graph

# Save the plot as an image file
ggsave("gini_probate_graph.jpg", plot = gini_probate_graph, width = 9, height = 6, dpi = 300)


try({  # [S2-RUN] wrap failing non-figure block (slave-owner share in probates)
# Step 1: Create a new column 'name1t' by combining 'Owner_name' and 'Owner_surname'
probates <- probates %>%
  mutate(name1t = paste(Owner_name, Owner_surname, sep = " "))  # Create the 'name1t' column

# Step 2: Create a decade variable from the 'year' column
probates <- probates %>%
  mutate(decade = (year %/% 10) * 10)  # Create a 'decade' column by rounding down the year to the nearest decade

# Step 3: Count the total number of unique settlers per decade
total_settlers_per_decade <- probates %>%
  group_by(decade) %>%
  summarise(total_settlers = n_distinct(name1t))  # Count unique settlers (name1t)

# Step 4: Count the number of settlers who owned slaves per decade
settlers_with_slaves_per_decade <- probates %>%
  filter(slave == 1) %>%
  group_by(decade) %>%
  summarise(slave_owners = n_distinct(name1t))  # Count unique settlers who owned slaves (name1t)

# Step 5: Combine the total settlers and slave owners per decade
settlers_ratio <- total_settlers_per_decade %>%
  left_join(settlers_with_slaves_per_decade, by = "decade") %>%
  mutate(slave_owner_percentage = (slave_owners / total_settlers) * 100)  # Calculate the percentage of settlers who owned slaves

# View the result
print(settlers_ratio)
})  # [S2-RUN] end try(): block fails because MOOC_probates.xlsx has no Owner_name/Owner_surname columns; it feeds no figure

### SLAVE EMANCIPATION DATASET

# Read the Excel file
sed <- read_excel("Slave Emancipation Dataset.xlsx", sheet = "Sheet1", col_names = TRUE)
.S2("sed", list(n = nrow(sed), bydist = dplyr::count(sed, District_name)))  # [S2-HOOK extraction only]

# Step 1: Combine 'Owner_name' and 'Owner_surname' into one unique variable called 'Owner_fullname'
sed <- sed %>%
  mutate(Owner_fullname = paste(Owner_name, Owner_surname, sep = " "))

# Count the number of unique 'Owner_fullname' observations
unique_owners_count <- sed %>%
  summarise(total_owners = n_distinct(Owner_fullname))

# Create a function to calculate Gini coefficient, ignoring NA values
calculate_gini <- function(x) {
  if (all(is.na(x))) return(NA)  # Return NA if all values are missing
  Gini(x, na.rm = TRUE)  # Calculate Gini coefficient, excluding NA values
}

# Gini for Valuation by district
gini_valuation_by_district <- sed %>%
  group_by(District_name) %>%
  summarise(valuation_gini = calculate_gini(Valuation))

# Gini for Compensation by district
gini_compensation_by_district <- sed %>%
  group_by(District_name) %>%
  summarise(compensation_gini = calculate_gini(Compensation))

# View the results
print(gini_valuation_by_district)
print(gini_compensation_by_district)

# First, combine the two Gini tables (for valuation and compensation) into one dataset
gini_combined <- gini_valuation_by_district %>%
  inner_join(gini_compensation_by_district, by = "District_name")

# Plot the scatter plot with ggrepel for label adjustment
gini_scatter_plot <- ggplot(gini_combined, aes(x = valuation_gini, y = compensation_gini)) +
  geom_point(color = "black", size = 3) +        # Plot the points in black
  geom_text_repel(aes(label = District_name), color = "black", size = 3, max.overlaps = 10) +  # Use ggrepel to prevent label overlap
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") +  # Add 45-degree line
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +  # Set x-axis from 0 to 1
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +  # Set y-axis from 0 to 1
  labs(x = "Gini coefficient (Valuation)", 
       y = "Gini coefficient (Compensation)") +
  theme_minimal() +
  theme(
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  )


# Display the plot
print(gini_scatter_plot)

# Save the plot as an image file (optional)
ggsave("gini_scatter_plot_bw.jpg", plot = gini_scatter_plot, width = 9, height = 6, dpi = 300)

### Let's add settlers with zero slaves

# Step 1: Combine 'Owner_name' and 'Owner_surname' into one unique variable called 'Owner_fullname'
sed2 <- sed %>%
  mutate(Owner_fullname = paste(Owner_name, Owner_surname, sep = " "))

# Step 2: Count the current number of settlers per district
settlers_per_district <- sed2 %>%
  group_by(District_name) %>%
  summarise(current_settlers = n_distinct(Owner_fullname))

# Step 3: Calculate the number of zero-asset settlers to add for each district
settlers_to_add_per_district <- settlers_per_district %>%
  mutate(settlers_to_add = ceiling(current_settlers * (100 / 30))) %>%
  mutate(settlers_to_add = settlers_to_add - current_settlers)  # Calculate additional settlers needed

# Step 4: Create new settlers with zero assets per district
new_settlers <- settlers_to_add_per_district %>%
  rowwise() %>%
  do(data.frame(
    Owner_fullname = paste0("Zero_Asset_Settler_", seq(1, .$settlers_to_add)),
    District_name = .$District_name,  # Use the district name from each row
    Valuation = 0,  # Zero valuation
    Compensation = 0  # Zero compensation
  )) %>%
  ungroup()

# Step 5: Combine the original dataset with the new settlers
sed_full <- bind_rows(sed2, new_settlers)
.S2("fig5_newsettlers", list(add = settlers_to_add_per_district, n_new = nrow(new_settlers)))  # [S2-HOOK extraction only]

# Step 6: Recalculate Gini for Valuation by district (including the zero-asset settlers)
gini_valuation_by_district_full <- sed_full %>%
  group_by(District_name) %>%
  summarise(valuation_gini = calculate_gini(Valuation))

# Step 7: Recalculate Gini for Compensation by district (including the zero-asset settlers)
gini_compensation_by_district_full <- sed_full %>%
  group_by(District_name) %>%
  summarise(compensation_gini = calculate_gini(Compensation))

# View the results
print(gini_valuation_by_district_full)
print(gini_compensation_by_district_full)

###Both scatters on same graph - Figure 5

# Step 1: Combine the original Gini results (excluding non-slave owners)
gini_combined_before <- gini_valuation_by_district %>%
  inner_join(gini_compensation_by_district, by = "District_name") %>%
  mutate(type = "Excluding non–slave-owning settlers")

# Step 2: Combine the Gini results after adding zero-asset settlers
gini_combined_after <- gini_valuation_by_district_full %>%
  inner_join(gini_compensation_by_district_full, by = "District_name") %>%
  mutate(type = "Including non–slave-owning settlers")

# Step 3: Combine both datasets into one
gini_combined_all <- bind_rows(gini_combined_before, gini_combined_after)
.S2("fig5", gini_combined_all)  # [S2-HOOK extraction only]

# Step 4: Plot the scatter plot with points for both before and after zero-asset settlers are added
gini_scatter_plot <- ggplot(gini_combined_all, aes(x = valuation_gini, y = compensation_gini, color = type, shape = type)) +
  geom_point(size = 3) +  # Plot the points with different shapes and colors
  geom_text_repel(aes(label = District_name), size = 3, max.overlaps = 10) +  # Use ggrepel to prevent label overlap
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "black") +  # Add 45-degree line
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +  # Set x-axis from 0 to 1
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +  # Set y-axis from 0 to 1
  labs(x = "Gini coefficient (Valuation)", 
       y = "Gini coefficient (Compensation)") +  # Remove legend title
  scale_color_manual(values = c(
    "Excluding non–slave-owning settlers" = "black",
    "Including non–slave-owning settlers" = "grey40"
  )) +
  scale_shape_manual(values = c(
    "Excluding non–slave-owning settlers" = 16,
    "Including non–slave-owning settlers" = 17
  )) +
  theme_minimal() +
  theme(
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom",  # Move the legend to the bottom
    legend.title = element_blank()  # Remove the "Data Type" title
  )

# Step 5: Display the plot
print(gini_scatter_plot)

# Optional: Save the plot as an image file
ggsave("gini_combined_scatter_plot.jpg", plot = gini_scatter_plot, width = 9, height = 6, dpi = 300)


##Calculate total inequality in Swellendam

# Step 1: Filter Swellendam settler households
swellendam_settlers <- all_districts %>%
  filter(district == "district_sw") %>%
  select(horses, cattle_oxen, cattle_breeding, sheep_breeding, wheat_sown, wine)

# Step 2: Prepare Khoe settlements associated with Swellendam
khoe_swellendam <- bind_rows(district_sr, district_gk) %>%
  select(horses, cattle_oxen, cattle_breeding, sheep_breeding, wheat_sown, wine)

# Step 3: Combine settler and Khoe data
combined_swellendam <- bind_rows(swellendam_settlers, khoe_swellendam)

# Step 4: Calculate Gini coefficient for each asset
combined_ginis <- combined_swellendam %>%
  summarise(
    gini_horses = Gini(horses, na.rm = TRUE),
    gini_oxen = Gini(cattle_oxen, na.rm = TRUE),
    gini_cattle = Gini(cattle_breeding, na.rm = TRUE),
    gini_sheep = Gini(sheep_breeding, na.rm = TRUE),
    gini_wheat = Gini(wheat_sown, na.rm = TRUE),
    gini_wine = Gini(wine, na.rm = TRUE)
  )

# Step 5: Print results
print(combined_ginis)
.S2("swellendam_combined", list(combined_ginis = combined_ginis, n_settlers = nrow(swellendam_settlers), n_khoe = nrow(khoe_swellendam)))  # [S2-HOOK extraction only]





























###ADDENDUM

#Previous version:

###OPGAAFROLLE

# CLEANING THE DATA

# Define the file path and sheet name

# Define the file path and sheet name
file_path <- "stellenbosch_clean_july2024.xlsx"
sheet_name <- "sheet1"

# Determine the number of columns
temp_df <- read_excel(file_path, sheet = sheet_name, n_max = 1)
num_columns <- ncol(temp_df)

# Create a vector of "text" types for each column
col_types <- rep("text", num_columns)

# Read the Excel file and specify all columns as text
opgaaf <- read_excel(file_path, sheet = sheet_name, col_types = col_types)

opgaaf_new <- data.table(opgaaf)


columns_to_convert <- c(
  "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
  "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", "horse_breeding",
  "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether",
  "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed",
  "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", "potatoes_vol",
  "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", "barleyzk_vol",
  "bzkoorn", "bzkoorn1", "vines", "wine", "brandy"
)

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to the specified columns
opgaaf_new <- clean_and_convert_columns_to_numeric(opgaaf_new, columns_to_convert)

# Now clean opgaaf
opgaaf2 <- data.table(opgaaf_new)

### Take care of zeros and NAs

# Function to replace NAs with zeros based on year only
replace_na_with_zero <- function(dt, columns, year_col = "year") {
  for (col in columns) {
    # Identify years where there are non-NA entries for the specific column
    non_na_years <- dt[!is.na(get(col)), unique(get(year_col))]
    
    # Loop through each year where there are non-NA entries
    for (year_val in non_na_years) {
      # Replace NAs with zeros for the specific year
      dt[get(year_col) == year_val & is.na(get(col)), (col) := 0]
    }
  }
  return(dt)
}

columns_to_convert2 <- c(
  "settler_men", "settler_women", "settler_sons", "settler_daughters", "settler_children",
  "servants", "servant_coachman", "servant_personal", "servant_home", "servant_cook",
  "slave_men", "slave_women", "slave_sons", "slave_daughters", "slave_children",
  "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters", "freeblack_men", "freeblack_women",
  "freeblack_sons", "freeblack_daughters", "prizenegro_men", "prizenegro_women", "prizenegro_sons",
  "prizenegro_daughters", "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
  "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", "horse_breeding",
  "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether",
  "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed",
  "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", "potatoes_vol",
  "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", "barleyzk_vol",
  "bzkoorn", "bzkoorn1", "vines", "wine", "brandy", "swords", "side_arm", "pistols", "rifle",
  "wagons", "carts", "wagons_pleasure", "carts_pleasure"
)


# Apply the NA replacement function to the specified columns
opgaaf2 <- replace_na_with_zero(opgaaf2, columns_to_convert2)


#write_xlsx(opgaaf2, "opgaaf2.xlsx")
#opgaaf2 <- read_excel("opgaaf2.xlsx")

# Now clean opgaaf
opgaaf <- data.table(opgaaf2)

## Livestock

# Function to replace NAs in the specified column with the sum of related columns
replace_na_with_sum <- function(dt, main_col, related_columns) {
  # Calculate the sum of the related columns
  dt[, temp_sum := rowSums(.SD, na.rm = TRUE), .SDcols = related_columns]
  
  # Replace NAs in the main column with the calculated sum
  dt[is.na(get(main_col)), (main_col) := temp_sum]
  
  # Drop the temporary column
  dt[, temp_sum := NULL]
  
  return(dt)
}

# Define the related columns for horses, cattle, and sheep
horse_columns <- c("horse_foals", "horse_work", "horse_breeding", "horse_pleasure")
cattle_columns <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves")
sheep_columns <- c("sheep_breeding", "sheep_wool", "sheep_wether", "sheep_goats")

# Apply the function to the data table for horses
opgaaf <- replace_na_with_sum(opgaaf, "horses", horse_columns)

# Apply the function to the data table for cattle
opgaaf[, cattle := rowSums(.SD, na.rm = TRUE), .SDcols = cattle_columns]

# Apply the function to the data table for sheep
opgaaf <- replace_na_with_sum(opgaaf, "sheep", sheep_columns)

#write_xlsx(opgaaf, "opgaaf .xlsx")
#opgaaf <- read_excel("opgaaf.xlsx")

# Convert your data.table to a CSV file
#fwrite(opgaaf_new, "opgaaf.csv")

# Read the CSV file back into R
#opgaaf <- fread("opgaaf.csv")

### People

# Convert opgaaf to a data.table if it isn't already
opgaaf <- as.data.table(opgaaf)

# Define the columns for slaves
slave_columns <- c("slave_men", "slave_women", "slave_sons", "slave_daughters")

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to opgaaf for slave columns
opgaaf <- clean_and_convert_columns_to_numeric(opgaaf, slave_columns)

# Create the new variable 'slaves' by summing up the specified columns using dplyr
opgaaf <- opgaaf %>%
  mutate(slaves = rowSums(select(., all_of(slave_columns)), na.rm = TRUE))


# Define the columns for slaves
khoe_columns <- c("khoe_men", "khoe_women", "khoe_sons", "khoe_daughters")


# Apply the cleaning function to opgaaf for slave columns
opgaaf <- clean_and_convert_columns_to_numeric(opgaaf, khoe_columns)

# Create the new variable 'slaves' by summing up the specified columns using dplyr
opgaaf <- opgaaf %>%
  mutate(khoe = rowSums(select(., all_of(khoe_columns)), na.rm = TRUE))



### Settlers

# Convert opgaaf to a data.table if it isn't already
opgaaf <- as.data.table(opgaaf)

# Define the columns for settlers
settler_columns <- c("settler_men", "settler_women", "settler_sons", "settler_daughters")

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to opgaaf for settler columns
opgaaf <- clean_and_convert_columns_to_numeric(opgaaf, settler_columns)

# Create the new variable 'settlers' by summing up the specified columns using dplyr within data.table
opgaaf <- opgaaf %>%
  mutate(settlers = rowSums(select(., all_of(settler_columns)), na.rm = TRUE))

# Convert your data.table to an Excel file
write_xlsx(opgaaf, "opgaaf.xlsx")

#opgaaf1 <- read_excel("opgaaf.xlsx")


prices <- read_excel("price_series.xlsx")


### INEQUALITY


### BEGIN THE ANALYSIS!

# Convert opgaaf to a data.table if it isn't already
opgaaf <- as.data.table(opgaaf1)

# Ensure the year column is numeric
opgaaf[, year := as.numeric(year)]

# Check for any NAs introduced by coercion and handle them if necessary
opgaaf <- opgaaf[!is.na(year)]

# Create the decade variable using the data.table syntax
opgaaf[, decade := (year %/% 10) * 10]

# Define the columns to keep
columns_to_keep <- c("year", "decade", "names_men", "settler_men", "settlers", "slave_men", "slaves", "khoe", "slave_women", "slave_sons", "slave_daughters",
                     "horses", "cattle", "sheep", "wheat_vol", "vines", "wine")



# Subset the data.table to keep only the specified columns
opgaaf <- opgaaf[, ..columns_to_keep]

#write_xlsx(opgaaf3, "opgaaf3.xlsx")
#opgaaf3 <- read_excel("opgaaf3.xlsx")


# Drop observations where wine > 10000 or wine >= vines, only if wine is not NA
opgaaf <- opgaaf[!(ifelse(!is.na(wine) & !is.na(vines), wine > 10000 | wine > vines, FALSE))]

###Trimming outliers

# Define the variables to filter
variables_to_filter <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine")


# Function to filter out the top 1% and bottom 1% within each decade
trim_outliers <- function(dt, var) {
  dt[, (var) := ifelse(get(var) >= quantile(get(var), 0.01, na.rm = TRUE) &
                         get(var) <= quantile(get(var), 0.99, na.rm = TRUE), get(var), NA), 
     by = decade]
  return(dt)
}

# Apply the filtering function to each variable
for (var in variables_to_filter) {
  opgaaf <- trim_outliers(opgaaf, var)
}


####This is where you have to return to work with slaves

# Ensure that all relevant columns are numeric
opgaaf[, horses := as.numeric(horses)]
opgaaf[, cattle := as.numeric(cattle)]
opgaaf[, sheep := as.numeric(sheep)]
opgaaf[, wheat_vol := as.numeric(wheat_vol)]
opgaaf[, vines := as.numeric(vines)]
opgaaf[, wine := as.numeric(wine)]

# Modify the descriptive statistics calculation to handle missing values and ensure consistent types
descriptive_stats <- opgaaf[, .(
  horses_mean = mean(as.numeric(horses), na.rm = TRUE),
  horses_sd = sd(as.numeric(horses), na.rm = TRUE),
  horses_max = ifelse(all(is.na(horses)), as.numeric(NA), max(horses, na.rm = TRUE)),
  horses_count = sum(!is.na(horses)),
  
  cattle_mean = mean(as.numeric(cattle), na.rm = TRUE),
  cattle_sd = sd(as.numeric(cattle), na.rm = TRUE),
  cattle_max = ifelse(all(is.na(cattle)), as.numeric(NA), max(cattle, na.rm = TRUE)),
  cattle_count = sum(!is.na(cattle)),
  
  sheep_mean = mean(as.numeric(sheep), na.rm = TRUE),
  sheep_sd = sd(as.numeric(sheep), na.rm = TRUE),
  sheep_max = ifelse(all(is.na(sheep)), as.numeric(NA), max(sheep, na.rm = TRUE)),
  sheep_count = sum(!is.na(sheep)),
  
  wheat_vol_mean = mean(as.numeric(wheat_vol), na.rm = TRUE),
  wheat_vol_sd = sd(as.numeric(wheat_vol), na.rm = TRUE),
  wheat_vol_max = ifelse(all(is.na(wheat_vol)), as.numeric(NA), max(wheat_vol, na.rm = TRUE)),
  wheat_vol_count = sum(!is.na(wheat_vol)),
  
  vines_mean = mean(as.numeric(vines), na.rm = TRUE),
  vines_sd = sd(as.numeric(vines), na.rm = TRUE),
  vines_max = ifelse(all(is.na(vines)), as.numeric(NA), max(vines, na.rm = TRUE)),
  vines_count = sum(!is.na(vines)),
  
  wine_mean = mean(as.numeric(wine), na.rm = TRUE),
  wine_sd = sd(as.numeric(wine), na.rm = TRUE),
  wine_max = ifelse(all(is.na(wine)), as.numeric(NA), max(wine, na.rm = TRUE)),
  wine_count = sum(!is.na(wine))
), by = decade]

# View the result
print(descriptive_stats)

# Calculate the number of observations for each variable by decade and the total
observations_by_decade <- opgaaf[, .(
  horses_obs = sum(!is.na(horses)),
  cattle_obs = sum(!is.na(cattle)),
  sheep_obs = sum(!is.na(sheep)),
  wheat_vol_obs = sum(!is.na(wheat_vol)),
  vines_obs = sum(!is.na(vines)),
  wine_obs = sum(!is.na(wine))
), by = decade]

# Calculate total number of observations across all decades
observations_total <- opgaaf[, .(
  horses_obs_total = sum(!is.na(horses)),
  cattle_obs_total = sum(!is.na(cattle)),
  sheep_obs_total = sum(!is.na(sheep)),
  wheat_vol_obs_total = sum(!is.na(wheat_vol)),
  vines_obs_total = sum(!is.na(vines)),
  wine_obs_total = sum(!is.na(wine))
)]

# Combine results into a single data.table
observations_summary <- rbindlist(list(observations_by_decade, observations_total), use.names = TRUE, fill = TRUE)

# Display the results
observations_summary




# Define the variables to be used
variables_to_plot <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Replace NAs with 0 for the specified variables
opgaaf[, (variables_to_plot) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = variables_to_plot]

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot)))) != length(variables_to_plot))

# Calculate the Gini coefficient for each variable by year
gini_values <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), ~ Gini(.x, na.rm = TRUE)))

# Calculate the number of observations per year
obs_per_year <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(count = n())

# Transform Gini data to long format for ggplot
gini_long <- gini_values %>%
  pivot_longer(cols = -year, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels <- c("horses" = "Horses", "cattle" = "Cattle", "sheep" = "Sheep", 
            "wheat_vol" = "Wheat", "vines" = "Vines", "wine" = "Wine")

# Create a custom scale for line types and colors
line_types <- c("horses" = "dotted", "cattle" = "dotdash", "sheep" = "longdash", 
                "wheat_vol" = "twodash", "vines" = "dotted", "wine" = "solid")

line_colors <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                 "wheat_vol" = "grey70", "vines" = "grey30", "wine" = "black")

# Plot the Gini coefficients over time
opgaafgini = ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long$year, na.rm = TRUE), max(gini_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_color_manual(values = line_colors, name = NULL, labels = labels) +
  labs(x = "Year",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border

opgaafgini
ggsave("opgaafgini.jpg", width = 9, height = 6, dpi = 300)

# Calculate the total number of non-NA observations for each variable
total_observations <- opgaaf %>%
  summarise(
    horses_obs = sum(!is.na(horses)),
    cattle_obs = sum(!is.na(cattle)),
    sheep_obs = sum(!is.na(sheep)),
    wheat_vol_obs = sum(!is.na(wheat_vol)),
    vines_obs = sum(!is.na(vines)),
    wine_obs = sum(!is.na(wine))
  )

# View the results
print(total_observations)



### Inequality with a bundle

# Create a 'period' column in opgaaf3 to match the decades in the prices data
opgaaf <- opgaaf %>%
  mutate(period = case_when(
    year >= 1680 & year < 1690 ~ 1680,
    year >= 1690 & year < 1700 ~ 1690,
    year >= 1700 & year < 1710 ~ 1700,
    year >= 1710 & year < 1720 ~ 1710,
    year >= 1720 & year < 1730 ~ 1720,
    year >= 1730 & year < 1740 ~ 1730,
    year >= 1740 & year < 1750 ~ 1740,
    year >= 1750 & year < 1760 ~ 1750,
    year >= 1760 & year < 1770 ~ 1760,
    year >= 1770 & year < 1780 ~ 1770,
    year >= 1780 & year < 1790 ~ 1780,
    year >= 1790 & year < 1800 ~ 1790,
    year >= 1800 & year < 1810 ~ 1800,
    year >= 1810 & year < 1820 ~ 1810,
    year >= 1820 & year < 1830 ~ 1820,
    year >= 1830 & year < 1840 ~ 1830
  ))

# Now perform the left join on the 'period' column
opgaaf_filtered <- opgaaf %>%
  left_join(prices, by = "period")

# Calculate the bundle value for each good (multiply quantity by price)
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(cattle_value = cattle * cattle_breeding,
         sheep_value = sheep.x * sheep.y,
         horses_value = horses.x * horses.y,
         wheat_value = wheat_vol.x * wheat_vol.y,
         wine_value = wine.x * wine.y)

# Define the new variables to be used (the total value of the goods)
variables_to_plot_bundle <- c("cattle_value", "sheep_value", "horses_value", "wheat_value", "wine_value")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_filtered %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot_bundle)))) != length(variables_to_plot_bundle))

# Calculate the Gini coefficient for each variable by period (decade)
gini_values_bundle <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(across(all_of(variables_to_plot_bundle), ~ Gini(.x, na.rm = TRUE)))

# Transform Gini data to long format for ggplot
gini_long_bundle <- gini_values_bundle %>%
  pivot_longer(cols = -period, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels_bundle <- c("cattle_value" = "Cattle Value", "sheep_value" = "Sheep Value", 
                   "horses_value" = "Horses Value", "wheat_value" = "Wheat Value", 
                   "wine_value" = "Wine Value")

# Create a custom scale for line types and colors
line_types_bundle <- c("cattle_value" = "dotted", "sheep_value" = "dotdash", 
                       "horses_value" = "longdash", "wheat_value" = "twodash", 
                       "wine_value" = "solid")

line_colors_bundle <- c("cattle_value" = "grey60", "sheep_value" = "black", 
                        "horses_value" = "grey50", "wheat_value" = "grey70", 
                        "wine_value" = "black")

# Plot the Gini coefficients over time for the bundle values
opgaafgini_bundle = ggplot(gini_long_bundle, aes(x = period, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long_bundle$period, na.rm = TRUE), max(gini_long_bundle$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  scale_linetype_manual(values = line_types_bundle, name = NULL, labels = labels_bundle) +
  scale_color_manual(values = line_colors_bundle, name = NULL, labels = labels_bundle) +
  labs(x = "Period",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border

opgaafgini_bundle
ggsave("opgaafgini_bundle.jpg", width = 9, height = 6, dpi = 300)


#Basket

# Calculate the total value of all goods combined for each period
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

# Summarize total value by period
total_values_by_period <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(total_value = sum(total_value, na.rm = TRUE))

# Plot the total production value over time
opgaaf_total_value = ggplot(total_values_by_period, aes(x = period, y = total_value)) +
  geom_line(size = 0.8, color = "black") +
  scale_x_continuous(breaks = seq(min(total_values_by_period$period, na.rm = TRUE), max(total_values_by_period$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, NA)) +
  labs(x = "Period",
       y = "Total Production Value") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank())  # Remove the black border

opgaaf_total_value
ggsave("opgaaf_total_value.jpg", width = 9, height = 6, dpi = 300)


##Gini

# Calculate the total production value for each household (row) by summing the values of the five goods
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

# Calculate the Gini coefficient of the total production value for each period (decade)
gini_total_production <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(gini_total_value = Gini(total_value, na.rm = TRUE))

# Plot the Gini coefficient of the total production value over time
opgaafgini_total = ggplot(gini_total_production, aes(x = period, y = gini_total_value)) +
  geom_line(size = 0.8, color = "black") +
  scale_x_continuous(breaks = seq(min(gini_total_production$period, na.rm = TRUE), max(gini_total_production$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  labs(x = "Period",
       y = "Gini coefficient (total value)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank())  # Remove the black border

opgaafgini_total
ggsave("opgaafgini_total_value.jpg", width = 9, height = 6, dpi = 300)

### Inequality of slave ownership

# Define the variables to be used
variables_to_plot <- c("slave_men", "slave_women", "slave_sons", "slave_daughters")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot)))) != length(variables_to_plot))

# Calculate the Gini coefficient for each variable by year
gini_values <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), ~ Gini(.x, na.rm = TRUE)))

# Calculate the number of observations per year
obs_per_year <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(count = n())

# Transform Gini data to long format for ggplot
gini_long <- gini_values %>%
  pivot_longer(cols = -year, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels <- c("slave_men" = "Slave men", "slave_women" = "Slave women", "slave_sons" = "Slave sons", 
            "slave_daughters" = "Slave daughters")

# Create a custom scale for line types and colors
line_types <- c("slave_men" = "dotted", "slave_women" = "dotdash", "slave_sons" = "longdash", 
                "slave_daughters" = "solid")

line_colors <- c("slave_men" = "grey60", "slave_women" = "black", "slave_sons" = "grey50", 
                 "slave_daughters" = "grey30")

# Plot the Gini coefficients over time
opgaafginislave = ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long$year, na.rm = TRUE), max(gini_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_color_manual(values = line_colors, name = NULL, labels = labels) +
  labs(x = "Year",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border


# Display the plot
opgaafginislave

# Save the plot as a jpg file
ggsave("opgaafginislave.jpg", plot = opgaafginislave, width = 9, height = 6, dpi = 300)


### Add slaves as separate households

# Ensure opgaaf3 is a data.table
opgaaf <- as.data.table(opgaaf)

# Define the columns to set to zero for new observations, including year and decade
columns_to_keep <- c("year", "decade", "settler_men", "settlers", "slave_men", "slaves", 
                     "horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Replace NAs with zeros for the specified columns
opgaaf <- opgaaf %>%
  mutate(across(all_of(columns_to_keep), ~ ifelse(is.na(.), 0, .)))

# Calculate total slaves per year
total_slaves_per_year <- opgaaf %>%
  filter(slave_men > 0) %>%
  group_by(year, decade) %>%
  summarise(total_slaves = sum(slave_men, na.rm = TRUE))

# Create additional rows with zero assets for each year
additional_rows <- total_slaves_per_year %>%
  pmap_dfr(function(year, decade, total_slaves) {
    data.frame(year = rep(year, total_slaves),
               decade = rep(decade, total_slaves),
               settler_men = 0,
               settlers = 0,
               slave_men = 0,
               slaves = 0,
               horses = 0,
               cattle = 0,
               sheep = 0,
               wheat_vol = 0,
               vines = 0,
               wine = 0,
               stringsAsFactors = FALSE)
  })

# Combine the original data with the new rows
opgaaf_with_zeros <- bind_rows(opgaaf, additional_rows)


# Ensure opgaaf_with_zeros is a data.table
opgaaf_with_zeros <- as.data.table(opgaaf_with_zeros)

# Define the variables to be used
variables_to_plot <- c("horses", "cattle", "sheep", "wheat_vol", "vines", "wine")

# Filter the data until the year 1828 and remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_with_zeros %>%
  filter(year <= 1828) %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot)))) != length(variables_to_plot))

# Calculate the Gini coefficient for each variable by year
gini_values <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), ~ Gini(.x, na.rm = TRUE)))

# Calculate the number of observations per year
obs_per_year <- opgaaf_filtered %>%
  group_by(year) %>%
  summarize(count = n())

# Transform Gini data to long format for ggplot
gini_long <- gini_values %>%
  pivot_longer(cols = -year, names_to = "variable", values_to = "gini")

# Create custom labels for the variables
labels <- c("horses" = "Horses", "cattle" = "Cattle", "sheep" = "Sheep", 
            "wheat_vol" = "Wheat", "vines" = "Vines", "wine" = "Wine")

# Create a custom scale for line types and colors
line_types <- c("horses" = "dotted", "cattle" = "dotdash", "sheep" = "longdash", 
                "wheat_vol" = "twodash", "vines" = "dotted", "wine" = "solid")

line_colors <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                 "wheat_vol" = "grey70", "vines" = "grey30", "wine" = "black")

# Plot the Gini coefficients over time
opgaafgini_withslaves <- ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, color = variable), size = 0.8) +
  scale_x_continuous(breaks = seq(min(gini_long$year, na.rm = TRUE), max(gini_long$year, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_color_manual(values = line_colors, name = NULL, labels = labels) +
  labs(x = "Year",
       y = "Gini coefficient") +
  guides(linetype = guide_legend(nrow = 1), color = guide_legend(nrow = 1)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom",
        legend.box = "horizontal",
        panel.border = element_blank())  # Remove the black border

# Display the plot
print(opgaafgini_withslaves)

# Save the plot as a jpg file
ggsave("opgaafgini_withslaves.jpg", plot = opgaafgini_withslaves, width = 9, height = 6, dpi = 300)

### Slaves as extra settler households - bundles

# Calculate total slaves per year
total_slaves_per_year <- opgaaf %>%
  filter(slave_men > 0) %>%
  group_by(year, decade) %>%
  summarise(total_slaves = sum(slave_men, na.rm = TRUE))

# Create additional rows with zero assets for each year
additional_rows <- total_slaves_per_year %>%
  pmap_dfr(function(year, decade, total_slaves) {
    data.frame(year = rep(year, total_slaves),
               decade = rep(decade, total_slaves),
               settler_men = 1,
               settlers = 0,
               slave_men = 0,
               slaves = 0,
               horses = 0,
               cattle = 0,
               sheep = 12,
               wheat_vol = 0,
               vines = 0,
               wine = 0,
               stringsAsFactors = FALSE)
  })

# Combine the original data with the new rows
opgaaf_with_zeros <- bind_rows(opgaaf, additional_rows)


# Ensure opgaaf3_with_zeros is a data.table
opgaaf_with_zeros <- as.data.table(opgaaf_with_zeros)


# Create a 'period' column in opgaaf3 to match the decades in the prices data
opgaaf_with_zeros <- opgaaf_with_zeros %>%
  mutate(period = case_when(
    year >= 1700 & year < 1710 ~ 1700,
    year >= 1710 & year < 1720 ~ 1710,
    year >= 1720 & year < 1730 ~ 1720,
    year >= 1730 & year < 1740 ~ 1730,
    year >= 1740 & year < 1750 ~ 1740,
    year >= 1750 & year < 1760 ~ 1750,
    year >= 1760 & year < 1770 ~ 1760,
    year >= 1770 & year < 1780 ~ 1770,
    year >= 1780 & year < 1790 ~ 1780,
    year >= 1790 & year < 1800 ~ 1790,
    year >= 1800 & year < 1810 ~ 1800,
    year >= 1810 & year < 1820 ~ 1810,
    year >= 1820 & year < 1830 ~ 1820,
    year >= 1830 & year < 1840 ~ 1830
  ))

# Filter data to only include records from 1700 onwards
opgaaf_filtered <- opgaaf_with_zeros %>%
  filter(year >= 1700)

# Now perform the left join on the 'period' column
opgaaf_filtered <- opgaaf_with_zeros %>%
  left_join(prices, by = "period")

# Calculate the bundle value for each good (multiply quantity by price)
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(cattle_value = cattle * cattle_breeding,
         sheep_value = sheep.x * sheep.y,
         horses_value = horses.x * horses.y,
         wheat_value = wheat_vol.x * wheat_vol.y,
         wine_value = wine.x * wine.y)

# Define the new variables to be used (the total value of the goods)
variables_to_plot_bundle <- c("cattle_value", "sheep_value", "horses_value", "wheat_value", "wine_value")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_filtered %>%
  filter(rowSums(is.na(select(., all_of(variables_to_plot_bundle)))) != length(variables_to_plot_bundle))

# Calculate the total value of all goods combined for each period
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

# Calculate the total production value for each household (row) by summing the values of the five goods
opgaaf_filtered <- opgaaf_filtered %>%
  mutate(total_value = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Remove rows with missing total value
opgaaf_filtered <- opgaaf_filtered %>%
  filter(!is.na(total_value))

### Calculate Gini for Settlers Only

# Filter for settlers (exclude slaves)
settler_only <- opgaaf_filtered %>%
  filter(settler_men > 0) %>%
  mutate(total_value_settlers = cattle_value + sheep_value + horses_value + wheat_value + wine_value)

# Calculate Gini for settlers only
gini_settlers <- settler_only %>%
  group_by(period) %>%
  summarize(gini_settler_value = Gini(total_value_settlers, na.rm = TRUE))

### Calculate Gini for Settlers and Slaves Combined (As Done Previously)

# Calculate Gini for settlers + slaves combined (already in your code)
gini_total_production <- opgaaf_filtered %>%
  group_by(period) %>%
  summarize(gini_total_value = Gini(total_value, na.rm = TRUE))

### Combine Both Gini Dataframes for Plotting

# Merge the two Gini data frames into one for comparison
gini_combined <- gini_settlers %>%
  left_join(gini_total_production, by = "period")

### Plot Both Gini Coefficients on the Same Graph

opgaafgini_combined <- ggplot(gini_combined, aes(x = period)) +
  geom_line(aes(y = gini_settler_value, color = "Settlers and slaves"), size = 0.8) +
  geom_line(aes(y = gini_total_value, color = "Settlers"), size = 0.8) +
  scale_x_continuous(breaks = seq(1700, max(gini_combined$period, na.rm = TRUE), by = 10)) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 1)) +
  labs(x = "Period",
       y = "Gini coefficient") +
  scale_color_manual(values = c("Settlers" = "grey60", "Settlers and slaves" = "black")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.border = element_blank(),
        legend.position = "bottom",           # Move legend to the bottom
        legend.title = element_blank(),
        legend.box = "horizontal")            # Combine legend into one box

opgaafgini_combined
ggsave("opgaafgini_settlersslaves_basket.jpg", width = 9, height = 6, dpi = 300)

columns_to_convert <- c(
  "nr", "year", "add_info", "settler_men", "settler_women", "settler_sons", "settler_daughters", "settler_children",
  "servants", "servant_coachman", "servant_personal", "servant_home", "servant_cook",
  "slave_men", "slave_women", "slave_sons", "slave_daughters", "slave_children",
  "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters", "freeblack_men", "freeblack_women",
  "freeblack_sons", "freeblack_daughters", "prizenegro_men", "prizenegro_women", "prizenegro_sons",
  "prizenegro_daughters", "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
  "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", "horse_breeding",
  "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether",
  "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed",
  "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", "potatoes_vol",
  "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", "barleyzk_vol",
  "bzkoorn", "bzkoorn1", "vines", "wine", "brandy", "swords", "side_arm", "pistols", "rifle",
  "wagons", "carts", "wagons_pleasure", "carts_pleasure", "farm_name", "years_owned", "years_cultivated",
  "years_occupied", "freehold_places", "freehold_erfs", "freehold_morgen", "freehold_srods",
  "freehold_sfeet", "quitrent_places", "quitrent_morgen", "quitrent_srods", "quitrent_sfeet",
  "loan_places", "area_cultivated", "area_grazing", "area_uncultivated", "cap_tax_pounds",
  "cap_tax_shillings", "cap_tax_dimes", "servant_tax_pounds", "servant_tax_shillings",
  "servant_tax_dimes", "horse_tax_pounds", "horse_tax_shillings", "horse_tax_dimes",
  "stock_tax_pounds", "stock_tax_shillings", "stock_tax_dimes", "produce_tax_pounds",
  "produce_tax_shillings", "produce_tax_dimes", "wagon_tax_pounds", "wagon_tax_shillings",
  "wagon_tax_dimes", "nonfarm_tax_pounds", "nonfarm_tax_shillings", "nonfarm_tax_dimes",
  "income_tax_pounds", "income_tax_shillings", "income_tax_dimes", "total_tax_pounds",
  "total_tax_shillings", "total_tax_dimes", "nonfarm_income", "persons_born", "persons_married",
  "persons_died", "settlers_born", "settler_died", "slaves_born", "slaves_died", "khoe_born",
  "khoi_died", "freeblacks_born", "freeblacks_died", "prizenegro_born", "prizenegro_died",
  "workers_farm", "workers_retail", "workers_factory", "mills_water", "mills_horse", "tanneries"
)

