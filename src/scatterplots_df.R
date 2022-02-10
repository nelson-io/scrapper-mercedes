library(tidyverse)
library(rio)


particip <- import_list('advances/particip_votaciones.xlsx')
votos_pct <- import_list('advances/votaciones_pct.xlsx')


join_particip <- function(votos, participaciones){
  df <- votos %>% 
    left_join(participaciones,by = c('eleciones' = 'elecciones', 'circuito', 'mesa'))
  
  return(df)
    
}


scatters_df <- map2(votos_pct, particip, ~join_particip(.x, .y))


export(scatters_df, 'advances/scatters_df.xlsx')


