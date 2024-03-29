## Load library
library(readxl) 
library(dplyr) 
library(tidyverse)
library(stringr)
library(sqldf)
library(tibble)
library(writexl)

## Data Preparation

condo_data <- read_excel("Condo_Light_green_line.xlsx", sheet = "Recovered_Sheet1")

condo_data2 <- condo_data %>%
  select(`listing-property-type`, `listing-property-type 2`, 
         `listing-floorarea`, price, `listing-features` ) %>%
  filter(grepl("ขายขาด", `listing-property-type 2`) 
         & grepl("คอนโด", `listing-property-type`)) %>%
  mutate(distance = str_extract(`listing-features`, "\\d{3}")) %>%
  mutate(station = str_extract(`listing-features`, "BTS\\s(\\S+)")) %>%
  mutate(size = str_extract(`listing-floorarea`, "[0-9]+")) %>%
  filter(!is.na(distance)) %>%
  select(-`listing-features`, -`listing-property-type`, 
         -`listing-property-type 2`, -`listing-floorarea`) %>%
  select(3,1,4,2)

condo_data2$price <- as.numeric(gsub(",", "", condo_data2$price))
condo_data2$size <- as.numeric(condo_data2$size)
condo_data2$distance <- as.numeric(condo_data2$distance)

## Remove condos with a weird price 
condo_data2 <- condo_data2 %>%
  arrange(condo_data2$price)

condo_data2 <- condo_data2[7:1889, ]

## Calculate upper bound to detect outlier
IQR = quantile(condo_data2$price, 0.75) - quantile(condo_data2$price, 0.25)
Upper_bound = quantile(condo_data2$price, 0.75) + (1.5*IQR)

## Remove condos with a price higher than 28,512,500
condo_data2 <- condo_data2 %>%
  filter( price< 28512500)

##Q1: Condos categorized by price and size
# build dataframe
condo_budget <- condo_data2 %>%
  select (station, price, size) %>%
  mutate(budget = case_when(
    price > 1000000 & price <= 2000000 ~ "1-2 M",
    price > 2000000 & price <= 3000000 ~ "2-3 M",
    price > 3000000 & price <= 4000000 ~ "3-4 M",
    price > 4000000 & price <= 5000000 ~ "4-5 M",
    price > 5000000 ~ "> 5 M")) %>%
  mutate(size_segment = case_when(
    size <= 30 ~ "1. less than 30 sq.m",
    size <= 40 ~ "2. between 30-40 sq.m",
    TRUE ~ "3. higher than 40 sq.m"))

# propotion of condos categorized by budget from 1707 data
df1 <-condo_budget %>%
  select(budget) %>%
  group_by(budget) %>%
  count(budget)

# propotion of condos categorized by size_segment from 1707 data
df2 <- condo_budget %>%
  select(size_segment) %>%
  group_by(size_segment) %>%
  count(size_segment)

df3 <- condo_budget %>%
  select(station) %>%
  count(station)

# size_segment for budget = 1-2 M
condo_budget %>%
  select(budget, size_segment, price) %>%
  filter(budget == "1-2 M") %>%
  group_by(size_segment) %>%
  count()

# size_segment for budget = 2-3 M
condo_budget %>%
  select(budget, size_segment, price) %>%
  filter(budget == "2-3 M") %>%
  group_by(size_segment) %>%
  count()
# size_segment for budget = 3-4 M
condo_budget %>%
  select(budget, size_segment, price) %>%
  filter(budget == "3-4 M") %>%
  group_by(size_segment) %>%
  count()
# size_segment for budget = 4-5 M
condo_budget %>%
  select(budget, size_segment, price) %>%
  filter(budget == "4-5 M") %>%
  group_by(size_segment) %>%
  count()
# size_segment for budget > 5 M
condo_budget %>%
  select(budget, size_segment, price) %>%
  filter(budget == "> 5 M") %>%
  group_by(size_segment) %>%
  count()

## Q2: What is the average price of condos per sq.m. near the light green sky train?
avg_condo_price <- sqldf("SELECT station,
                    price/size as avg_price_per_sqm
                    FROM condo_data2
                    GROUP BY station
                    ORDER BY price/size DESC")

# Top 5
ggplot(data = avg_condo_price[1:5, ],
       mapping = aes(x = reorder(station, avg_price_per_sqm),
                     y = avg_price_per_sqm)) +
  geom_col(fill = "#427ef5") +
  geom_label(aes(label = round(avg_price_per_sqm, 0))) +
  theme_minimal() +
  labs(
    title = "Top 5 average condo price per square meter on the Light Green Sky Train",
    subtitle = "These condos considered is within 1 km of BTS station",
    caption = "Source: ddproperty on 16 Dec 2023",
    x = "Light green line station",
    y= "Average price (thb.) per square meter")

# Bottom 5
ggplot(data = avg_condo_price[32:36, ],
       mapping = aes(x = reorder(station, avg_price_per_sqm),
                     y = avg_price_per_sqm)) +
  geom_col(fill = "#427ef5") +
  geom_label(aes(label = round(avg_price_per_sqm, 0))) +
  theme_minimal() +
  labs(
    title = "Bottom 5 average condo price per square meter on the Light Green Sky Train",
    subtitle = "These condos considered is within 1 km of BTS station",
    caption = "Source: ddproperty on 16 Dec 2023",
    x = "Light green line station",
    y= "Average price (thb.) per square meter")
