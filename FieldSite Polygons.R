FieldSite_poly_JSON <- fromJSON('http://128.196.38.73:9200/neon_sites/_search?pretty')
FieldSite_poly <- cbind(FieldSite_Poly$hits$hits$`_source`)
