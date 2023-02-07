(ns user
  "Some helper functions for testing the replica.nvim library when connected to an Clojure nREPL process"
  (:require [figwheel.main.api :as figwheel]))

(defn start-figwheel! []
  (figwheel/start
    {:id "dev"
     :options {:output-to "target/public/cljs-out/main.js"
               :main 'replica.core}
     :config {:watch-dirs ["tests/cljs"]
              :open-url false
              :mode :serve}}))

(defn stop-figwheel![]
  (figwheel/stop-all))

(defn test-me []
  :hello)

(comment
  (start-figwheel!)
  (stop-figwheel!)
  )
