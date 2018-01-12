Rails.application.routes.draw do
  get 'test/index'

  get 'picker_data/generate'

  get 'summary/index'

  get 'temporary_register/index'
  get 'temporary_register/register_name' => 'temporary_register#register_name'
  get 'temporary_register/description' => 'temporary_register#description'
  get 'temporary_register/custodian' => 'temporary_register#custodian'
  get 'temporary_register/fields' => 'temporary_register#fields'
  get 'temporary_register/create_custom_field' => 'temporary_register#create_custom_field'
  get 'temporary_register/linked_registers' => 'temporary_register#linked_registers'
  get 'temporary_register/upload_data' => 'temporary_register#upload_data'
  get 'temporary_register/preview' => 'temporary_register#preview'
  get 'temporary_register/download' => 'temporary_register#download'
  get 'temporary_register/confirmation' => 'temporary_register#confirmation'
  get 'temporary_register/summary' => 'temporary_register#summary'
  get 'temporary_register/confirmation' => 'temporary_register#confirmation'
  post 'temporary_register/save_register_name', to: 'temporary_register#save_register_name'
  post 'temporary_register/save_description', to: 'temporary_register#save_description'
  post 'temporary_register/save_custodian', to: 'temporary_register#save_custodian'
  post 'temporary_register/save_fields', to: 'temporary_register#save_fields'
  post 'temporary_register/save_custom_field', to: 'temporary_register#save_custom_field'
  post 'temporary_register/save_linked_registers', to: 'temporary_register#save_linked_registers'
  post 'temporary_register/save_upload_data', to: 'temporary_register#save_upload_data'
  post 'temporary_register/create_register', to: 'temporary_register#create_register'

  root 'temporary_register#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
