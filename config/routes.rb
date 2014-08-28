Typewright::Application.routes.draw do
  resources :page_reports

	resources :lines do
		collection do
			get 'ping'
		end
	end
	resources :users do
		member do
			get 'corrections'
		end
	end
	resources :document_users
  get 'documents/exists' => 'documents#exists', :as => :exists
  post 'documents/upload' => 'documents#upload', :as => :upload
  post 'documents/update_page_ocr' => 'documents#update_page_ocr', :as => :update_page_ocr
  get 'documents/export_corrected_text' => 'documents#export_corrected_text', :as => :export_corrected_text
  get 'documents/export_corrected_gale_xml' => 'documents#export_corrected_gale_xml', :as => :export_corrected_gale_xml
  get 'documents/export_original_gale_xml' => 'documents#export_original_gale_xml', :as => :export_original_gale_xml
  get 'documents/export_original_gale_text' => 'documents#export_original_gale_text', :as => :export_original_gale_text
  get 'documents/export_corrected_tei_a' => 'documents#export_corrected_tei_a', :as => :export_corrected_tei_a
  resources :documents do
	  collection do
		  get 'corrections'
		  get 'retrieve'
		  get 'unload'
	  end
  end
  get 'documents/:id/report' => 'documents#report', :as => :report
  post 'documents/:id/upload' => 'documents#upload', :as => :upload
  post 'documents/:id/update_page_ocr' => 'documents#update_page_ocr', :as => :update_page_ocr
  put 'documents/:id/delete_corrections' => 'documents#delete_corrections', :as => :delete_corrections

  get "/test_exception_notifier" => "users#test_exception_notifier"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
