#usual suspects
.libPaths(c("./P30_STB24/repro_original/_scratch/Rlib", .libPaths()))  # ENV PATCH E1: local library for circlize, ggstream, pacman, tidygeocoder
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
library(tidygeocoder)
library(pacman)
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
library(ggstream)
library(circlize)
library(ggridges)
library(forcats)
require(foreign)
require(RColorBrewer)
require(readxl)
require(dummies)

rm(list = ls())

setwd(OUTDIR)  # ENV PATCH E2: was setwd("C:\Users\johanf\Dropbox\3 Cape Panel\Research\2024F_Inequality"); OUTDIR set in run_original.R

opgaaf <- read_excel(DATAFILE, sheet = "Sheet1", col_names = TRUE) # ENV PATCH E3: was "stellenbosch_clean.xlsx" relative to setwd


###########

# Define the file path and sheet name
file_path <- "stellenbosch_clea.xlsx"
sheet_name <- "Sheet1"

# Determine the number of columns
temp_df <- read_excel(file_path, sheet = sheet_name, n_max = 1)
num_columns <- ncol(temp_df)

# Create a vector of "text" types for each column
col_types <- rep("text", num_columns)

# Read the Excel file and specify all columns as text
opgaaf <- read_excel(file_path, sheet = sheet_name, col_types = col_types)

opgaaf_new <- data.table(opgaaf)

### Fix the issue of fractions

# Function to convert text fractions to decimals
convert_fraction_to_decimal <- function(x) {
  # Define a named vector of fractions and their decimal equivalents
  fractions <- c("½" = ".5", "¼" = ".25", "¾" = ".75", "⅛" = ".125", "⅜" = ".375", "⅝" = ".625", "⅞" = ".875")
  
  # Function to replace fractions within a string
  replace_fractions <- function(cell) {
    for (fraction in names(fractions)) {
      cell <- gsub(fraction, as.character(fractions[[fraction]]), cell)
    }
    return(cell)
  }
  
  # Function to handle mixed numbers and fractions
  handle_mixed_numbers <- function(cell) {
    # Replace fractions first
    cell <- replace_fractions(cell)
    
    # Check if the cell contains a mixed number
    if (grepl("^[0-9]+[.0-9]*$", cell)) {
      # If the cell is already a number, return it
      return(as.numeric(cell))
    } else {
      # Split the mixed number into integer and fraction parts
      parts <- unlist(strsplit(cell, "(?<=\\d)(?=\\D)", perl = TRUE))
      if (length(parts) == 2) {
        # If we have both integer and fraction parts, add them
        integer_part <- as.numeric(parts[1])
        fraction_part <- as.numeric(parts[2])
        return(integer_part + fraction_part)
      } else {
        # If we only have one part, return it as a number
        return(as.numeric(cell))
      }
    }
  }
  
  # Apply the conversion to each element
  x <- sapply(x, function(cell) {
    cell <- as.character(cell) # Ensure cell is treated as a string
    tryCatch({
      result <- handle_mixed_numbers(cell)
      if (!is.numeric(result) || is.na(result)) {
        return(NA)
      }
      return(result)
    }, error = function(e) {
      return(NA) # Return NA if evaluation fails
    })
  }, USE.NAMES = FALSE)
  
  return(x)
}

columns_to_convert <- c(
  "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows",
  "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", "horse_breeding",
  "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", "sheep_wether",
  "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", "barley_seed",
  "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", "potatoes_vol",
  "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", "barleyzk_vol",
  "bzkoorn", "bzkoorn1", "vines", "wine", "brandy"
)

# Apply the conversion function to the specified columns
opgaaf_new[, (columns_to_convert) := lapply(.SD, convert_fraction_to_decimal), .SDcols = columns_to_convert]

# Convert all specified columns to numeric
opgaaf_new[, (columns_to_convert) := lapply(.SD, as.numeric), .SDcols = columns_to_convert]
####Cleaning the fractions
###############

# Now clean opgaaf
opgaaf_new2 <- data.table(opgaaf)


### Write to Excel -- new 'standard' version

#write_xlsx(opgaaf_new2, "opgaaf_new2.xlsx")

#opgaaf_new2 <- read_excel("opgaaf_new2.xlsx")





### STELLENBOSCH OPGAAFROLLE PAPER


### BEGIN THE ANALYSIS!



# Descriptive table of observations


#######OLD######
# Extract the decade from the year (assuming there's a date column named 'year')
# If 'year' is not a column, replace 'year' with the appropriate column name
opgaaf_new2$decade <- floor(opgaaf_new2$year / 10) * 10

# Calculate the number of observations by decade for each variable
obs_by_decade <- opgaaf_new2 %>%
  gather(key = "variable", value = "value", -decade, -year, na.rm = TRUE) %>%
  filter(!is.na(value)) %>%
  group_by(variable, decade) %>%
  summarise(observations = n(), .groups = 'drop')

# Calculate total observations per variable
total_obs_per_variable <- obs_by_decade %>%
  group_by(variable) %>%
  summarise(total_observations = sum(observations), .groups = 'drop') %>%
  arrange(desc(total_observations))

# Select the top 15 variables with the most observations
top_15_variables <- head(total_obs_per_variable, 15)$variable

# Filter the original observations by decade data to include only the top 15 variables
filtered_obs_by_decade <- obs_by_decade %>%
  filter(variable %in% top_15_variables)

# Spread the data to create a table format
table_output <- filtered_obs_by_decade %>%
  spread(key = "decade", value = "observations", fill = 0)

# Print the table
print(table_output)

# Calculate the number of observations for each variable
obs_total <- opgaaf_new2 %>%
  gather(key = "variable", value = "value", -year, na.rm = TRUE) %>%
  filter(!is.na(value)) %>%
  group_by(variable) %>%
  summarise(observations = n(), .groups = 'drop')

# Select the top 15 variables with the most observations
top_15_variables <- obs_total %>%
  arrange(desc(observations)) %>%
  head(15)

# Print the table
print(top_15_variables)


# Calculate the number of unique years
num_unique_years <- opgaaf_new2 %>%
  summarise(unique_years = n_distinct(year))

# Print the number of unique years
print(num_unique_years)


########


### Heat map of original opgaaf

# Now clean opgaaf
opgaaf_new <- data.table(opgaaf)

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

# Define the columns to be converted, using the list of variables provided
columns_to_convert2 <- c(
  "nr", "year", "add_info", "district", "field_cornet", "names_men", "names_women", "names_persons", 
  "settler_men", "settler_women", "settler_sons", "settler_daughters", "settler_children", "servants", 
  "servant_coachman", "servant_personal", "servant_home", "servant_cook", "slave_men", "slave_women", 
  "slave_sons", "slave_daughters", "slave_children", "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters", 
  "freeblack_men", "freeblack_women", "freeblack_sons", "freeblack_daughters", "prizenegro_men", 
  "prizenegro_women", "prizenegro_sons", "prizenegro_daughters", "cattle_bull", "cattle_breeding", 
  "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves", "horses", "horse_foals", "horse_work", 
  "horse_riding", "horse_breeding", "horse_pleasure", "donkeys", "sheep", "sheep_breeding", "sheep_wool", 
  "sheep_wether", "goats", "sheep_goats", "pigs", "sheep_goats_pigs", "wheat_seed", "wheat_vol", 
  "barley_seed", "barley_vol", "rye_seed", "rye_vol", "oat_seed", "oat_vol", "hay_vol", "maize_vol", 
  "potatoes_vol", "peas_vol", "barleyryeoat_vol", "grains_vol", "zkoorn", "wheat_bz", "rye_bz", 
  "barleyzk_vol", "bzkoorn", "bzkoorn1", "vines", "wine", "brandy", "swords", "side_arm", "pistols", 
  "rifle", "wagons", "carts", "wagons_pleasure", "carts_pleasure", "farm_name", "years_owned", 
  "years_cultivated", "years_occupied", "freehold_places", "freehold_erfs", "freehold_morgen", 
  "freehold_srods", "freehold_sfeet", "quitrent_places", "quitrent_morgen", "quitrent_srods", 
  "quitrent_sfeet", "loan_places", "area_cultivated", "area_grazing", "area_uncultivated", 
  "cap_tax_pounds", "cap_tax_shillings", "cap_tax_dimes", "servant_tax_pounds", "servant_tax_shillings", 
  "servant_tax_dimes", "horse_tax_pounds", "horse_tax_shillings", "horse_tax_dimes", "stock_tax_pounds", 
  "stock_tax_shillings", "stock_tax_dimes", "produce_tax_pounds", "produce_tax_shillings", 
  "produce_tax_dimes", "wagon_tax_pounds", "wagon_tax_shillings", "wagon_tax_dimes", "nonfarm_tax_pounds", 
  "nonfarm_tax_shillings", "nonfarm_tax_dimes", "income_tax_pounds", "income_tax_shillings", 
  "income_tax_dimes", "total_tax_pounds", "total_tax_shillings", "total_tax_dimes", "nonfarm_income", 
  "nonfarm_income_pounds", "nonfarm_income_shillings", "nonfarm_income_dimes", "persons_born", 
  "persons_married", "persons_died", "settlers_born", "settlers_died", "slaves_born", "slaves_died", 
  "khoe_born", "khoe_died", "freeblacks_born", "freeblacks_died", "prizenegro_born", "prizenegro_died", 
  "workers_farm", "workers_retail", "workers_factory", "mills_water", "mills_horse", "tanneries", 
  "farm_owned", "farm_inherited", "farm_owned_loaned", "farm_loaned", "land_government", "land_eigendom", 
  "land_erfpagt", "land_loaned", "land_morgen", "land_farm", "land_erven", "prizenegro_born_sons", 
  "prizenegro_born_daughters", "quitrent_erfs", "apprentice_men", "apprentice_women", "apprentice_sons", 
  "apprentice_daughters"
)

# Apply the NA replacement function to the specified columns
opgaaf_new <- replace_na_with_zero(opgaaf_new, columns_to_convert2)

# Convert opgaaf_clean to data.table
opgaaf_clean <- as.data.table(opgaaf_new)

# Step 1: Count non-NA observations for each variable
variable_completeness <- colSums(!is.na(opgaaf_clean))

# Step 2: Rank variables based on completeness
ranked_variables <- sort(variable_completeness, decreasing = TRUE)

# Step 3: Keep variables except the 100 most incomplete
variables_to_keep <- names(ranked_variables)[1:(length(ranked_variables) - 100)]
opgaaf_clean <- opgaaf_clean[, ..variables_to_keep]

# Step 4: Melt the dataset to long format
data_long <- melt(opgaaf_clean, id.vars = "year", variable.name = "variable", value.name = "value")

# Convert `data_long` to a `data.table`
data_long <- as.data.table(data_long)

# Step 5: Summarize non-NA counts by variable and year
data_summary <- data_long[, .(count = sum(!is.na(value))), by = .(variable, year)]

# Step 6: Order variables by completeness
data_summary$variable <- factor(data_summary$variable, levels = names(ranked_variables))

# Step 7: Convert year to numeric for proper sorting
data_summary$year <- as.numeric(as.character(data_summary$year))

# Step 8: Create the heatmap
heatmap <- ggplot(data_summary, aes(x = year, y = variable, fill = count)) +
  geom_tile(color = "white") +  # Add white gridlines for distinction
  scale_fill_gradient(low = "grey90", high = "black", name = "Count") +
  scale_x_continuous(breaks = seq(min(data_summary$year, na.rm = TRUE), 
                                  max(data_summary$year, na.rm = TRUE), by = 10)) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 8),
    legend.position = "bottom",  # Move the legend to the bottom
    legend.key.width = unit(2, "cm"),  # Increase the width of the legend key
    legend.key.height = unit(0.5, "cm"),  # Adjust the height of the legend key
    legend.text = element_text(size = 10)  # Adjust legend text size
  ) +
  labs(
    x = "Year",
    y = "Variable"
  )

# Print the heatmap
print(heatmap)

ggsave("heatmap2.jpg", width = 9, height = 15, dpi = 600)

##########################

###CLEANING THE ORIGINALS

# Convert opgaaf_clean to data.table
opgaaf_new2 <- as.data.table(opgaaf_new)

# Convert specified columns to numeric
columns_to_convert <- c("horse_foals", "horse_work", "horse_breeding", "horse_pleasure", 
                        "cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", 
                        "cattle_heifers", "cattle_calves", "sheep_breeding", "sheep_wool", 
                        "sheep_wether", "sheep_goats", "servants", "servant_coachman", 
                        "servant_personal", "servant_home", "servant_cook", "slave_men", 
                        "slave_women", "slave_sons", "slave_daughters", "slave_children", 
                        "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters", 
                        "freeblack_men", "freeblack_women", "freeblack_sons", 
                        "freeblack_daughters", "prizenegro_men", "prizenegro_women", 
                        "prizenegro_sons", "prizenegro_daughters", "settler_men", 
                        "settler_women", "settler_sons", "settler_daughters", 
                        "settler_children", "year")

opgaaf_new2[, (columns_to_convert) := lapply(.SD, as.numeric), .SDcols = columns_to_convert]

### Horses

# Function to replace NAs in the horses column with the sum of other horse-related columns
replace_horses_na_with_sum <- function(dt) {
  horse_columns <- c("horse_foals", "horse_work", "horse_breeding", "horse_pleasure")
  
  # Calculate the sum of the other horse-related columns
  dt[, horse_sum := rowSums(.SD, na.rm = TRUE), .SDcols = horse_columns]
  
  # Replace NAs in the horses column with the calculated sum
  dt[is.na(horses), horses := horse_sum]
  
  # Drop the temporary column
  dt[, horse_sum := NULL]
  
  return(dt)
}

# Apply the function to the data table
opgaaf_new2 <- replace_horses_na_with_sum(opgaaf_new2)

### Cattle

# Function to create a new cattle column by summing all other cattle-related columns
create_cattle_sum <- function(dt) {
  cattle_columns <- c("cattle_bull", "cattle_breeding", "cattle_work", "cattle_cows", "cattle_heifers", "cattle_calves")
  
  # Calculate the sum of all cattle-related columns and create a new 'cattle' column
  dt$cattle <- rowSums(dt[, ..cattle_columns], na.rm = TRUE)
  
  return(dt)
}

# Apply the function to the data table
opgaaf_new2 <- create_cattle_sum(opgaaf_new2)

### Sheep

# Function to replace NAs in the sheep column with the sum of other sheep-related columns
replace_sheep_na_with_sum <- function(dt) {
  sheep_columns <- c("sheep_breeding", "sheep_wool", "sheep_wether", "sheep_goats")
  
  # Calculate the sum of the other sheep-related columns
  dt[, sheep_sum := rowSums(.SD, na.rm = TRUE), .SDcols = sheep_columns]
  
  # Replace NAs in the sheep column with the calculated sum
  dt[is.na(sheep), sheep := sheep_sum]
  
  # Drop the temporary column
  dt[, sheep_sum := NULL]
  
  return(dt)
}

# Apply the function to the data table
opgaaf_new2 <- replace_sheep_na_with_sum(opgaaf_new2)

### Labourers

# Define the columns for laborers
laborer_columns <- c("servants", "servant_coachman", "servant_personal", "servant_home", "servant_cook",
                     "slave_men", "slave_women", "slave_sons", "slave_daughters", "slave_children",
                     "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters",
                     "freeblack_men", "freeblack_women", "freeblack_sons", "freeblack_daughters",
                     "prizenegro_men", "prizenegro_women", "prizenegro_sons", "prizenegro_daughters")

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to opgaaf_new2
opgaaf_new2 <- as.data.frame(opgaaf_new2)
opgaaf_new2 <- clean_and_convert_columns_to_numeric(opgaaf_new2, laborer_columns)


# Function to create a new variable for the number of laborers
create_number_of_laborers <- function(df) {
  # Define the columns for laborers
  laborer_columns <- c("servants", "servant_coachman", "servant_personal", "servant_home", "servant_cook",
                       "slave_men", "slave_women", "slave_sons", "slave_daughters",
                       "khoe_men", "khoe_women", "khoe_sons", "khoe_daughters",
                       "freeblack_men", "freeblack_women", "freeblack_sons", "freeblack_daughters",
                       "prizenegro_men", "prizenegro_women", "prizenegro_sons", "prizenegro_daughters")
  
  # Calculate the total number of laborers on the farms
  df$number_of_laborers <- rowSums(df[, laborer_columns, drop = FALSE], na.rm = TRUE)
  
  return(df)
}

# Apply the function to the cleaned data table
opgaaf_new2 <- create_number_of_laborers(opgaaf_new2)

# Function to create a new variable for the number of laborers
create_number_of_slaves <- function(df) {
  # Define the columns for laborers
  slaves_columns <- c("slave_men", "slave_women", "slave_sons", "slave_daughters")
  
  # Calculate the total number of laborers on the farms
  df$number_of_slaves <- rowSums(df[, slaves_columns, drop = FALSE], na.rm = TRUE)
  
  return(df)
}

# Apply the function to the cleaned data table
opgaaf_new2 <- create_number_of_slaves(opgaaf_new2)

### Settlers

# Define the columns for settlers
settler_columns <- c("settler_men", "settler_women", "settler_sons", "settler_daughters", "settler_children")

# Function to clean and convert columns to numeric
clean_and_convert_columns_to_numeric <- function(df, columns) {
  for (col in columns) {
    df[[col]] <- as.numeric(gsub("[^0-9.]", "", as.character(df[[col]])))
  }
  return(df)
}

# Apply the cleaning function to opgaaf_new2 for settler columns
opgaaf_new2 <- clean_and_convert_columns_to_numeric(opgaaf_new2, settler_columns)

# Function to create a new variable for the settler household size
create_settler_household_size <- function(df) {
  # Define the columns for settlers
  settler_columns <- c("settler_men", "settler_women", "settler_sons", "settler_daughters", "settler_children")
  
  # Calculate the total settler household size
  df$settler_household_size <- rowSums(df[, settler_columns, drop = FALSE], na.rm = TRUE)
  
  return(df)
}

# Apply the function to the cleaned data table for settler columns
opgaaf_new2 <- create_settler_household_size(opgaaf_new2)

### Year

# Convert the 'year' column to numeric
opgaaf_new2$year <- as.numeric(gsub("[^0-9.]", "", as.character(opgaaf_new2$year)))


# Create decade variable
opgaaf_new2$decade <- (opgaaf_new2$year %/% 10) * 10


### FIGURE 5: Line graph of averages, indexed

# Define the variables to be indexed and plotted (replace with correct column names if necessary)
variables_to_plot <- c("horses", "cattle", "sheep", "wheat_vol", "barley_vol", "wine")

# Calculate mean values for each variable by year
mean_values <- opgaaf_new2 %>%
  group_by(year) %>%
  summarize(across(all_of(variables_to_plot), mean, na.rm = TRUE))

# Calculate the number of observations per year
obs_per_year <- opgaaf_new2 %>%
  group_by(year) %>%
  summarize(count = n())

# Normalize each variable to the base year (1795)
base_year <- 1780

# Create a function to normalize to the base year
normalize_to_base_year <- function(df, base_year, variables) {
  base_values <- df %>%
    filter(year == base_year) %>%
    select(all_of(variables)) %>%
    unlist()
  
  df %>%
    mutate(across(all_of(variables), ~ . / base_values[match(cur_column(), names(base_values))], .names = "index_{col}"))
}

# Apply the normalization function
indexed_values <- normalize_to_base_year(mean_values, base_year, variables_to_plot)

# Transform data to long format for ggplot
indexed_long <- indexed_values %>%
  pivot_longer(cols = starts_with("index_"), names_to = "variable", values_to = "value") %>%
  mutate(variable = gsub("index_", "", variable))

# Merge indexed values with observations data
indexed_long <- indexed_long %>%
  left_join(obs_per_year, by = "year")

# Create a custom scale for line types and colors
line_types <- c("horses" = "solid", "cattle" = "dotdash", "sheep" = "longdash", 
                "wheat_vol" = "twodash", "barley_vol" = "dotted", 
                "wine" = "solid")

line_colors <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                 "wheat_vol" = "grey70", "barley_vol" = "grey30", 
                 "wine" = "black")

# Create a custom scale for labels
labels <- c("horses" = "Horses", "cattle" = "Cattle", "sheep" = "Sheep", 
            "wheat_vol" = "Wheat", "barley_vol" = "Barley", "wine" = "Wine")

library(grid)

# Plot the indexed values with log scale and custom range
assets_plot <- ggplot(indexed_long, aes(x = year, y = value, group = variable)) +
  geom_line(aes(linetype = variable, colour = variable), size = 0.8) +
  scale_y_log10(
    limits = c(0.01, 100),
    breaks = c(0.01, 0.1, 1, 10, 100),
    labels = c("0.01", "0.1", "1", "10", "100")
  ) +
  scale_x_continuous(
    breaks = seq(min(indexed_long$year, na.rm = TRUE),
                 max(indexed_long$year, na.rm = TRUE),
                 by = 10)
  ) +
  scale_linetype_manual(values = line_types,
                        name   = NULL,
                        labels = labels) +
  scale_colour_manual(values = line_colors,
                      name   = NULL,
                      labels = labels) +
  # lengthen the legend keys (the little sample lines)
  guides(
    colour   = guide_legend(keywidth = unit(2, "cm")),
    linetype = guide_legend(keywidth = unit(2, "cm"))
  ) +
  labs(
    x     = "Year",
    y     = "Indexed value (Log scale, Base year = 1795)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x       = element_text(angle = 45, hjust = 1),
    legend.position   = "bottom",
    legend.key.width  = unit(1.5, "cm")    # also affects key length
  )

# Plot the number of observations per year
obs_plot <- ggplot(obs_per_year, aes(x = year, y = count)) +
  geom_line(size = 0.8) +
  labs(y = "Number of obs") +
  theme_minimal() +
  theme(
    axis.text.x    = element_text(angle = 45, hjust = 1),
    axis.title.x   = element_blank()
  )

# Combine the plots
assets_combined <- obs_plot / assets_plot +
  plot_layout(heights = c(1, 3))

# Print and save
print(assets_combined)
ggsave("assets_combined.jpg", width = 9, height = 6, dpi = 300)



# FIGURE 6: Line graph of Ginis

# Define the variables to be used
variables_to_plot <- c("horses", "cattle", "sheep", "wheat_vol", "barley_vol", "wine")

# Remove observations with no information in the specified variables
opgaaf_filtered <- opgaaf_new2 %>%
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
            "wheat_vol" = "Wheat", "barley_vol" = "Barley", "wine" = "Wine")

# Create a custom scale for line types and colors
line_types <- c("horses" = "solid", "cattle" = "dotdash", "sheep" = "longdash", 
                "wheat_vol" = "twodash", "barley_vol" = "dotted", "wine" = "solid")

line_colors <- c("horses" = "grey60", "cattle" = "black", "sheep" = "grey50", 
                 "wheat_vol" = "grey70", "barley_vol" = "grey30", "wine" = "black")

# Plot the Gini coefficients over time
gini_plot <- ggplot(gini_long, aes(x = year, y = gini, group = variable)) +
  geom_line(aes(linetype = variable, colour = variable), size = 0.8) +
  scale_x_continuous(
    breaks = seq(
      min(gini_long$year, na.rm = TRUE),
      max(gini_long$year, na.rm = TRUE),
      by = 10
    )
  ) +
  scale_linetype_manual(values = line_types, name = NULL, labels = labels) +
  scale_colour_manual(values = line_colors, name = NULL, labels = labels) +
  guides(
    colour   = guide_legend(keywidth = unit(2, "cm")),  # lengthen the line samples
    linetype = guide_legend(keywidth = unit(2, "cm"))
  ) +
  labs(
    x = "Year",
    y = "Gini coefficient"
  ) +
  theme_minimal() +
  theme(
    axis.text.x      = element_text(angle = 45, hjust = 1),
    legend.position  = "bottom",
    legend.key.width = unit(1.5, "cm"),                  # global fallback for key length
    panel.border     = element_blank()                   # Remove the black border
  )

# Print and save
print(gini_plot)
ggsave("gini.jpg", width = 9, height = 6, dpi = 300)


### FIGURE 3: Names plot

# Clean the data: Set rows with any question marks in the names_men column to NA
opgaaf_new2_cleaned <- opgaaf_new2 %>%
  mutate(names_men = if_else(str_detect(names_men, "\\?"), NA_character_, names_men))

# Create the surname column
opgaaf_new2_cleaned <- opgaaf_new2_cleaned %>%
  mutate(
    surname = case_when(
      # Case for "Surname, First Name"
      str_detect(names_men, ",") ~ str_trim(str_extract(names_men, "^[^,]+")),
      # Case for "First Name Last Name"
      !is.na(names_men) ~ str_trim(word(names_men, -1)),
      # Set surname to NA if names_men is NA
      TRUE ~ NA_character_
    )
  )

# Remove rows with NA or '0' in the surname column and filter data between 1700 and 1830
opgaaf_new2_cleaned <- opgaaf_new2_cleaned %>%
  filter(!is.na(surname) & surname != "0" & year >= 1700 & year <= 1830)

# Identify the top twelve surnames over the period, excluding '0'
top_surnames <- opgaaf_new2_cleaned %>%
  count(surname) %>%
  top_n(12, n) %>%
  pull(surname)

# Group data by decade
opgaaf_new2_cleaned <- opgaaf_new2_cleaned %>%
  mutate(decade = floor(year / 10) * 10)

# Summarize data to get counts of top surnames by decade
surname_counts_by_decade <- opgaaf_new2_cleaned %>%
  count(decade, surname) %>%
  spread(key = surname, value = n, fill = 0)

# Filter for the top 12 surnames
top_surname_data <- surname_counts_by_decade %>%
  select(decade, all_of(top_surnames))

# Calculate the total surnames for each decade
top_surname_data$total <- rowSums(top_surname_data[ , -1])

# Calculate the percentage for each surname
top_surname_data <- top_surname_data %>%
  mutate(across(-decade, ~ (. / total) * 100))

# Melt the data for ggplot, excluding the 'total' column
melted_data <- melt(top_surname_data %>% select(-total), id.vars = "decade", variable.name = "surname", value.name = "percentage")

# compute your decade breaks
decade_breaks <- seq(
  min(melted_data$decade, na.rm = TRUE),
  max(melted_data$decade, na.rm = TRUE),
  by = 10
)

# Create the line graph with direct labels using ggrepel
# compute your decade breaks
decade_breaks <- seq(
  min(melted_data$decade, na.rm = TRUE),
  max(melted_data$decade, na.rm = TRUE),
  by = 10
)

# find, for each surname, the row at which percentage is highest
label_positions <- melted_data %>%
  group_by(surname) %>%
  slice_max(percentage, n = 1) %>%
  ungroup()

linegraph_plot <- ggplot(melted_data, aes(x = decade, y = percentage,
                                          group = surname,
                                          colour = surname,
                                          linetype = surname)) +
  geom_vline(xintercept = decade_breaks,
             colour    = "grey80",
             linetype  = "dashed",
             size      = 0.3) +
  geom_line(size = 0.8) +
  geom_point(size = 2) +
  scale_color_grey(start = 0.2, end = 0.8) +
  scale_linetype_manual(
    values = rep(c("solid", "dashed", "dotted", "dotdash"),
                 length.out = length(unique(melted_data$surname)))
  ) +
  geom_text_repel(
    data           = label_positions,
    aes(x = decade, y = percentage, label = surname),
    colour         = "black",    # all labels in black
    nudge_x        = 2,
    direction      = "y",
    hjust          = 0,
    segment.colour = "grey70",
    size           = 3
  ) +
  scale_x_continuous(breaks = decade_breaks, minor_breaks = NULL) +
  labs(x = "Decade", y = "Percentage of all surnames") +
  theme_minimal(base_size = 12) +
  theme(
    legend.position    = "none",
    panel.grid.major   = element_line(colour = "grey90"),
    panel.grid.minor.x = element_blank(),
    axis.text.x        = element_text(angle = 45, hjust = 1)
  )

# print to screen
print(linegraph_plot)

# save to file
ggsave(
  filename = "linegraph_plot.jpg",
  plot     = linegraph_plot,
  width    = 9,
  height   = 6,
  dpi      = 300
)


####FIGURE 4


# Remove rows where surnames are "0" and clean the data: Set rows with any question marks in the names_men and names_women columns to NA
opgaaf_new2_cleaned <- opgaaf_new2 %>%
  mutate(
    names_men = if_else(str_detect(names_men, "\\?"), NA_character_, names_men),
    names_women = if_else(str_detect(names_women, "\\?"), NA_character_, names_women)
  ) %>%
  mutate(
    surname_men = case_when(
      # Case for "Surname, First Name"
      str_detect(names_men, ",") ~ str_trim(str_extract(names_men, "^[^,]+")),
      # Case for "First Name Last Name"
      !is.na(names_men) ~ str_trim(word(names_men, -1)),
      # Set surname to NA if names_men is NA
      TRUE ~ NA_character_
    ),
    surname_women = case_when(
      # Case for "Surname, First Name"
      str_detect(names_women, ",") ~ str_trim(str_extract(names_women, "^[^,]+")),
      # Case for "First Name Last Name"
      !is.na(names_women) ~ str_trim(word(names_women, -1)),
      # Set surname to NA if names_women is NA
      TRUE ~ NA_character_
    )
  ) %>%
  filter(
    !is.na(surname_men) & !is.na(surname_women),  # Exclude rows with NA surnames
    surname_men != "0",  # Exclude rows where `surname_men` is "0"
    surname_women != "0",  # Exclude rows where `surname_women` is "0"
    year >= 1700 & year <= 1830  # Keep rows within the time range
  )

# Count the frequency of each surname connection
surname_connections <- opgaaf_new2_cleaned %>%
  count(surname_men, surname_women) %>%
  arrange(desc(n)) %>%
  head(100)  # Select the top 100 connections

### Plotting Chord Diagram

# Prepare data for the chord diagram
chord_data <- surname_connections[, c("surname_men", "surname_women", "n")]

# Define a set of grey colors for the links with more variations
link_colors <- colorRampPalette(c("grey10", "grey30", "grey50", "grey70", "grey90"))(100)

# Define a color function for the sectors
sector_colors <- rep("grey20", length(unique(c(chord_data$surname_men, chord_data$surname_women))))

# Open a PNG device
png("chord_diagram_cleaned.png", width = 8, height = 8, units = "in", res = 300)

# Plot the chord diagram with customized colors
chordDiagram(
  x = chord_data,
  transparency = 0.5,
  annotationTrack = "grid",
  preAllocateTracks = list(track.height = 0.1),
  col = link_colors,
  grid.col = sector_colors
)

# Add labels and title with smaller font sizes
circos.trackPlotRegion(track.index = 1, panel.fun = function(x, y) {
  circos.text(CELL_META$xcenter, CELL_META$ylim[1], CELL_META$sector.index, facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5), cex = 0.6, col = "black")
}, bg.border = NA)

# Close the PNG device
dev.off()




#### SLAVERY

# Fix the issue with slave_sons and slave_children
opgaaf_new2 <- opgaaf_new2 %>%
  mutate(
    slave_sons = ifelse(year <= 1737, slave_children, slave_sons),  # Assign slave_children to slave_sons for years <= 1737
    slave_children = ifelse(year <= 1737, NA, slave_children)      # Set slave_children to NA for years <= 1737
  )

# Filter data to include only records before 1830 and with non-zero total slaves
opgaaf_new3 <- opgaaf_new2 %>%
  filter(year < 1830) %>%
  filter(slave_men > 0 | slave_women > 0 | slave_sons > 0 | slave_daughters > 0)

# Group data by two-decade intervals
opgaaf_new3 <- opgaaf_new3 %>%
  mutate(decade = floor(year / 20) * 20)

# Melt the dataframe to long format for ggplot2
opgaaf_new2_long <- melt(opgaaf_new3, id.vars = "decade", measure.vars = c("slave_men", "slave_women", "slave_sons", "slave_daughters"), variable.name = "category", value.name = "count")

# Rename the categories
opgaaf_new2_long$category <- recode(opgaaf_new2_long$category,
                                    "slave_men" = "Slave men",
                                    "slave_women" = "Slave women",
                                    "slave_sons" = "Slave sons",
                                    "slave_daughters" = "Slave daughters")

# Create a ridgeline plot with log scale for the number of slaves and non-log x-axis labels
slaves_plot <- ggplot(opgaaf_new2_long, aes(x = log1p(count), y = as.factor(decade), fill = category)) +  # log1p to handle log(0)
  geom_density_ridges(alpha = 0.8, scale = 1, color = "black", fill = "grey") +
  facet_wrap(~ category, scales = "free_x") +
  scale_x_continuous(
    breaks = log1p(c(0, 1, 3, 10, 30)),  # Add breaks at 0, 1, 3, 10, 30
    labels = c(0, 1, 3, 10, 30),  # Labels for the breaks
    limits = c(0, log1p(30))
  ) +  # Transform labels back to original scale and set limits
  labs(x = "Number of enslaved people",
       y = "Decades") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 8),
        legend.position = "none")  # Remove legend as categories are faceted

slaves_plot
ggsave("slaves_plot.jpg", width = 9, height = 6, dpi = 300)


###Word cloud of Additional Info

# Extract the column of interest
text_data <- opgaaf_new2$add_info

# Create a corpus
corpus <- Corpus(VectorSource(text_data))

# Clean the text data
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, removeNumbers)
corpus <- tm_map(corpus, removeWords, stopwords("english"))

# Create a term-document matrix
tdm <- TermDocumentMatrix(corpus)
tdm_matrix <- as.matrix(tdm)
word_freqs <- sort(rowSums(tdm_matrix), decreasing = TRUE)
word_freqs_df <- data.frame(word = names(word_freqs), freq = word_freqs)

# Filter to include only the top 100 most frequent words
top_100 <- head(word_freqs_df, 100)

# Open a graphical device to save the plot as a JPEG file
jpeg("word_plot.jpg", width = 6, height = 6, units = "in", res = 300)

# Adjust margins to zero to ensure the word cloud fills the entire space
par(mar = c(0, 0, 0, 0))

# Generate the word cloud in black and white with a minimalist style
set.seed(1234) # for reproducibility
wordcloud(words = top_100$word, freq = top_100$freq, min.freq = 1, 
          max.words = 100, random.order = FALSE, rot.per = 0.35, 
          scale = c(4, 0.5), # Adjust scale for better fitting
          colors = "black", use.r.layout = FALSE)
dev.off()




















###ADDENDUM

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



