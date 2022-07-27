ArchivesSpacePublic::Application.routes.draw do
  match "repositories/:rid/resources/:id/digct" => "resources_addons#digital_object_count", :via => [:get]
  match "repositories/:rid/resources/:id/digital_only" => "resources#digital_only", :via => [:get, :post]
  match "id/object/*refid" => "resources_addons#refid", :via => [:get, :post]
  match "id/digital/*digid" => "resources_addons#digid", :via => [:get, :post]
  match "special" => "agents_test#special", :via => [:get, :post]
end
