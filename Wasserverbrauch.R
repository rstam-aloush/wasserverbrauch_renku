library(tidyverse)
library(openxlsx)

times1000 <- function(x, na.rm = FALSE) x * 1000
divide1000 <- function(x, na.rm = FALSE) x / 1000

Jahr_monatlich = 2025 # Jahr des letzten monatlichen Wertes
Jahr_jaerlich_W = 2023 # Jahr des letzten jährlichen Wertes

#### Wasserverbrauch

URL <- "https://statistik.bs.ch/files/webtabellen/t02-4-02.xlsx"

download.file(URL, destfile = "Tabelle.xlsx", mode = "wb")


read.xlsx("Tabelle.xlsx", 
          sheet = "Jahr",
          rows = 8:eval(Jahr_jaerlich_W - 1940)) %>%
  select(Jahr = 1,
         `Haushaltungen, Gewerbe` = 2,
         `Grossbezüger` = 3,
         `Öffentliche Brunnen` = 4,
         `Andere öffentliche Zwecke` = 5,
         `Eigenbedarf IWB` = 6,
         Verlust,
         Total,
         Mittlerer,
         `Grösster` = 10
         ) %>% 
  mutate_at(2:8, times1000) %>%
  mutate_at(9:10, divide1000) %>%
  pivot_longer(cols = -Jahr,
               names_to = "Kategorie",
               values_to = "Menge") %>%
  mutate(
    Aggregationsstufe = "Jahr",
    Einheitbeschreibung = case_when(
      Kategorie %in% c("Mittlerer", "Grösster") ~ "Tagesverbrauch pro Kopf in Kubikmeter",
      TRUE ~ "Wasserverbrauch in Kubikmeter"
    ),
    Zeitperiode = paste0(Jahr)
  ) %>%
  select(Aggregationsstufe, Zeitperiode, Kategorie, Einheitbeschreibung, Menge) %>%
  bind_rows(
    read.xlsx("Tabelle.xlsx", 
              sheet = "Monat",
              rows = 7:eval(Jahr_monatlich - 1996)) %>%
      pivot_longer(cols = -Jahr,
                   names_to = "Aggregationsstufe",
                   values_to = "Menge") %>%
      mutate_at(3, times1000,
               ) %>%
      mutate(Einheitbeschreibung = "Wasserverbrauch in Kubikmeter",
             Kategorie = "Monatlicher Wasserverbrauch",
             Monat = recode(Aggregationsstufe,
                            Jan = "01",
                            Feb = "02",
                            Mrz = "03",
                            Apr = "04",
                            Mai = "05",
                            Jun = "06",
                            Jul = "07",
                            Aug = "08",
                            Sep = "09",
                            Okt = "10",
                            Nov = "11",
                            Dez = "12"),
             Zeitperiode = paste0(Jahr, "-", Monat),
             Aggregationsstufe = "Monat") %>%
      select(Aggregationsstufe, Zeitperiode, Kategorie, Einheitbeschreibung, Menge)
  ) %>%
  arrange(Zeitperiode) %>% 
  write.xlsx("100420_wasserverbrauch.xlsx")

file.remove("Tabelle.xlsx")
