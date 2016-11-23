ArchivesSpace::Application.routes.draw do

  match('/plugins/resource_mods' => 'resource_mods#index', :via => [:get])
  match('/plugins/resource_mods/mods' => 'resource_mods#mods', :via => [:post])
  match('/plugins/ao_mods/:id/download' => 'ao_mods#download', :via => [:get])

end
