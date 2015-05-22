Typewright::Application.routes.draw do

   # AWL integration
   get '/awl' => 'awl#index'
   get 'awl/fullview/:id' => "awl#fullview"
   get 'awl/attachment' => "awl#attachment"
   get 'awl/attachment/src/:uid/:aid' => "awl#attachment_sources"
   get 'awl/attachment/perm/:uid/:aid' => "awl#attachment_permissions"

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
  get 'documents/:id/edited' => 'documents#edited'
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
end
