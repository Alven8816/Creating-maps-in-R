# Aim: create regional map of election results

# Packages we'll use
pkgs = c("rvest", "geojsonio", "tmap", "dplyr",
         "stringdist")
lapply(pkgs, library, character.only = T)

# 1: Get local authority data
url = "https://github.com/npct/pct-bigdata/raw/master/las-dbands.geojson"
download.file(url, "las.geojson")
las = geojson_read("las.geojson", what = "sp")

# 2: Get and test results data
url = "http://www.bbc.co.uk/news/politics/eu_referendum/results/local/a"
bbc = read_html(url)

la_name = bbc %>%
  html_nodes(".eu-ref-result-bar__title") %>% 
  html_text()
vote_leave = bbc %>%
  html_nodes(".eu-ref-result-bar__party-votes--percentage") %>% 
  html_text() %>% 
  gsub(pattern = " |%", replacement = "") %>% 
  as.numeric() %>% 
vote_leave = vote_leave[(1:length(la_name)) * 2 - 1]

ref_result = data_frame(geo_label = la_name, `% vote leave` = vote_leave)

summary(local_authority %in% las$geo_label) # looks good
las@data = left_join(las@data, ref_result)
summary(las$vote_leave)
qtm(las, "% vote leave")

# 3: Run for all data points
i = "b"
for(i in letters[-1]){
  url = "http://www.bbc.co.uk/news/politics/eu_referendum/results/local/"
  url = paste0(url, i)
  url_exists = RCurl::url.exists(url)
  if(!url_exists) next
  bbc = read_html(url)
  la_name = bbc %>%
    html_nodes(".eu-ref-result-bar__title") %>% 
    html_text()
  vote_leave = bbc %>%
    html_nodes(".eu-ref-result-bar__party-votes--percentage") %>% 
    html_text() %>% 
    gsub(pattern = " |%", replacement = "") %>% 
    as.numeric() 
    vote_leave = vote_leave[(1:length(la_name)) * 2 - 1]
  ref_res_tmp = data_frame(geo_label = la_name, `% vote leave` = vote_leave)
  ref_result = bind_rows(ref_result, ref_res_tmp)
}
ref_result_orig = ref_result
las = geojson_read("las.geojson", what = "sp")
las$geo_label = as.character(las$geo_label)

# Manual fixes
ref_result$geo_label[grep("Corn", ref_result$geo_label)] =
  las$geo_label[grep("Corn", las$geo_label)]
ref_result$geo_label[grep("Heref", ref_result$geo_label)] =
  las$geo_label[grep("Heref", las$geo_label)]
ref_result$geo_label[msel] = las$geo_label[ams]

# Auto fixes
msel = !ref_result$geo_label %in% las$geo_label
mismatches = ref_result$geo_label[msel]
ams = amatch(mismatches, las$geo_label, method = "osa", maxDist = 3)
pmatches = cbind(as.character(las$geo_label[ams]),
                 ref_result$geo_label[msel])


las$geo_label[grep("and", las$geo_label)]

las@data = left_join(las@data, ref_result)
 
summary(las$`% vote leave`)
las$`% vote leave` = las$`% vote leave` - 50
tm_shape(las) +
  tm_fill("% vote leave", palette = "RdBu",
    title = "% vote leave\n(swing)") +
  tm_borders(lwd = 0.1)

