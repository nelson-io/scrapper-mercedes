library(tidyverse)

path <- 'out/other/paso_out_21.csv'

paso_2021 <- read_csv(path) %>% 
  filter(seccion == 'Mercedes',
         distrito == 'Buenos Aires',
         color == 'Amarillo')

paso_2021 <- paso_2021 %>% 
  transmute(circuito = as.numeric(id_circuito),
            mesa = as.numeric(str_extract(mesa,regex('\\d+'))),
            diputados_y_senadores_paso_2021 = prop_votos)

write_csv(paso_2021, 'out/other/paso_21_processed.csv')
