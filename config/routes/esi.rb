ActionController::Routing::Routes.draw do |map|
  # ENTRY SEARCH
  map.entries_search_header 'articles/search/header', :controller => 'entries/search', :action => 'header'
  map.entries_search_results 'articles/search/results', :controller => 'entries/search', :action => 'results'
  map.entries_search_facets 'articles/search/facets/:facet', :controller => 'entries/search', :action => 'facets'
end