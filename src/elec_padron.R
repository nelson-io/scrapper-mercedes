library(tidyverse)
library(sf)
library(readxl)
library(rio)

#read padron data

circuitos <- read_xlsx('padron/circuitos.xlsx')
padron <- read_xlsx('padron/padron_geo.xlsx')
circuitos_shp <- read_sf('padron/circuitos-electorales.shp')




#read prop elecciones

pct_jyc <- import_list('advances/votaciones_pct_2.xlsx')
paso_2021 <- read_csv('out/other/paso_21_processed.csv')

names(pct_jyc$elec_grales_10_2019_data_csv)[4:7] <- paste(names(pct_jyc$elec_grales_10_2019_data_csv)[4:7], '2019', sep = '_')
names(pct_jyc$elec_grales_11_2021_data_csv)[4:6] <- paste(names(pct_jyc$elec_grales_11_2021_data_csv)[4:6], '2021', sep = '_')


props <- pct_jyc$elec_grales_11_2021_data_csv %>% 
  select(-eleciones) %>% 
  inner_join(pct_jyc$elec_grales_10_2019_data_csv %>% select(-eleciones)) %>% 
  left_join(paso_2021, by = c('mesa','circuito')) %>% 
  mutate_at(vars(mesa, circuito), as.character)

padron_en <- padron %>% 
  left_join(props %>% 
              mutate(CIRC_NUMERO = as.numeric(circuito),
                     NRO_MESA = as.numeric(mesa)),by = c('CIRC_NUMERO', 'NRO_MESA' ))

write_csv(padron_en,'advances/padron_enriquecido.csv')
