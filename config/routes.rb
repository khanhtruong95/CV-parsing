Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  namespace :onboarding do
    get  "cv",        to: "cv_uploads#new",    as: :cv_upload
    post "cv",        to: "cv_uploads#create"
    get  "cv/status", to: "cv_uploads#status", as: :cv_status
    post "cv/skip",   to: "cv_uploads#skip",   as: :cv_skip
    post "cv/demo",   to: "cv_uploads#demo",   as: :cv_demo
    get   "profile",  to: "profiles#edit",     as: :profile
    patch "profile",  to: "profiles#update"
    get   "complete", to: "completions#show",  as: :complete
  end

  namespace :admin do
    root "candidate_profiles#index"
    resources :candidate_profiles, only: [ :index, :show ] do
      member { get :cv, action: :download_cv }
    end
  end

  # Defines the root path route ("/")
  root "pages#home"
end
